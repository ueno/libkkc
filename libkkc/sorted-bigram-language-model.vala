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
    public class SortedBigramLanguageModel : LanguageModel, UnigramLanguageModel, BigramLanguageModel {
        LanguageModelEntry _bos;
        public override LanguageModelEntry bos {
            get {
                return _bos;
            }
        }

        LanguageModelEntry _eos;
        public override LanguageModelEntry eos {
            get {
                return _eos;
            }
        }

        Marisa.Trie input_trie = new Marisa.Trie ();
        Marisa.Trie unigram_trie = new Marisa.Trie ();
        MemoryMappedFile unigram_mmap;
        MemoryMappedFile bigram_mmap;

        Collection<LanguageModelEntry?> unigram_entries_with_prefix (string prefix) {
            var entries = new ArrayList<LanguageModelEntry?> ();
            var agent = new Marisa.Agent ();
            var query = prefix + "/";
            agent.set_query (query.data);
            while (unigram_trie.predictive_search (agent)) {
                var key = agent.get_key ();
                var input_output = key.get_string ().split ("/");
                var id = (uint) key.get_id ();
                LanguageModelEntry entry = {
                    input_output[0],
                    input_output[1],
                    id
                };
                entries.add (entry);
            }
            return entries;
        }

        public override Collection<LanguageModelEntry?> entries (string input) {
            var entries = new ArrayList<LanguageModelEntry?> ();
            var agent = new Marisa.Agent ();
            agent.set_query (input.data);
            while (input_trie.common_prefix_search (agent)) {
                var prefix = agent.get_key ().get_string ();
                entries.add_all (unigram_entries_with_prefix (prefix));
            }
            return entries;
        }

        public override LanguageModelEntry? @get (string input, string output) {
            var agent = new Marisa.Agent ();
            string query;
            if (input != " ")
                query = "%s/%s".printf (input, output);
            else
                query = output;
            agent.set_query (query.data);
            if (unigram_trie.lookup (agent)) {
                var id = agent.get_key ().get_id ();
                LanguageModelEntry entry = {
                    input,
                    output,
                    (uint) id
                };
                return entry;
            }
            return null;
        }

        // Remember the last offset since bsearch_ngram takes time and
        // the same 2-gram pair is likely to be used in the next call.
        uint32 last_value = 0;
        uint32 last_pvalue = 0;
        long last_offset = 0;

        protected long bigram_offset (LanguageModelEntry pentry, LanguageModelEntry entry) {
            if (pentry.id == last_pvalue && entry.id == last_value)
                return last_offset;

            uint8[] buffer = new uint8[8];
            uint8 *p = buffer;
            var value = ((uint32) entry.id).to_little_endian ();
            Memory.copy (p, &value, sizeof(uint32));
            p += 4;
            var pvalue = ((uint32) pentry.id).to_little_endian ();
            Memory.copy (p, &pvalue, sizeof(uint32));

            var record_size = 12;
            var offset = LanguageModelUtils.bsearch_ngram (
                bigram_mmap.memory,
                0,
                (long) bigram_mmap.length / record_size,
                record_size,
                buffer);

            last_value = entry.id;
            last_pvalue = pentry.id;
            last_offset = offset;

            return offset;
        }

        public double unigram_cost (LanguageModelEntry entry) {
            if (entry.id >= unigram_mmap.length)
                return 0;

            uint8 *p = (uint8 *) unigram_mmap.memory + entry.id * 6;
            var cost = uint16.from_little_endian (*((uint16 *) p));
            return LanguageModelUtils.decode_cost (cost, min_cost);
        }

        public double unigram_backoff (LanguageModelEntry entry) {
            if (entry.id >= unigram_mmap.length)
                return 0;

            uint8 *p = (uint8 *) unigram_mmap.memory + entry.id * 6 + 2;
            var backoff = uint16.from_little_endian (*((uint16 *) p));
            return LanguageModelUtils.decode_cost (backoff, min_cost);
        }

        public bool has_bigram (LanguageModelEntry pentry, LanguageModelEntry entry) {
            return bigram_offset (pentry, entry) >= 0;
        }

        public double bigram_cost (LanguageModelEntry pentry, LanguageModelEntry entry) {
            var offset = bigram_offset (pentry, entry);
            if (offset < 0)
                return 0;

            uint8 *p = (uint8 *) bigram_mmap.memory + offset * 12 + 8;
            var cost = uint16.from_little_endian (*((uint16 *) p));
            return LanguageModelUtils.decode_cost (cost, min_cost);
        }

        public double bigram_backoff (LanguageModelEntry pentry, LanguageModelEntry entry) {
            var offset = bigram_offset (pentry, entry);
            if (offset < 0)
                return 0;

            uint8 *p = (uint8 *) bigram_mmap.memory + offset * 12 + 10;
            var backoff = uint16.from_little_endian (*((uint16 *) p));
            return LanguageModelUtils.decode_cost (backoff, min_cost);
        }

        public double min_cost {
            get {
                return -8.0;
            }
        }

        construct {
            var prefix = Path.build_filename (metadata.base_dir, "data");

			var input_trie_filename = prefix + ".input";
			try {
				input_trie.mmap (input_trie_filename);
			} catch (GLib.Error e) {
				error ("can't load %s: %s", input_trie_filename, e.message);
			}

			var unigram_trie_filename = prefix + ".1gram.index";
			try {
				unigram_trie.mmap (unigram_trie_filename);
			} catch (GLib.Error e) {
				error ("can't load %s: %s", unigram_trie_filename, e.message);
			}

            var unigram_file = File.new_for_path (prefix + ".1gram");
			try {
				unigram_mmap = new MemoryMappedFile (unigram_file);
			} catch (IOError e) {
				error ("can't load %s: %s",
					   unigram_file.get_path (), e.message);
			}

            var bigram_file = File.new_for_path (prefix + ".2gram");
			try {
				bigram_mmap = new MemoryMappedFile (bigram_file);
			} catch (IOError e) {
				error ("can't load %s: %s",
					   bigram_file.get_path (), e.message);
			}

            _bos = get (" ", "<s>");
            _eos = get (" ", "</s>");
        }
    }
}
