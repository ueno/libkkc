#!/usr/bin/python

# Copyright (C) 2011-2014 Daiki Ueno <ueno@gnu.org>
# Copyright (C) 2011-2014 Red Hat, Inc.

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

import struct
import marisa
import re

NGRAM = 3
NGRAM_LINE_REGEX = '^([-0-9.]+)[ \t]+([^\t]+?)(?:[ \t]+([-0-9.]+))?$'

class SortedGenerator(object):
    def __init__(self, infile, output_prefix):
        self.__infile = infile
        self.__output_prefix = output_prefix
        self.__ngram_line_regex = re.compile(NGRAM_LINE_REGEX)

        self.__ngram_entries = [{} for x in range(0, NGRAM)]

        self.__vocab_keyset = marisa.Keyset()
        self.__input_keyset = marisa.Keyset()

        self.__vocab_trie = marisa.Trie()
        self.__input_trie = marisa.Trie()

        self.__min_cost = 0.0

    def read(self):
        print("reading N-grams")
        self.__read_tries()
        self.__read_ngrams()
        print("min cost = %lf" % self.__min_cost)

    def __read_tries(self):
        while True:
            line = self.__infile.readline()
            if line == "":
                break
            if line.startswith("\\1-grams"):
                break

        unigram_count = 0
        while True:
            line = self.__infile.readline()
            if line == "":
                break
            line = line.strip('\n')
            if line == "":
                break
            match = self.__ngram_line_regex.match(line)
            if not match:
                continue
            strv = match.groups()
            self.__vocab_keyset.push_back(strv[1])
            if not strv[1] in ("<s>", "</s>", "<UNK>"):
                if "/" not in strv[1]:
                    continue
                (input, output) = strv[1].split("/")
                self.__input_keyset.push_back(input)

        self.__vocab_trie.build(self.__vocab_keyset)
        self.__input_trie.build(self.__input_keyset)

    def __read_ngrams(self):
        self.__infile.seek(0)
        for n in range(1, NGRAM + 1):
            while True:
                line = self.__infile.readline()
                if line == "":
                    break
                if line.startswith("\\%s-grams:" % n):
                    break

            while True:
                line = self.__infile.readline()
                if line == "":
                    break
                line = line.strip('\n')
                if line == "":
                    break
                match = self.__ngram_line_regex.match(line)
                if not match:
                    continue
                strv = match.groups()
                ngram = strv[1].split(" ")
                ids = []
                for word in ngram:
                    agent = marisa.Agent()
                    agent.set_query(word)
                    if not self.__vocab_trie.lookup(agent):
                        continue
                    ids.append(agent.key_id())
                cost = float(strv[0])
                if cost != -99 and cost < self.__min_cost:
                    self.__min_cost = cost
                backoff = 0.0
                if strv[2]:
                    backoff = float(strv[2])
                self.__ngram_entries[n - 1][tuple(ids)] = (cost, backoff)

    def write(self):
        self.__min_cost = -8.0
        self.__write_tries()
        self.__write_ngrams()

    def __write_tries(self):
        self.__vocab_trie.save(self.__output_prefix + ".1gram.index")
        self.__input_trie.save(self.__output_prefix + ".input")

    def __write_ngrams(self):
        def quantize(cost, min_cost):
            return max(0, min(65535, int(cost * 65535 / min_cost)))

        print("writing 1-gram file")
        unigram_offsets = {}
        unigram_file = open("%s.1gram" % self.__output_prefix, "wb")
        offset = 0
        for ids, value in sorted(self.__ngram_entries[0].items()):
            unigram_offsets[ids[0]] = offset
            s = struct.pack("=HHH",
                            quantize(value[0], self.__min_cost),
                            quantize(value[1], self.__min_cost),
                            0   # reserved
                            )
            unigram_file.write(s)
            offset += 1
        unigram_file.close()

        print("writing 2-gram file")
        bigram_offsets = {}
        bigram_file = open("%s.2gram" % self.__output_prefix, "wb")
        keys = self.__ngram_entries[1].keys()
        items = [(struct.pack("=LL", ids[1], unigram_offsets[ids[0]]), ids) for ids in keys]
        offset = 0
        for header, ids in sorted(items, key=lambda x: x[0]):
            value = self.__ngram_entries[1][ids]
            bigram_offsets[ids] = offset
            s = struct.pack("=HH",
                            quantize(value[0], self.__min_cost),
                            quantize(value[1], self.__min_cost))
            bigram_file.write(header + s)
            offset += 1
        bigram_file.close()

        if len(self.__ngram_entries[2]) > 0:
            print("writing 3-gram file")
            trigram_file = open("%s.3gram" % self.__output_prefix, "wb")
            keys = self.__ngram_entries[2].keys()
            items = [(struct.pack("=LL", ids[2], bigram_offsets[(ids[0], ids[1])]), ids) for ids in keys]
            for header, ids in sorted(items, key=lambda x: x[0]):
                value = self.__ngram_entries[2][ids]
                s = struct.pack("=H",
                                quantize(value[0], self.__min_cost))
                trigram_file.write(header + s)
            trigram_file.close()

if __name__ == '__main__':
    import sys
    import argparse

    parser = argparse.ArgumentParser(description='sortlm')
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r'),
                        default=sys.stdin,
                        help='language model file')
    parser.add_argument('output_prefix', metavar='OUTPUT_PREFIX', type=str,
                        help='output file prefix')
    args = parser.parse_args()

    generator = SortedGenerator(args.infile, args.output_prefix)
    generator.read();
    generator.write();
