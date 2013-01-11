/*
 * Copyright (C) 2012-2013 Daiki Ueno <ueno@unixuser.org>
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
    class NbestNode {
        public TrellisNode node;

        public double gn = 0.0;
        public double fn = double.MAX;

        public NbestNode? next;

        public NbestNode (TrellisNode node) {
            this.node = node;
        }
    }

    public class BigramDecoder : Decoder {
        public override Segment[] decode (string input,
                                          int nbest,
                                          int[] constraints)
        {
            var trellis = build_trellis (input, constraints);
            add_unknown_nodes (trellis, input);
            forward_search (trellis, input);
            return backward_search (trellis, nbest);
        }

        protected void add_unknown_nodes (ArrayList<TrellisNode>[] trellis,
                                          string input)
        {
            for (var i = 1; i < trellis.length; i++) {
                for (var j = i;
                     j < trellis.length && trellis[j].is_empty;
                     j++)
                {
                    long offset = input.index_of_nth_char (i - 1);
                    long length = input.index_of_nth_char (j) - offset;
                    var _input = input.substring (offset, length);
                    LanguageModelEntry entry = {
                        _input,
                        _input,
                        2
                    };
                    var node = new UnigramTrellisNode (entry, j);
                    trellis[j].add (node);
                }
            }
        }

        protected ArrayList<TrellisNode>[] build_trellis (string input,
                                                          int[] constraints)
        {
            var length = input.char_count ();
            var trellis = new ArrayList<TrellisNode>[length + 2];
            for (var i = 0; i < trellis.length; i++) {
                trellis[i] = new ArrayList<TrellisNode> ();
            }

            var bos_node = new UnigramTrellisNode (dict.bos, 1);
            trellis[0].add (bos_node);

            var eos_node = new UnigramTrellisNode (dict.eos, length + 1);
            trellis[length + 1].add (eos_node);

            for (var i = 0; i < length; i++) {
                long byte_offset = input.index_of_nth_char (i);
                var _input = input.substring (byte_offset);
                var entries = dict.entries (_input);
                foreach (var entry in entries) {
                    var j = i + entry.input.char_count ();
                    if (!check_constraints (constraints, i, j))
                        continue;
                    var node = new UnigramTrellisNode (entry, j);
                    trellis[j].add (node);
                }
            }
            return trellis;
        }

        bool check_constraints (int[] constraints, int i, int j) {
            int last_c = 0;
            foreach (var c in constraints) {
                if (i == last_c && j == c) {
                    return true;
                }
                last_c = c;
            }
            return i >= last_c;
        }

        protected void forward_search (ArrayList<TrellisNode>[] trellis,
                                       string input) {
            for (var i = 1; i < trellis.length; i++) {
                foreach (var node in trellis[i]) {
                    int j = i - (int) node.length;
                    if (j < 0)
                        continue;
                    double max_cost = - double.MAX;
                    TrellisNode? max_pnode = null;
                    foreach (var pnode in trellis[j]) {
                        var cost = pnode.cumulative_cost + path_cost (pnode, node, j);
                        if (cost > max_cost) {
                            max_pnode = pnode;
                            max_cost = cost;
                        }
                    }
                    if (max_pnode == null) {
                        max_pnode = trellis[i][0];
                    }
                    node.cumulative_cost = max_cost;
                    node.previous = max_pnode;
#if false
                    stdout.printf ("%s -> %s: %lf %lf %d %d\n",
                                   max_pnode.to_string (),
                                   node.to_string(),
                                   max_cost,
                                   path_cost (max_pnode,
                                              node,
                                              j),
                                   j,
                                   i);
#endif
                }
            }
        }

        protected virtual double path_cost (TrellisNode pnode,
                                            TrellisNode node,
                                            int endpos)
        {
            var upnode = pnode as UnigramTrellisNode;
            var unode = node as UnigramTrellisNode;
            assert (upnode != null && unode != null);
            return dict.bigram_backoff_cost (upnode.entry, unode.entry);
        }

        Segment nbest_node_to_segment (NbestNode nbest_node) {
            Segment? start_segment = null;
            Segment? previous_segment = null;
            for (; nbest_node.next != null; nbest_node = nbest_node.next) {
                for (var i = 0; i < nbest_node.node.entries.length; i++) {
                    var entry = nbest_node.node.entries[i];
                    var segment = new Segment (entry.input, entry.output);
                    if (start_segment == null)
                        start_segment = segment;
                    if (previous_segment != null)
                        previous_segment.next = segment;
                    previous_segment = segment;
                }
            }
            return start_segment;
        }

        protected Segment[] backward_search (ArrayList<TrellisNode>[] trellis,
                                             int nbest)
        {
            var bos_trellis_node = trellis[0][0];
            var eos_trellis_node = trellis[trellis.length - 1][0];

            if (nbest == 1) {
                Segment? segment = null;
                Segment? next_segment = null;
                for (var node = eos_trellis_node.previous;
                     node != null;
                     node = node.previous)
                {
                    for (var i = node.entries.length - 1; i >= 0; i--) {
                        var entry = node.entries[i];
                        if (entry == dict.bos)
                            break;
                        segment = new Segment (entry.input, entry.output);
                        segment.next = next_segment;
                        next_segment = segment;
                    }
                }
                return new Segment[] { segment };
            }

            var trellis_nbest_map = new HashMap<TrellisNode,NbestNode> (
                direct_hash,
                direct_equal);

            var open_list = new PriorityQueue<NbestNode> (
                (CompareFunc)compare_nbest_node);

            var close_list = new PriorityQueue<NbestNode> (
                (CompareFunc)compare_nbest_node);

            var duplicates = new HashSet<string> (str_hash, str_equal);

            var eos_nbest_node = new NbestNode (eos_trellis_node);
            trellis_nbest_map.set (eos_trellis_node, eos_nbest_node);
            open_list.add (eos_nbest_node);

            while (!open_list.is_empty) {
                var current_nbest_node = open_list.poll ();
                if (current_nbest_node.node == bos_trellis_node) {
                    var output = concat_nbest_node_outputs (current_nbest_node);
                    if (!duplicates.contains (output)) {
                        close_list.add (current_nbest_node);
                        if (close_list.size == nbest)
                            break;
                        duplicates.add (output);
                    }
                } else if (current_nbest_node.node.endpos >= current_nbest_node.node.length) {
                    var i = (int) current_nbest_node.node.endpos - current_nbest_node.node.length;
                    foreach (var trellis_node in trellis[i]) {
                        var nbest_node = new NbestNode (trellis_node);
                        var cost = nbest_node.node.cumulative_cost + path_cost (
                            nbest_node.node,
                            current_nbest_node.node,
                            (int) i);

                        nbest_node.gn = cost + current_nbest_node.gn;
                        nbest_node.fn = nbest_node.gn + nbest_node.node.cumulative_cost;
                        nbest_node.next = current_nbest_node;

                        trellis_nbest_map.set (trellis_node, nbest_node);
                        open_list.add (nbest_node);
                    }
                }
            }

            ArrayList<Segment> segments = new ArrayList<Segment> ();
            foreach (var nbest_node in close_list)
                segments.add (nbest_node_to_segment (nbest_node.next));
            return segments.to_array ();
        }
        
        static int compare_nbest_node (NbestNode a, NbestNode b) {
            return (int) b.fn - (int) a.fn; 
        }

        string concat_nbest_node_outputs (NbestNode nbest_node) {
            var builder = new StringBuilder ();
            while (nbest_node != null) {
                builder.append (nbest_node.node.output);
                nbest_node = nbest_node.next;
            }
            return builder.str;
        }

        BigramLanguageModel _dict;
        public BigramLanguageModel dict {
            get {
                return _dict;
            }
        }

        public BigramDecoder (BigramLanguageModel dict) {
            _dict = dict;
        }
    }
}
