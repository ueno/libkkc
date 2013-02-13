#!/usr/bin/python

# Copyright (C) 2011-2013 Daiki Ueno <ueno@gnu.org>
# Copyright (C) 2011-2013 Red Hat, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
import mmap
import math
import struct

ERROR_RATE = 0.25

def murmur_hash3_32(b0, b1, seed):
    h1 = seed

    c1 = 0xcc9e2d51
    c2 = 0x1b873593

    # body: b0
    b0 *= c1
    b0 &= 0xFFFFFFFF
    b0 = (b0 << 15) | (b0 >> (32 - 15))
    b0 &= 0xFFFFFFFF
    b0 *= c2
    b0 &= 0xFFFFFFFF

    h1 ^= b0
    h1 &= 0xFFFFFFFF
    h1 = (h1 << 13) | (h1 >> (32 - 13)) 
    h1 &= 0xFFFFFFFF
    h1 = h1 * 5 + 0xe6546b64
    h1 &= 0xFFFFFFFF

    # body: b1
    b1 *= c1
    b1 &= 0xFFFFFFFF
    b1 = (b1 << 15) | (b1 >> (32 - 15))
    b1 &= 0xFFFFFFFF
    b1 *= c2
    b1 &= 0xFFFFFFFF

    h1 ^= b1
    h1 &= 0xFFFFFFFF
    h1 = (h1 << 13) | (h1 >> (32 - 13)) 
    h1 &= 0xFFFFFFFF
    h1 = h1 * 5 + 0xe6546b64
    h1 &= 0xFFFFFFFF

    # No tail processing needed.

    # fmix
    h1 ^= 8
    h1 &= 0xFFFFFFFF
    h1 ^= h1 >> 16
    h1 &= 0xFFFFFFFF
    h1 *= 0x85ebca6b
    h1 &= 0xFFFFFFFF
    h1 ^= h1 >> 13
    h1 &= 0xFFFFFFFF
    h1 *= 0xc2b2ae35
    h1 &= 0xFFFFFFFF
    h1 ^= h1 >> 16
    h1 &= 0xFFFFFFFF
    return h1

class FilterGenerator(object):
    def __init__(self, infile, outfile, record_size, header_size):
        self.infile = infile
        self.outfile = outfile
        self.record_size = record_size
        self.header_size = header_size

    def generate(self):
        size = os.fstat(self.infile.fileno()).st_size
        n = size / self.record_size
        m = int(math.ceil(-n*math.log10(ERROR_RATE) /
                          math.pow(math.log10(2), 2)))
        m = (m/8 + 1)*8
        inmem = mmap.mmap(self.infile.fileno(),
                          size,
                          access=mmap.ACCESS_READ)
        outmem = bytearray(m/8)
        for i in xrange(0, n):
            offset = i*self.record_size
            b0, b1 = struct.unpack("=LL", inmem[offset:offset+self.header_size])
            for k in xrange(0, 4):
                h = murmur_hash3_32(b0, b1, k)
                h = int(h * (m / float(0xFFFFFFFF)))
                outmem[h/8] |= (1 << (h%8))
        inmem.close()
        self.outfile.write(outmem)

if __name__ == '__main__':
    import sys
    import argparse

    parser = argparse.ArgumentParser(description='filter')
    parser.add_argument('infile', type=argparse.FileType('r'),
                        help='input file')
    parser.add_argument('outfile', type=argparse.FileType('w'),
                        help='output file')
    parser.add_argument('record_size', type=int,
                        help='record size')
    parser.add_argument('header_size', type=int,
                        help='header size')
    args = parser.parse_args()
    generator = FilterGenerator(args.infile,
                                args.outfile,
                                args.record_size,
                                args.header_size)
    generator.generate()
