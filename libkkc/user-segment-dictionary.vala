/*
 * Copyright (C) 2011-2013 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2011-2013 Red Hat, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gee;

namespace Kkc {
    /**
     * File based implementation of Dictionary with write access.
     */
    public class UserSegmentDictionary : Object, Dictionary, SegmentDictionary {
        void load () throws DictionaryError, GLib.IOError {
            uint8[] contents;
            try {
                file.load_contents (null, out contents, out etag);
            } catch (GLib.Error e) {
                throw new DictionaryError.NOT_READABLE ("can't load contents");
            }
            var memory = new MemoryInputStream.from_data (contents, g_free);
            var data = new DataInputStream (memory);

            string? line = null;
            size_t length;
            line = data.read_line (out length);
            if (line == null) {
                return;
            }

            var coding = EncodingConverter.extract_coding_system (line);
            if (coding != null) {
                try {
                    var _converter = new EncodingConverter.from_coding_system (
                        coding);
                    if (_converter != null) {
                        converter = _converter;
                    }
                } catch (GLib.Error e) {
                    warning ("can't create converter from coding system %s: %s",
                             coding, e.message);
                }
                // proceed to the next line
                line = data.read_line (out length);
                if (line == null) {
                    return;
                }
            }

            Map<string,Gee.List<Candidate>>? entries = null;
            while (line != null) {
                if (line.has_prefix (";; okuri-ari entries.")) {
                    entries = okuri_ari_entries;
                    break;
                }
                line = data.read_line (out length);
                if (line == null) {
                    break;
                }
            }
            if (entries == null) {
                throw new DictionaryError.MALFORMED_INPUT (
                    "no okuri-ari boundary");
            }

            bool okuri = true;
            while (line != null) {
                line = data.read_line (out length);
                if (line == null) {
                    break;
                }
                if (line.has_prefix (";; okuri-nasi entries.")) {
                    entries = okuri_nasi_entries;
                    okuri = false;
                    continue;
                }
                try {
                    line = converter.decode (line);
                } catch (GLib.Error e) {
                    throw new DictionaryError.MALFORMED_INPUT (
                        "can't decode line %s: %s", line, e.message);
                }
                int index = line.index_of ("/");
                if (index < 1) {
                    throw new DictionaryError.MALFORMED_INPUT (
                        "can't extract midasi from line %s",
                        line);
                }

                string midasi = line[0:index].strip ();
                string candidates_str = line[index:line.length];
                if (!candidates_str.has_prefix ("/") ||
                    !candidates_str.has_suffix ("/")) {
                    throw new DictionaryError.MALFORMED_INPUT (
                        "can't parse candidates list %s",
                        candidates_str);
                }

                var candidates = DictionaryUtils.split_candidates (
                    midasi,
                    okuri,
                    candidates_str);
                var list = new ArrayList<Candidate> ();
                foreach (var c in candidates) {
                    list.add (c);
                }
                entries.set (midasi, list);
            }
        }

        /**
         * {@inheritDoc}
         */
        public void reload () throws GLib.Error {
#if VALA_0_16
            string attributes = FileAttribute.ETAG_VALUE;
#else
            string attributes = FILE_ATTRIBUTE_ETAG_VALUE;
#endif
            FileInfo info = file.query_info (attributes,
                                             FileQueryInfoFlags.NONE);
            if (info.get_etag () != etag) {
                this.okuri_ari_entries.clear ();
                this.okuri_nasi_entries.clear ();
                try {
                    load ();
                } catch (DictionaryError e) {
                    warning ("error parsing user dictionary %s: %s",
                             file.get_path (), e.message);
                } catch (GLib.IOError e) {
                    warning ("error reading user dictionary %s: %s",
                             file.get_path (), e.message);
                }
            }
            is_dirty = false;
        }

        static int compare_entry_asc (Map.Entry<string,Gee.List<Candidate>> a,
                                      Map.Entry<string,Gee.List<Candidate>> b)
        {
            return strcmp (a.key, b.key);
        }

        static int compare_entry_dsc (Map.Entry<string,Gee.List<Candidate>> a,
                                      Map.Entry<string,Gee.List<Candidate>> b)
        {
            return strcmp (b.key, a.key);
        }

        void write_entries (StringBuilder builder,
                            Gee.List<Map.Entry<string,Gee.List<Candidate>>> entries)
        {
            var iter = entries.iterator ();
            while (iter.next ()) {
                var entry = iter.get ();
                var line = "%s %s\n".printf (
                    entry.key,
                    DictionaryUtils.join_candidates (entry.value.to_array ()));
                builder.append (line);
            }
        }

        /**
         * {@inheritDoc}
         */
        public void save () throws GLib.Error {
            if (!is_dirty)
                return;

            var builder = new StringBuilder ();
            var coding = converter.get_coding_system ();
            if (coding != null) {
                builder.append (";;; -*- coding: %s -*-\n".printf (coding));
            }

            builder.append (";; okuri-ari entries.\n");
            var entries = new ArrayList<Map.Entry<string,Gee.List<Candidate>>> ();
            entries.add_all (okuri_ari_entries.entries);
            entries.sort ((CompareFunc) compare_entry_dsc);
            write_entries (builder, entries);
            entries.clear ();

            builder.append (";; okuri-nasi entries.\n");
            entries.add_all (okuri_nasi_entries.entries);
            entries.sort ((CompareFunc) compare_entry_asc);
            write_entries (builder, entries);
            entries.clear ();

            var contents = converter.encode (builder.str);
            DirUtils.create_with_parents (Path.get_dirname (file.get_path ()),
                                          448);
#if VALA_0_16
            file.replace_contents (contents.data,
                                   etag,
                                   false,
                                   FileCreateFlags.PRIVATE,
                                   out etag);
#else
            file.replace_contents (contents,
                                   contents.length,
                                   etag,
                                   false,
                                   FileCreateFlags.PRIVATE,
                                   out etag);
#endif
            is_dirty = false;
        }

        Map<string,Gee.List<Candidate>> get_entries (bool okuri = false) {
            if (okuri) {
                return okuri_ari_entries;
            } else {
                return okuri_nasi_entries;
            }
        }

        /**
         * {@inheritDoc}
         */
        public bool lookup_candidates (string midasi,
                                       bool okuri,
                                       out Candidate[] candidates) {
            var entries = get_entries (okuri);
            if (entries.has_key (midasi)) {
                candidates = entries.get (midasi).to_array ();
                return true;
            } else {
                candidates = new Candidate[0];
                return false;
            }
        }

        /**
         * {@inheritDoc}
         */
        public string[] complete (string midasi) {
            Gee.List<string> completion = new ArrayList<string> ();
            Gee.List<string> keys = new ArrayList<string> ();
            keys.add_all (okuri_nasi_entries.keys);
            keys.sort ();
            var iter = keys.iterator ();
            // find the first matching entry
            while (iter.next ()) {
                var key = iter.get ();
                if (key.has_prefix (midasi)) {
                    // don't add midasi word itself
                    if (key != midasi) {
                        completion.add (key);
                    }
                    break;
                }
            }
            // loop until the last matching entry
            while (iter.next ()) {
                var key = iter.get ();
                if (!key.has_prefix (midasi)) {
                    break;
                }
                // don't add midasi word itself
                if (key != midasi) {
                    completion.add (key);
                }
            }
            return completion.to_array ();
        }

        /**
         * {@inheritDoc}
         */
        public bool select_candidate (Candidate candidate) {
            int index;

            // update midasi history
            for (index = 0;
                 index < midasi_history.length && midasi_history[index] != null;
                 index++) {
                if (midasi_history[index] == candidate.midasi) {
                    if (index > 0) {
                        var first = midasi_history[0];
                        midasi_history[0] = midasi_history[index];
                        midasi_history[index] = first;
                        break;
                    }
                }
            }
            if (index == midasi_history.length ||
                midasi_history[index] == null) {
                for (int j = 1; j < index - 1; j++) {
                    midasi_history[j] = midasi_history[j - 1];
                }
            }
            midasi_history[0] = candidate.midasi;

            // update candidates list associated with midasi
            var entries = get_entries (candidate.okuri);
            if (!entries.has_key (candidate.midasi)) {
                entries.set (candidate.midasi, new ArrayList<Candidate> ());
            }
            index = 0;
            var candidates = entries.get (candidate.midasi);
            foreach (var c in candidates) {
                if (c.text == candidate.text) {
                    if (index > 0) {
                        var first = candidates[0];
                        candidates[0] = candidates[index];
                        candidates[index] = first;
                        is_dirty = true;
                        return true;
                    }
                    return false;
                }
                index++;
            }
            candidates.insert (0, candidate);
            is_dirty = true;
            return true;
        }

        /**
         * {@inheritDoc}
         */
        public bool purge_candidate (Candidate candidate) {
            bool modified = false;
            var entries = get_entries (candidate.okuri);
            if (entries.has_key (candidate.midasi)) {
                var candidates = entries.get (candidate.midasi);
                if (candidates.size > 0) {
                    var iter = candidates.iterator ();
                    while (iter.next ()) {
                        var c = iter.get ();
                        if (c.text == candidate.text) {
                            iter.remove ();
                            modified = true;
                        }
                    }
                    if (candidates.size == 0) {
                        entries.unset (candidate.midasi);
                    }
                }
            }
            if (modified)
                is_dirty = true;
            return modified;
        }

        /**
         * {@inheritDoc}
         */
        public bool read_only {
            get {
                return false;
            }
        }

        File file;
        string etag;
        EncodingConverter converter;
        Map<string,Gee.List<Candidate>> okuri_ari_entries =
            new HashMap<string,Gee.List<Candidate>> ();
        Map<string,Gee.List<Candidate>> okuri_nasi_entries =
            new HashMap<string,Gee.List<Candidate>> ();
        string midasi_history[128];
        bool is_dirty;

        /**
         * Create a new UserSegmentDictionary.
         *
         * @param path a path to the file
         * @param encoding encoding of the file (default UTF-8)
         *
         * @return a new UserSegmentDictionary
         * @throws GLib.Error if opening the file is failed
         */
        public UserSegmentDictionary (string path,
                                      string encoding = "UTF-8") throws GLib.Error
        {
            this.file = File.new_for_path (path);
            this.etag = "";
            this.converter = new EncodingConverter (encoding);
            // user dictionary may not exist for the first time
            if (FileUtils.test (path, FileTest.EXISTS)) {
                reload ();
            }
        }

        ~UserSegmentDictionary () {
            var okuri_ari_iter = okuri_ari_entries.map_iterator ();
            while (okuri_ari_iter.next ()) {
                okuri_ari_iter.get_value ().clear ();
            }
            okuri_ari_entries.clear ();
            var okuri_nasi_iter = okuri_nasi_entries.map_iterator ();
            while (okuri_nasi_iter.next ()) {
                okuri_nasi_iter.get_value ().clear ();
            }
            okuri_nasi_entries.clear ();
        }
    }
}