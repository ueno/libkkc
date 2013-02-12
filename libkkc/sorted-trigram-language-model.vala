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
    public class SortedTrigramLanguageModel : SortedBigramLanguageModel, TrigramLanguageModel {
        MemoryMappedFile trigram_mmap;

        // Remember the last offset since bsearch_ngram takes time and
        // the same 2-gram pair is likely to be used in the next call.
        uint32 last_value = 0;
        uint32 last_pvalue = 0;
        long last_offset = 0;

        long trigram_offset (LanguageModelEntry ppentry,
                             LanguageModelEntry pentry,
                             LanguageModelEntry entry)
        {
            var c = bigram_offset (ppentry, pentry);

            if (c == last_pvalue && entry.id == last_value)
                return last_offset;

            uint8[] buffer = new uint8[8];
            uint8 *p = buffer;
            var value = ((uint32) entry.id).to_little_endian ();
            Memory.copy (p, &value, sizeof(uint32));
            p += 4;
            var pvalue = ((uint32) c).to_little_endian ();
            Memory.copy (p, &pvalue, sizeof(uint32));

            var record_size = 10;
            var offset = LanguageModelUtils.bsearch_ngram (
                trigram_mmap.memory,
                0,
                (long) trigram_mmap.length / record_size,
                record_size,
                buffer);

            last_value = entry.id;
            last_pvalue = (uint32) c;
            last_offset = offset;

            return offset;
        }

        public bool has_trigram (LanguageModelEntry ppentry,
                                 LanguageModelEntry pentry,
                                 LanguageModelEntry entry)
        {
            return trigram_offset (ppentry, pentry, entry) >= 0;
        }

        public double trigram_cost (LanguageModelEntry ppentry,
                                    LanguageModelEntry pentry,
                                    LanguageModelEntry entry)
        {
            var offset = trigram_offset (ppentry, pentry, entry);
            if (offset < 0)
                return 0;

            uint8 *p = (uint8 *) trigram_mmap.memory + offset * 10 + 8;
            var cost = uint16.from_little_endian (*((uint16 *) p));
            return LanguageModelUtils.decode_cost (cost, min_cost);
        }

        construct {
            var prefix = Path.build_filename (metadata.base_dir, "data");
            var trigram_file = File.new_for_path (prefix + ".3gram");
			try {
				trigram_mmap = new MemoryMappedFile (trigram_file);
			} catch (IOError e) {
				error ("can't load %s: %s",
					   trigram_file.get_path (), e.message);
			}
        }
    }
}
