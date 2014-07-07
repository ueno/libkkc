/*
 * Copyright (C) 2012-2014 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2012-2014 Red Hat, Inc.
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

namespace Kkc {
    namespace LanguageModelUtils {
        internal static double decode_cost (uint16 cost, double min_cost) {
            return cost * min_cost / 65535;
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
    }
}
