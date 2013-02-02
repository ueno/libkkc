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

    struct PrefixEntry {
        public int offset;
        public string[] sequence;
        public PrefixEntry (int offset, string[] sequence) {
            this.offset = offset;
            this.sequence = sequence;
        }
    }

    class SequenceUtils : Object {
        public static Gee.List<PrefixEntry?> enumerate_prefixes (
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

    class MemoryMappedFile : Object {
        void *_memory = null;
        public void *memory {
            get {
                return _memory;
            }
        }

        size_t _length = 0;
        public size_t length {
            get {
                return _length;
            }
        }

        File file;

        public MemoryMappedFile (File file) throws IOError {
            this.file = file;
            remap ();
        }

        public void remap () throws IOError {
            if (_memory != null) {
                Posix.munmap (_memory, _length);
                _memory = null;
            }
            map ();
        }

        void map () throws IOError {
            int fd = Posix.open (file.get_path (), Posix.O_RDONLY, 0);
            if (fd < 0) {
                throw new IOError.FAILED ("can't open %s: %s",
                                          file.get_path (),
                                          Posix.strerror (Posix.errno));
            }

            Posix.Stat stat;
            int retval = Posix.fstat (fd, out stat);
            if (retval < 0) {
                throw new IOError.FAILED ("can't stat fd: %s",
                                          Posix.strerror (Posix.errno));
            }

            _memory = Posix.mmap (null,
                                  stat.st_size,
                                  Posix.PROT_READ,
                                  Posix.MAP_SHARED,
                                  fd,
                                  0);
            if (_memory == Posix.MAP_FAILED) {
                throw new IOError.FAILED ("mmap failed: %s",
                                          Posix.strerror (Posix.errno));
            }
            _length = stat.st_size;
        }
    }
}
