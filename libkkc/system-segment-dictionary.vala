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
     * Read-only file based implementation of Dictionary.
     */
    public class SystemSegmentDictionary : Object, Dictionary, SegmentDictionary {
        // Read a line near offset and move offset to the beginning of
        // the line.
        string read_line (ref long offset) {
            return_val_if_fail (offset < mmap.length, null);
            char *p = ((char *)mmap.memory + offset);
            for (; offset > 0; offset--, p--) {
                if (*p == '\n')
                    break;
            }

            if (offset > 0) {
                offset++;
                p++;
            }

            var builder = new StringBuilder ();
            long _offset = offset;
            for (; _offset < mmap.length; _offset++, p++) {
                if (*p == '\n')
                    break;
                builder.append_c (*p);
            }
            return builder.str;
        }

        // can only called after read*_line
        string? read_previous_line (ref long pos, string line) {
            if (pos < 2) {
                return null;
            }
            // place the cursor at the end of the previous line
            pos -= 2;
            return read_line (ref pos);
        }

        // can only called after read*_line
        string? read_next_line (ref long pos, string line) {
            if (pos + line.length + 1 >= mmap.length) {
                return null;
            }
            // place the cursor at "\n" of the current line
            pos += line.length + 1;
            return read_line (ref pos);
        }

        // Skip until the first occurrence of line.  This moves offset
        // at the beginning of the next line.
        bool read_until (ref long offset, string line) {
            return_val_if_fail (offset < mmap.length, null);
            while (offset + line.length < mmap.length) {
                char *p = ((char *)mmap.memory + offset);
                if (*p == '\n' &&
                    Memory.cmp (p + 1, (void *)line, line.length) == 0) {
                    offset += line.length;
                    return true;
                }
                offset++;
            }
            return false;
        }

        void load () throws DictionaryError {
            try {
                mmap.remap ();
            } catch (IOError e) {
                throw new DictionaryError.NOT_READABLE (
                    "can't load: %s", e.message);
            }

            long offset = 0;
            var line = read_line (ref offset);
            if (line == null) {
                throw new DictionaryError.MALFORMED_INPUT (
                    "can't read the first line");
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
            }

            offset = 0;
            if (!read_until (ref offset, ";; okuri-ari entries.\n")) {
                throw new DictionaryError.MALFORMED_INPUT (
                    "no okuri-ari boundary");
            }
            okuri_ari_offset = offset;
            
            if (!read_until (ref offset, ";; okuri-nasi entries.\n")) {
                throw new DictionaryError.MALFORMED_INPUT (
                    "no okuri-nasi boundary");
            }
            okuri_nasi_offset = offset;
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
                try {
                    load ();
                    etag = info.get_etag ();
                } catch (DictionaryError e) {
                    warning ("error loading file dictionary %s %s",
                             file.get_path (), e.message);
                }
            }
        }

        bool search_pos (string midasi,
                         long start_offset,
                         long end_offset,
                         CompareFunc<string> cmp,
                         out long pos,
                         out string? line,
                         int direction) {
            long offset = start_offset + (end_offset - start_offset) / 2;
            while (start_offset < end_offset) {
                assert (offset < mmap.length);

                string _line = read_line (ref offset);
                int index = _line.index_of (" ");
                if (index < 1) {
                    warning ("corrupted dictionary entry: %s", _line);
                    break;
                }

                int r = cmp (_line[0:index], midasi);
                if (r == 0) {
                    pos = offset;
                    line = _line;
                    return true;
                }

                if (r * direction > 0) {
                    end_offset = offset - 2;
                } else {
                    start_offset = offset + _line.length + 1;
                }
                offset = start_offset + (end_offset - start_offset) / 2;
            }
            pos = -1;
            line = null;
            return false;
        }

        /**
         * {@inheritDoc}
         */
        public bool lookup_candidates (string midasi,
                                       bool okuri,
                                       out Candidate[] candidates) {
            if (mmap.memory == null) {
                candidates = new Candidate[0];
                return false;
            }

            long start_offset, end_offset;
            if (okuri) {
                start_offset = okuri_ari_offset;
                end_offset = okuri_nasi_offset;
            } else {
                start_offset = okuri_nasi_offset;
                end_offset = (long) mmap.length - 1;
            }
            string _midasi;
            try {
                _midasi = converter.encode (midasi);
            } catch (GLib.Error e) {
                warning ("can't encode %s: %s", midasi, e.message);
                candidates = new Candidate[0];
                return false;
            }

            long pos;
            string line;
            if (search_pos (_midasi,
                            start_offset,
                            end_offset,
                            strcmp,
                            out pos,
                            out line,
                            okuri ? -1 : 1)) {
                int index = line.index_of (" ");
                string _line;
                if (index > 0) {
                    try {
                        _line = converter.decode (line[index:line.length]);
                    } catch (GLib.Error e) {
                        warning ("can't decode line %s: %s",
                                 line, e.message);
                        candidates = new Candidate[0];
                        return false;
                    }
                    candidates = DictionaryUtils.split_candidates (midasi,
                                                                   okuri,
                                                                   _line);
                    return true;
                }
            }
            candidates = new Candidate[0];
            return false;
        }

        static int strcmp_prefix (string a, string b) {
            if (a.has_prefix (b))
                return 0;
            return strcmp (a, b);
        }

        /**
         * {@inheritDoc}
         */
        public string[] complete (string midasi) {
            if (mmap.memory == null)
                return new string[0];

            var completion = new ArrayList<string> ();

            long start_offset, end_offset;
            start_offset = okuri_nasi_offset;
            end_offset = (long) mmap.length;

            string _midasi;
            try {
                _midasi = converter.encode (midasi);
            } catch (GLib.Error e) {
                warning ("can't decode %s: %s", midasi, e.message);
                return completion.to_array ();
            }

            long pos;
            string line;
            if (search_pos (_midasi,
                            start_offset,
                            end_offset,
                            strcmp_prefix,
                            out pos,
                            out line,
                            1)) {
                long _pos = pos;
                string _line = line;

                // search backward
                do {
                    int index = line.index_of (" ");
                    if (index < 0) {
                        warning ("corrupted dictionary entry: %s",
                                 line);
                    } else {
                        var completed = line[0:index];
                        // don't add midasi word itself
                        if (completed != _midasi) {
                            try {
                                string decoded = converter.decode (completed);
                                completion.insert (0, decoded);
                            } catch (GLib.Error e) {
                                warning ("can't decode line %s: %s",
                                         line, e.message);
                            }
                        }
                    }
                } while ((line = read_previous_line (ref pos, line)) != null &&
                         line.has_prefix (_midasi));

                // search forward
                pos = _pos;
                line = _line;
                while ((line = read_next_line (ref pos, line)) != null &&
                       line.has_prefix (_midasi)) {
                    int index = line.index_of (" ");
                    if (index < 0) {
                        warning ("corrupted dictionary entry: %s",
                                 line);
                    } else {
                        var completed = line[0:index];
                        // don't add midasi word itself
                        if (completed != _midasi) {
                            try {
                                string decoded = converter.decode (completed);
                                completion.add (decoded);
                            } catch (GLib.Error e) {
                                warning ("can't decode line %s: %s",
                                         line, e.message);
                            }
                        }
                    }
                }
            }
            return completion.to_array ();
        }

        /**
         * {@inheritDoc}
         */
        public bool read_only {
            get {
                return true;
            }
        }

        File file;
        MemoryMappedFile mmap;
        string etag;
        EncodingConverter converter;
        long okuri_ari_offset;
        long okuri_nasi_offset;

        /**
         * Create a new SystemSegmentDictionary.
         *
         * @param path a path to the file
         * @param encoding encoding of the file (default EUC-JP)
         *
         * @return a new FileDictionary
         * @throws GLib.Error if opening the file is failed
         */
        public SystemSegmentDictionary (string path,
                                        string encoding = "EUC-JP") throws GLib.Error
        {
            this.file = File.new_for_path (path);
            this.mmap = new MemoryMappedFile (file);
            this.etag = "";
            this.converter = new EncodingConverter (encoding);
            reload ();
        }
    }
}
