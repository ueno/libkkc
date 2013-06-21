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
namespace Kkc {
    static uint32 murmur_hash3_32 (uint32 b0, uint32 b1, uint32 seed) {
        uint32 h1 = seed;

        const uint32 c1 = 0xcc9e2d51U;
        const uint32 c2 = 0x1b873593U;

        // body: b0
        b0 *= c1;
        b0 = (b0 << 15) | (b0 >> (32 - 15));
        b0 *= c2;

        h1 ^= b0;
        h1 = (h1 << 13) | (h1 >> (32 - 13)); 
        h1 = h1 * 5 + 0xe6546b64U;

        // body: b1
        b1 *= c1;
        b1 = (b1 << 15) | (b1 >> (32 - 15));
        b1 *= c2;

        h1 ^= b1;
        h1 = (h1 << 13) | (h1 >> (32 - 13)); 
        h1 = h1 * 5 + 0xe6546b64U;

        // No tail processing needed.

        // fmix
        h1 ^= 8;
        h1 ^= h1 >> 16;
        h1 *= 0x85ebca6bU;
        h1 ^= h1 >> 13;
        h1 *= 0xc2b2ae35U;
        h1 ^= h1 >> 16;
        return h1;
    }

    class BloomFilter : Object {
        MappedFile mmap;

        public BloomFilter (string filename) throws Error {
            this.mmap = new MappedFile (filename, false);
        }

        bool is_bit_set (uint32 index) {
            assert (index / 8 < mmap.get_length ());
            uint8 *p = (uint8 *) mmap.get_contents () + index / 8;
            return (*p & (1 << (index % 8))) != 0;
        }

        public bool contains (uint32 b0, uint32 b1) {
            for (var k = 0; k < 4; k++) {
                var h = murmur_hash3_32 (b0, b1, k);
                var i = (uint32) (h * (mmap.get_length () * 8 / (double) 0xFFFFFFFF));
                if (!is_bit_set (i))
                    return false;
            }
            return true;
        }
    }
}
