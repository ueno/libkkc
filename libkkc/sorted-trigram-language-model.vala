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
    public class SortedTrigramLanguageModel : SortedBigramLanguageModel, TrigramLanguageModel {
        MemoryMappedFile trigram_mmap;

        long trigram_offset (LanguageModelEntry ppentry,
                             LanguageModelEntry pentry,
                             LanguageModelEntry entry)
        {
            var c = bigram_offset (ppentry, pentry);
            uint8[] buffer = new uint8[8];
            uint8 *p = buffer;
            var value = ((uint32) entry.id).to_little_endian ();
            Memory.copy (p, &value, sizeof(uint32));
            p += 4;
            var pvalue = ((uint32) c).to_little_endian ();
            Memory.copy (p, &pvalue, sizeof(uint32));

            var record_size = 10;
            var offset = Util.bsearch_ngram (
                trigram_mmap.memory,
                0,
                (long) trigram_mmap.length / record_size,
                record_size,
                buffer);
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
            return Util.decode_cost (cost, min_cost);
        }

        construct {
            var prefix = Path.build_filename (metadata.base_dir, "data");
            var trigram_file = File.new_for_path (prefix + ".3gram");
			try {
				trigram_mmap = new MemoryMappedFile (trigram_file);
			} catch (Kkc.LanguageModelError e) {
				error ("can't load %s: %s",
					   trigram_file.get_path (), e.message);
			}
        }
    }
}
