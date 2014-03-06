/*
 * Copyright (C) 2012-2013 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2012-2013 Red Hat, Inc.
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
using Keysyms;

namespace Kkc {
    namespace Utils {
        internal static string[] build_data_path (string subdir) {
            ArrayList<string> dirs = new ArrayList<string> ();
            string? path = Environment.get_variable (
                "%s_DATA_PATH".printf (Config.PACKAGE_NAME.up ()));
            if (path == null) {
                dirs.add (Path.build_filename (
                              Environment.get_user_config_dir (),
                              Config.PACKAGE_NAME,
                              subdir));
                // For arch-dependent data files
                dirs.add (Path.build_filename (Config.LIBDIR,
                                               Config.PACKAGE_NAME,
                                               subdir));
                // For arch-independent data files
                dirs.add (Path.build_filename (Config.PKGDATADIR, subdir));
            } else {
                string[] elements = path.split (":");
                foreach (var element in elements) {
                    dirs.add (Path.build_filename (element, subdir));
                }
            }
            return dirs.to_array ();
        }

        internal static string[] split_utf8 (string str) {
            var result = new ArrayList<string> ();
            int index = 0;
            unichar uc;
            while (str.get_next_char (ref index, out uc)) {
                result.add (uc.to_string ());
            }
            return result.to_array ();
        }

        internal static int hex_char_to_int (char hex) {
            if ('0' <= hex && hex <= '9') {
                return hex - '0';
            } else if ('a' <= hex.tolower () && hex.tolower () <= 'f') {
                return hex - 'a' + 10;
            }
            return -1;
        }

        internal static string parse_hex (string hex) {
            var builder = new StringBuilder ();
            for (var i = 0; i < hex.length - 1; i += 2) {
                int c = (hex_char_to_int (hex[i]) << 4) |
                    hex_char_to_int (hex[i + 1]);
                builder.append_c ((char)c);
            }
            return builder.str;
        }
    }

    internal struct PrefixEntry {
        public int offset;
        public string[] sequence;
        public PrefixEntry (int offset, string[] sequence) {
            this.offset = offset;
            this.sequence = sequence;
        }
    }

    namespace SequenceUtils {
        internal static Gee.List<PrefixEntry?> enumerate_prefixes (
            string[] sequence, int min, int max)
        {
            var result = new ArrayList<PrefixEntry?> ();
            for (var i = 0; i < sequence.length; i++) {
                for (var j = sequence.length; j > i; j--) {
                    if (j - i < min)
                        break;
                    if (j - i > max)
                        continue;
                    result.add (PrefixEntry (i, sequence[i:j]));
                }
            }
            return result;
        }
    }

    abstract class KeyEventUtils : Object {
        static KeysymEntry *bsearch_keysyms (
            KeysymEntry *memory,
            long start_offset,
            long end_offset,
            CompareDataFunc<KeysymEntry?> compare,
            KeysymEntry needle)
        {
            var offset = start_offset + (end_offset - start_offset) / 2;
            while (start_offset <= end_offset) {
                KeysymEntry *p = memory + offset;
                var r = compare (*p, needle);
                if (r == 0)
                    return p;
                if (r > 0)
                    end_offset = offset - 1;
                else
                    start_offset = offset + 1;
                offset = start_offset + (end_offset - start_offset) / 2;
            }
            return null;
        }

        static string? read_name (long start_offset) {
            long offset;
            for (offset = start_offset; keysym_names[offset] != '\0'; offset++)
                ;

            string *result = malloc0 (offset - start_offset + 1);
            char *dest = (char *) result;

            Memory.copy (dest,
                         (char *) keysym_names + start_offset,
                         (offset - start_offset));

            return (owned) result;
        }

        public static string? keyval_name (uint keyval) {
            KeysymEntry needle = KeysymEntry () {
                keysym = keyval,
                offset = 0
            };

            var entry = bsearch_keysyms (keysym_to_name,
                                         0,
                                         keysym_to_name.length,
                                         (a, b) => {
                                             return a.keysym == b.keysym ? 0 :
                                                 a.keysym < b.keysym ? -1 : 1;
                                         },
                                         needle);
            if (entry == null)
                return null;

            return read_name (entry->offset);
        }

        static KeysymEntry *find_keysym (KeysymEntry *entry, string name) {
            if (read_name (entry->offset) == name)
                return entry;

            KeysymEntry *iter;
            for (iter = entry - 1;
                 iter >= (KeysymEntry *) name_to_keysym;
                 iter++)
                if (read_name (iter->offset) == name)
                    return iter;

            return null;
        }

        public static uint keyval_from_name (string name) {
            KeysymEntry needle = KeysymEntry () {
                keysym = 0,
                offset = 0
            };

            var entry = bsearch_keysyms (name_to_keysym,
                                         0,
                                         name_to_keysym.length,
                                         (a, b) => {
                                             var aname = read_name (a.offset);
                                             return aname.ascii_casecmp (name);
                                         },
                                         needle);
            if (entry != null) {
                entry = find_keysym (entry, name);
                if (entry != null)
                    return entry->keysym;
            }

            // handle ASCII keyvals with differnet name (e.g. at,
            // percent, etc.)
            if (name.char_count () == 1) {
                unichar code = name.get_char ();
                if (0x20 <= code && code < 0x7F)
                    return code;
            }

            return Keysyms.VoidSymbol;
        }

        public static unichar keyval_unicode (uint keyval) {
            if (0x20 <= keyval && keyval < 0x7F)
                return keyval;
            // FIXME: handle other unicode keyvals
            switch (keyval) {
            case Keysyms.yen:
                return "\xc2\xa5".get_char ();
            default:
                break;
            }
            return '\0';
        }
    }

    interface IndexFile : Object {
        public abstract char* get_contents ();
        public abstract size_t get_length ();
    }

    class MappedIndexFile : IndexFile, Object {
        MappedFile mmap;

        public MappedIndexFile (string filename) throws Error {
            mmap = new MappedFile (filename, false);
        }

        public char* get_contents () {
            return mmap.get_contents ();
        }

        public size_t get_length () {
            return mmap.get_length ();
        }
    }

    class LoadedIndexFile : IndexFile, Object {
        uint8[] contents;

        public LoadedIndexFile (string filename) throws Error {
            var file = File.new_for_path (filename);
            string etag;
            file.load_contents (null, out contents, out etag);
        }

        public char* get_contents () {
            return contents;
        }

        public size_t get_length () {
            return contents.length;
        }
    }
}
