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
        static Gee.Map<uint,string> keyval_to_keyname =
            new HashMap<uint,string> ();
        static Gee.Map<string,uint> keyname_to_keyval =
            new HashMap<string,uint> ();

        static construct {
            foreach (var entry in keynames)
                keyval_to_keyname.set (entry.keyval, entry.name);
            foreach (var entry in keynames)
                keyname_to_keyval.set (entry.name, entry.keyval);
        }

        public static string? keyval_name (uint keyval) {
            return keyval_to_keyname.get (keyval);
        }

        public static uint keyval_from_name (string name) {
            if (keyname_to_keyval.has_key (name))
                return keyname_to_keyval.get (name);

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
