/*
 * Copyright (C) 2012 Daiki Ueno <ueno@unixuser.org>
 * Copyright (C) 2012 Red Hat, Inc.
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
    namespace Util {
        internal static double decode_cost (uint16 cost, double min_cost) {
            return cost * min_cost / 65535;
        }

        internal static uint8[] pack_uint32_array (uint32[] ids) {
            uint8[] buffer = new uint8[ids.length * sizeof(uint32)];
            uint8 *p = buffer;
            foreach (var id in ids) {
                var value = id.to_little_endian ();
                Memory.copy (p, &value, sizeof(uint32));
                p += sizeof(uint32);
            }
            return buffer;
        }

        internal static long bsearch_ngram (void *memory,
                                            long start_offset,
                                            long end_offset,
                                            long record_size,
                                            uint8[] needle)
        {
            var offset = start_offset + (end_offset - start_offset) / 2;
            while (start_offset <= end_offset) {
                uint8 *p = (uint8 *) memory + offset * record_size;
                var r = Memory.cmp (p, needle, needle.length);
                if (r == 0)
                    return offset;
                if (r > 0)
                    end_offset = offset - 1;
                else
                    start_offset = offset + 1;
                offset = start_offset + (end_offset - start_offset) / 2;
            }
            return -1;
        }

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

        public MemoryMappedFile (File file) {
            this.file = file;
            remap ();
        }

        public void remap () throws DictError {
            if (_memory != null) {
                Posix.munmap (_memory, _length);
                _memory = null;
            }
            map ();
        }

        void map () throws DictError {
            int fd = Posix.open (file.get_path (), Posix.O_RDONLY, 0);
            if (fd < 0) {
                throw new DictError.NOT_READABLE ("can't open %s",
                                                     file.get_path ());
            }

            Posix.Stat stat;
            int retval = Posix.fstat (fd, out stat);
            if (retval < 0) {
                throw new DictError.NOT_READABLE ("can't stat fd");
            }

            _memory = Posix.mmap (null,
                                  stat.st_size,
                                  Posix.PROT_READ,
                                  Posix.MAP_SHARED,
                                  fd,
                                  0);
            if (_memory == Posix.MAP_FAILED) {
                throw new DictError.NOT_READABLE ("mmap failed");
            }
            _length = stat.st_size;
        }
    }
}

