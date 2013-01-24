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
    struct PrefixEntry {
        public int offset;
        public string text;
        public PrefixEntry (int offset, string text) {
            this.offset = offset;
            this.text = text;
        }
    }

    class SentenceUtils : Object {
        static int compare_prefix (PrefixEntry a, PrefixEntry b) {
            var result = b.text.char_count () - a.text.char_count ();
            if (result == 0)
                result = a.offset - b.offset;
            return result;
        }

        public static Gee.List<PrefixEntry?> enumerate_prefixes (
            string[] sequence)
        {
            var result = new ArrayList<PrefixEntry?> ();
            int[] offsets = new int[sequence.length];
            for (var i = 1; i < sequence.length; i++) {
                offsets[i] = sequence[i - 1].char_count ();
            }
            offsets[0] = 0;
            for (var i = 0; i < sequence.length; i++) {
                for (var j = i; j < sequence.length; j++) {
                    string[] _sequence = sequence[i:j+1];
                    _sequence += null;
                    var text = string.joinv ("", _sequence);
                    result.add (PrefixEntry (i, text));
                }
            }
            result.sort ((GLib.CompareFunc) compare_prefix);
            return result;
        }
    }

    /**
     * Base interface of sentence dictionaries.
     */
    public interface SentenceDictionary : Object, Dictionary {
        /**
         * Lookup constraints.
         *
         * @param input input string to lookup
         *
         * @return an array of positions
         */
        public abstract int[] lookup_constraints (string input);

        /**
         * Lookup sequence.
         *
         * @param sequence input sequence to lookup
         *
         * @return an array of strings
         */
        public abstract string[] lookup_sequence (string[] sequence);

        public virtual bool select_segments (Segment[] input) {
            // FIXME: throw an error when the dictionary is read only
            return false;
        }
    }

    class UserSentenceDictionary : Object, Dictionary, SentenceDictionary {
        File file;
        string etag;

        enum UserSentenceState {
            NONE,
            CONSTRAINT,
            PHRASE,
        }

        Map<string,Gee.List<int>> constraint_entries =
            new HashMap<string,Gee.List<int>> ();
        Map<string,Gee.List<string>> phrase_entries =
            new HashMap<string,Gee.List<string>> ();

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

            var state = UserSentenceState.NONE;
            while (line != null) {
                if (line.has_prefix (";; constraint entries.")) {
                    state = UserSentenceState.CONSTRAINT;
                    break;
                }
                line = data.read_line (out length);
                if (line == null) {
                    break;
                }
            }
            if (state == UserSentenceState.NONE) {
                throw new DictionaryError.MALFORMED_INPUT (
                    "no constraints boundary");
            }

            while (line != null) {
                line = data.read_line (out length);
                if (line == null) {
                    break;
                }
                if (line.has_prefix (";; phrase entries.")) {
                    state = UserSentenceState.PHRASE;
                    continue;
                }
                int index = line.index_of ("/");
                if (index < 2) {
                    throw new DictionaryError.MALFORMED_INPUT (
                        "can't extract midasi from line %s",
                        line);
                }

                string midasi = line[0:index].strip ();
                string candidates_str = line[index:line.length].strip ();
                if (!candidates_str.has_prefix ("/") ||
                    !candidates_str.has_suffix ("/")) {
                    throw new DictionaryError.MALFORMED_INPUT (
                        "can't parse candidates list %s",
                        candidates_str);
                }

                switch (state) {
                case UserSentenceState.CONSTRAINT:
                    var numbers = new ArrayList<int> ();
                    var strv = candidates_str.slice (1, -1).split (",");
                    foreach (var str in strv) {
                        numbers.add (int.parse (str));
                    }
                    constraint_entries.set (midasi, numbers);
                    break;
                case UserSentenceState.PHRASE:
                    var segments = new ArrayList<string> ();
                    var strv = candidates_str.slice (1, -1).split ("/");
                    foreach (var str in strv) {
                        segments.add (str);
                    }
                    phrase_entries.set (midasi, segments);
                    break;
                }
            }
        }

        static int compare_constraint_entry (Map.Entry<string,Gee.List<int>> a,
                                             Map.Entry<string,Gee.List<int>> b)
        {
            return strcmp (a.key, b.key);
        }

        static int compare_phrase_entry (Map.Entry<string,Gee.List<string>> a,
                                         Map.Entry<string,Gee.List<string>> b)
        {
            return strcmp (b.key, a.key);
        }

        void write_constraint_entries (StringBuilder builder,
                                       ArrayList<Map.Entry<string,Gee.List<int>>> entries) {
            var iter = entries.iterator ();
            while (iter.next ()) {
                var entry = iter.get ();
                string[] strv = new string[entry.value.size];
                for (var i = 0; i < strv.length; i++) {
                    strv[i] = entry.value[i].to_string ();
                }
                var line = "%s /%s/\n".printf (
                    entry.key,
                    string.joinv (",", strv));
                builder.append (line);
            }
        }

        void write_phrase_entries (StringBuilder builder,
                                   ArrayList<Map.Entry<string,Gee.List<string>>> entries) {
            var iter = entries.iterator ();
            while (iter.next ()) {
                var entry = iter.get ();
                string[] strv = new string[entry.value.size];
                for (var i = 0; i < strv.length; i++) {
                    strv[i] = entry.value[i];
                }
                var line = "%s /%s/\n".printf (
                    entry.key,
                    string.join ("/", strv));
                builder.append (line);
            }
        }

        public void save () throws GLib.Error {
            var builder = new StringBuilder ();
            builder.append (";; constraint entries.\n");
            var _constraint_entries = new ArrayList<Map.Entry<string,Gee.List<int>>> ();
            _constraint_entries.add_all (constraint_entries.entries);
            _constraint_entries.sort ((CompareFunc) compare_constraint_entry);
            write_constraint_entries (builder, _constraint_entries);

            builder.append (";; phrase entries.\n");
            var _phrase_entries = new ArrayList<Map.Entry<string,Gee.List<string>>> ();
            _phrase_entries.add_all (phrase_entries.entries);
            _phrase_entries.sort ((CompareFunc) compare_phrase_entry);
            write_phrase_entries (builder, _phrase_entries);

            DirUtils.create_with_parents (Path.get_dirname (file.get_path ()),
                                          448);

            var contents = builder.str;
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
        }

        public void reload () throws GLib.Error {
#if VALA_0_16
            string attributes = FileAttribute.ETAG_VALUE;
#else
            string attributes = FILE_ATTRIBUTE_ETAG_VALUE;
#endif
            FileInfo info = file.query_info (attributes,
                                             FileQueryInfoFlags.NONE);
            if (info.get_etag () != etag) {
                this.constraint_entries.clear ();
                this.phrase_entries.clear ();
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
        }

        public int[] lookup_constraints (string input) {
            return constraint_entries.get (input).to_array ();
        }

        public string[] lookup_sequence (string[] sequence) {
            var midasi = string.joinv (" ", sequence);
            return phrase_entries.get (midasi).to_array ();
        }
 
        public bool select_segments (Segment[] segments) {
            int offset = 0;
            var builder = new StringBuilder ();
            ArrayList<int> constraints = new ArrayList<int> ();
            ArrayList<string> phrase = new ArrayList<string> ();
            foreach (var segment in segments) {
                var count = segment.input.char_count ();
                offset += count;
                constraints.add (offset);
                phrase.add (segment.output);
                builder.append (segment.input);
            }
            constraint_entries.set (builder.str, constraints);
            phrase_entries.set (builder.str, phrase);
            return true;
        }

        /**
         * {@inheritDoc}
         */
        public bool read_only {
            get {
                return false;
            }
        }
   }
}