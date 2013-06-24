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
        IndexFile unigram_index;
        IndexFile bigram_index;
        BloomFilter bigram_filter = null;

        public override Collection<LanguageModelEntry?> unigram_entries (string prefix) {
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
                entries.add_all (unigram_entries (prefix));
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

            if (bigram_filter != null
                && !bigram_filter.contains (entry.id, pentry.id))
                return -1;

            uint8[] buffer = new uint8[8];
            uint8 *p = buffer;
            var value = (uint32) entry.id;
            Memory.copy (p, &value, sizeof(uint32));
            p += 4;
            var pvalue = (uint32) pentry.id;
            Memory.copy (p, &pvalue, sizeof(uint32));

            var record_size = 12;
            var offset = LanguageModelUtils.bsearch_ngram (
                bigram_index.get_contents (),
                0,
                (long) bigram_index.get_length () / record_size,
                record_size,
                buffer);

            last_value = entry.id;
            last_pvalue = pentry.id;
            last_offset = offset;

            return offset;
        }

        public double unigram_cost (LanguageModelEntry entry) {
            if (entry.id >= unigram_index.get_length ())
                return 0;

            uint8 *p = (uint8 *) unigram_index.get_contents () + entry.id * 6;
            var cost = *((uint16 *) p);
            return LanguageModelUtils.decode_cost (cost, min_cost);
        }

        public double unigram_backoff (LanguageModelEntry entry) {
            if (entry.id >= unigram_index.get_length ())
                return 0;

            uint8 *p = (uint8 *) unigram_index.get_contents () + entry.id * 6 + 2;
            var backoff = *((uint16 *) p);
            return LanguageModelUtils.decode_cost (backoff, min_cost);
        }

        public bool has_bigram (LanguageModelEntry pentry, LanguageModelEntry entry) {
            return bigram_offset (pentry, entry) >= 0;
        }

        public double bigram_cost (LanguageModelEntry pentry, LanguageModelEntry entry) {
            var offset = bigram_offset (pentry, entry);
            if (offset < 0)
                return 0;

            uint8 *p = (uint8 *) bigram_index.get_contents () + offset * 12 + 8;
            var cost = *((uint16 *) p);
            return LanguageModelUtils.decode_cost (cost, min_cost);
        }

        public double bigram_backoff (LanguageModelEntry pentry, LanguageModelEntry entry) {
            var offset = bigram_offset (pentry, entry);
            if (offset < 0)
                return 0;

            uint8 *p = (uint8 *) bigram_index.get_contents () + offset * 12 + 10;
            var backoff = *((uint16 *) p);
            return LanguageModelUtils.decode_cost (backoff, min_cost);
        }

        public double min_cost {
            get {
                return -8.0;
            }
        }

        public override bool parse () throws Error {
            var prefix = Path.build_filename (
                Path.get_dirname (metadata.filename),
                "data");

			var input_trie_filename = prefix + ".input";
            input_trie.mmap (input_trie_filename);

			var unigram_trie_filename = prefix + ".1gram.index";
            unigram_trie.mmap (unigram_trie_filename);

            if (use_mapped_index_file) {
                unigram_index = new MappedIndexFile (prefix + ".1gram");
                bigram_index = new MappedIndexFile (prefix + ".2gram");
            } else {
                unigram_index = new LoadedIndexFile (prefix + ".1gram");
                bigram_index = new LoadedIndexFile (prefix + ".2gram");
            }

            var bigram_filter_filename = prefix + ".2gram.filter";
            try {
                bigram_filter = new BloomFilter (bigram_filter_filename);
            } catch (Error e) {
                warning ("can't load %s: %s",
                         bigram_filter_filename,
                         e.message);
            }

            _bos = get (" ", "<s>");
            _eos = get (" ", "</s>");

            return true;
        }

        public SortedBigramLanguageModel (LanguageModelMetadata metadata) throws Error {
            base (metadata);
        }
    }
}
