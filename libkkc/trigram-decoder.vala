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
    abstract class PathCostFunc {
        public abstract double path_cost (TrigramLanguageModel model,
                                          TrellisNode pnode,
                                          TrellisNode node);
    }

    class UnigramToUnigramPathCostFunc : PathCostFunc {
        public override double path_cost (TrigramLanguageModel model,
                                          TrellisNode pnode,
                                          TrellisNode node)
        {
            assert (pnode is UnigramTrellisNode);
            assert (node is UnigramTrellisNode);

            UnigramTrellisNode upnode = (UnigramTrellisNode) pnode;
            UnigramTrellisNode unode = (UnigramTrellisNode) node;

            double cost = 0.0;
            if (upnode.entry == model.bos) {
                cost = model.bigram_backoff_cost (upnode.entry, unode.entry);
            } else if (upnode.previous != null) {
                if (upnode.previous is UnigramTrellisNode) {
                    cost = model.trigram_backoff_cost (
                        ((UnigramTrellisNode) upnode.previous).entry,
                        upnode.entry,
                        unode.entry);
                } else {
                    cost = model.trigram_backoff_cost (
                        ((BigramTrellisNode) upnode.previous).right_node.entry,
                        upnode.entry,
                        unode.entry);
                }
            }

            return cost;
        }
    }

    class UnigramToBigramPathCostFunc : PathCostFunc {
        public override double path_cost (TrigramLanguageModel model,
                                          TrellisNode pnode,
                                          TrellisNode node)
        {
            assert (pnode is UnigramTrellisNode);
            assert (node is BigramTrellisNode);

            UnigramTrellisNode upnode = (UnigramTrellisNode) pnode;
            BigramTrellisNode bnode = (BigramTrellisNode) node;

            double cost = 0.0;
            if (upnode.entry == model.bos) {
                cost += model.bigram_backoff_cost (
                    upnode.entry,
                    bnode.left_node.entry);
            }

            cost += model.trigram_backoff_cost (
                upnode.entry,
                bnode.left_node.entry,
                bnode.right_node.entry);

            if (upnode.previous != null) {
                if (upnode.previous is UnigramTrellisNode) {
                    cost += model.trigram_backoff_cost (
                        ((UnigramTrellisNode) upnode.previous).entry,
                        upnode.entry,
                        bnode.left_node.entry);
                } else {
                    cost += model.trigram_backoff_cost (
                        ((BigramTrellisNode) upnode.previous).right_node.entry,
                        upnode.entry,
                        bnode.left_node.entry);
                }
            }

            return cost;
        }
    }

    class BigramToUnigramPathCostFunc : PathCostFunc {
        public override double path_cost (TrigramLanguageModel model,
                                          TrellisNode pnode,
                                          TrellisNode node)
        {
            assert (pnode is BigramTrellisNode);
            assert (node is UnigramTrellisNode);

            BigramTrellisNode bpnode = (BigramTrellisNode) pnode;
            UnigramTrellisNode unode = (UnigramTrellisNode) node;

            double cost = 0.0;
            if (bpnode.left_node.entry == model.bos) {
                cost += model.bigram_backoff_cost (
                    bpnode.left_node.entry,
                    bpnode.right_node.entry);
            }

            cost += model.trigram_backoff_cost (
                bpnode.left_node.entry,
                bpnode.right_node.entry,
                unode.entry);

            return cost;
        }
    }

    class BigramToBigramPathCostFunc : PathCostFunc {
        public override double path_cost (TrigramLanguageModel model,
                                          TrellisNode pnode,
                                          TrellisNode node)
        {
            assert (pnode is BigramTrellisNode);
            assert (node is BigramTrellisNode);

            BigramTrellisNode bpnode = (BigramTrellisNode) pnode;
            BigramTrellisNode bnode = (BigramTrellisNode) node;

            double cost = 0.0;
            if (bpnode.left_node.entry == model.bos) {
                cost += model.bigram_backoff_cost (
                    bpnode.left_node.entry,
                    bpnode.right_node.entry);
            }

            cost += model.trigram_backoff_cost (
                bpnode.left_node.entry,
                bpnode.right_node.entry,
                bnode.left_node.entry);

            cost += model.trigram_backoff_cost (
                bpnode.right_node.entry,
                bnode.left_node.entry,
                bnode.right_node.entry);

            return cost;
        }
    }

    public class TrigramDecoder : BigramDecoder {
        public override Segment[] decode (string input,
                                          int nbest,
                                          int[] constraint)
        {
            return decode_with_costs (input,
                                      nbest,
                                      constraint,
                                      double.MAX,
                                      -double.MAX);
        }

        public override Segment[] decode_with_costs (string input,
                                                     int nbest,
                                                     int[] constraint,
                                                     double max_distance,
                                                     double min_path_cost)
        {
            var trellis = build_trellis (input, constraint);
            add_trigram_nodes (trellis);
            add_unknown_nodes (trellis, input, constraint);

            forward_search (trellis, input);
            return backward_search (trellis,
                                    nbest,
                                    max_distance,
                                    min_path_cost);
        }

        void add_trigram_nodes (ArrayList<TrellisNode>[] trellis) {
            var trigram_trellis = new ArrayList<TrellisNode>[trellis.length];
            for (var i = 0; i < trigram_trellis.length; i++) {
                trigram_trellis[i] = new ArrayList<TrellisNode> ();
            }

            var overlapped_nodes = new HashSet<TrellisNode>[trellis.length];
            for (var i = 0; i < overlapped_nodes.length; i++) {
                overlapped_nodes[i] = new HashSet<TrellisNode> (direct_hash,
                                                                direct_equal);
            }

            for (var i = 1; i < trellis.length; i++) {
                foreach (var node in trellis[i]) {
                    var unode = node as UnigramTrellisNode;
                    int j = i - (int) node.length;
                    foreach (var pnode in trellis[j]) {
                        var upnode = pnode as UnigramTrellisNode;
                        if (!model.has_bigram (upnode.entry, unode.entry))
                            continue;

                        int k = j - (int) pnode.length;
                        if (k < 0)
                            continue;
                        foreach (var ppnode in trellis[k]) {
                            var uppnode = ppnode as UnigramTrellisNode;

                            if (!overlapped_nodes[k].contains (uppnode) &&
                                ((TrigramLanguageModel)model).has_trigram (uppnode.entry,
                                                                 upnode.entry,
                                                                 unode.entry)) {
                                var bigram_node = new BigramTrellisNode (
                                    uppnode,
                                    upnode,
                                    j);
                                trigram_trellis[j].add (bigram_node);
                                overlapped_nodes[j].add (upnode);
                            }
                        }
                    }
                }
            }
            for (var i = 0; i < trellis.length; i++) {
                trellis[i].add_all (trigram_trellis[i]);
            }
        }

        int path_to_func_index (TrellisNode pnode, TrellisNode node) {
            var pnode_index = (pnode is UnigramTrellisNode) ? 0 : 1;
            var node_index = (node is UnigramTrellisNode) ? 0 : 1;
            return (pnode_index << 1) + node_index;
        }

        PathCostFunc path_cost_funcs[4];

        protected override double path_cost (TrellisNode pnode,
                                             TrellisNode node,
                                             int endpos)
        {
            var index = path_to_func_index (pnode, node);
            return path_cost_funcs[index].path_cost ((TrigramLanguageModel) model,
                                                     pnode,
                                                     node);
        }

        public TrigramDecoder (TrigramLanguageModel model) {
            base (model);

            path_cost_funcs[0] = new UnigramToUnigramPathCostFunc ();
            path_cost_funcs[1] = new UnigramToBigramPathCostFunc ();
            path_cost_funcs[2] = new BigramToUnigramPathCostFunc ();
            path_cost_funcs[3] = new BigramToBigramPathCostFunc ();
        }
    }
}
