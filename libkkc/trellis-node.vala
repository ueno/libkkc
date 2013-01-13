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
    public abstract class TrellisNode {
        public abstract uint endpos { get; }
        public abstract uint length { get; }
        public abstract string input { owned get; }
        public abstract string output { owned get; }

        public TrellisNode? previous;
        public double cumulative_cost;

        public abstract string to_string ();
        public abstract LanguageModelEntry[] entries { get; }
    }

    public class UnigramTrellisNode : TrellisNode {
        LanguageModelEntry _entry;
        public LanguageModelEntry entry {
            get {
                return _entry;
            }
        }

        public override string input {
            owned get {
                return _entry.input;
            }
        }

        public override string output {
            owned get {
                return _entry.output;
            }
        }

        uint _endpos;
        public override uint endpos {
            get {
                return _endpos;
            }
        }

        public override uint length {
            get {
                return _entry.input.char_count ();
            }
        }

        public UnigramTrellisNode (LanguageModelEntry entry, uint endpos) {
            _entry = entry;
            _endpos = endpos;
            _entries = new LanguageModelEntry[] { _entry };
        }

        public override string to_string () {
            return "<%s/%s>".printf (_entry.input, _entry.output);
        }

        LanguageModelEntry[] _entries;
        public override LanguageModelEntry[] entries {
            get {
                return _entries;
            }
        }
    }

    public class BigramTrellisNode : TrellisNode {
        UnigramTrellisNode _left_node;
        public UnigramTrellisNode left_node {
            get {
                return _left_node;
            }
        }

        UnigramTrellisNode _right_node;
        public UnigramTrellisNode right_node {
            get {
                return _right_node;
            }
        }

        public override string input {
            owned get {
                if (_endpos < _right_node.endpos)
                    return _left_node.entry.input;
                return _left_node.entry.input + _right_node.entry.input;
            }
        }

        public override string output {
            owned get {
                if (_endpos < _right_node.endpos)
                    return _left_node.entry.output;
                return _left_node.entry.output + _right_node.entry.output;
            }
        }

        uint _endpos;
        public override uint endpos {
            get {
                return _endpos;
            }
        }

        public override uint length {
            get {
                return input.char_count ();
            }
        }

        public BigramTrellisNode (UnigramTrellisNode left_node,
                                  UnigramTrellisNode right_node,
                                  uint endpos)
        {
            _left_node = left_node;
            _right_node = right_node;
            _endpos = endpos;
            _entries = new LanguageModelEntry[] { left_node.entry, right_node.entry };
        }

        public override string to_string () {
            return "<%s/%s><%s/%s>".printf (_left_node.entry.input,
                                            _left_node.entry.output,
                                            _right_node.entry.input,
                                            _right_node.entry.output);
        }

        LanguageModelEntry[] _entries;
        public override LanguageModelEntry[] entries {
            get {
                return _entries;
            }
        }
    }
}
