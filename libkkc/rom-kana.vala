// -*- coding: utf-8 -*-
/*
 * Copyright (C) 2011-2013 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2011-2013 Red Hat, Inc.
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
    struct RomKanaEntry {
        string rom;
        string carryover;
        string hiragana;
        string katakana;
        string hiragana_partial;
        string katakana_partial;

        public string get_kana (KanaMode mode, bool partial) {
            switch (mode) {
            case KanaMode.HIRAGANA:
                return partial ? hiragana_partial : hiragana;
            case KanaMode.KATAKANA:
                return partial ? katakana_partial : katakana;
            default:
                return RomKanaUtils.convert_by_kana_mode (
                    partial ? hiragana_partial : hiragana,
                    mode);
            }
        }
    }

    static const string[] PUNCTUATION_RULE = {"。、", "．，", "。，", "．、"};

    class RomKanaNode : Object {
        internal RomKanaEntry? entry;
        internal weak RomKanaNode parent;
        internal RomKanaNode children[256];
        internal char c;
        internal uint n_children = 0;
        internal uint8 valid[32];

        internal RomKanaNode (RomKanaEntry? entry) {
            this.entry = entry;
            for (int i = 0; i < children.length; i++) {
                children[i] = null;
            }
            Memory.set (valid, 0, valid.length);
        }

        internal void insert (string key, RomKanaEntry entry) {
            var node = this;
            int index = 0;
            unichar uc;
            while (key.get_next_char (ref index, out uc)) {
                if (node.children[uc] == null) {
                    var child = node.children[uc] = new RomKanaNode (null);
                    child.parent = node;
                }
                node.n_children++;
                node = node.children[uc];
                valid[uc / 8] |= (uint8) (1 << (uc % 8));
            }
            node.entry = entry;
        }

#if 0
        RomKanaNode? lookup_node (string key) {
            var node = this;
            for (var i = 0; i < key.length; i++) {
                node = node.children[key[i]];
                if (node == null)
                    return null;
            }
            return node;
        }

        internal RomKanaEntry? lookup (string key) {
            var node = lookup_node (key);
            if (node == null)
                return null;
            return node.entry;
        }

        void remove_child (RomKanaNode node) {
            children[node.c] = null;
            if (--n_children == 0 && parent != null) {
                parent.remove_child (this);
            }
        }

        internal void @remove (string key) {
            var node = lookup_node (key);
            if (node != null) {
                return_if_fail (node.parent != null);
                node.parent.remove_child (node);
            }
        }
#endif
    }

    /**
     * Type representing kana scripts.
     */
    public enum KanaMode {
        /**
         * Hiragana like "あいう...".
         */
        HIRAGANA,

        /**
         * Katakana like "アイウ...".
         */
        KATAKANA,

        /**
         * Half-width katakana like "ｱｲｳ...".
         */
        HANKAKU_KATAKANA,

        /**
         * Half-width latin like "abc...".
         */
        LATIN,

        /**
         * Full-width latin like "ａｂｃ...".
         */
        WIDE_LATIN
    }

    /**
     * Type to specify how "." and "," are converted.
     */
    public enum PunctuationStyle {
        /**
         * Use "。" and "、" for "." and ",".
         */
        JA_JA,

        /**
         * Use "．" and "，" for "." and ",".
         */
        EN_EN,

        /**
         * Use "。" and "，" for "." and ",".
         */
        JA_EN,

        /**
         * Use "．" and "、" for "." and ",".
         */
        EN_JA
    }

    public struct RomKanaCharacter {
        string output;
        string input;
    }

    /**
     * Romaji-to-kana converter.
     */
    public class RomKanaConverter : Object {
        RomKanaMapFile _rule;
        internal RomKanaMapFile rule {
            get {
                return _rule;
            }
            set {
                _rule = value;
                current_node = _rule.root_node;
            }
        }

        RomKanaNode current_node;

        public KanaMode kana_mode { get; set; default = KanaMode.HIRAGANA; }
        public PunctuationStyle punctuation_style { get; set; default = PunctuationStyle.JA_JA; }

        StringBuilder _pending_output = new StringBuilder ();
        public string pending_output {
            get {
                return _pending_output.str;
            }
        }

        StringBuilder _pending_input = new StringBuilder ();
        public string pending_input {
            get {
                return _pending_input.str;
            }
        }

        Gee.List<RomKanaCharacter?> _produced = new ArrayList<RomKanaCharacter?> ();
        public RomKanaCharacter[] get_produced () {
            RomKanaCharacter[] array = new RomKanaCharacter[_produced.size];
            for (var i = 0; i < _produced.size; i++)
                array[i] = _produced[i];
            return array;
        }

        public string get_produced_output () {
            var builder = new StringBuilder ();
            foreach (var c in _produced) {
                builder.append (c.output);
            }
            return builder.str;
        }

        public void clear_produced () {
            _produced.clear ();
        }

        public RomKanaConverter () {
            try {
                _rule = new RomKanaMapFile (Rule.find_rule ("default"));
                current_node = _rule.root_node;
            } catch (RuleParseError e) {
                warning ("can't find default rom-kana rule: %s",
                         e.message);
                assert_not_reached ();
            }
        }

        public bool is_valid (unichar uc) {
            if (uc > 256)
                return false;
            uint8 mask = (uint8) (1 << (uc % 8));
            return (current_node.valid[uc / 8] & mask) != 0 ||
                (_rule.root_node.valid[uc / 8] & mask) != 0;
        }

        /**
         * Finish pending input, if any.
         */
        public bool flush_partial () {
            if (current_node.entry != null) {
                var partial = current_node.entry.get_kana (kana_mode, true);
                if (partial.length > 0) {
                    _produced.add (RomKanaCharacter () {
                            output = partial, input = _pending_input.str
                        });
                    _pending_input.erase ();
                    _pending_output.erase ();
                    current_node = rule.root_node;
                    return true;
                }
            }
            return false;
        }

        /**
         * Append text to the internal buffer.
         *
         * @param text a string
         */
        public void append_text (string text) {
            int index = 0;
            unichar c;
            while (text.get_next_char (ref index, out c)) {
                append (c);
            }
        }

        bool append_punctuation (unichar uc) {
            var index = -1;
            if (is_valid (uc)) {
                var node = current_node.children[uc];
                if (node != null && node.entry != null) {
                    if (node.entry.hiragana == "。")
                        index = 0;
                    else if (node.entry.hiragana == "、")
                        index = 1;
                }
            }
            if (index >= 0) {
                if (current_node.entry != null) {
                    _produced.add (RomKanaCharacter () {
                            output = _pending_output.str,
                            input = _pending_input.str
                        });
                }
                index = PUNCTUATION_RULE[punctuation_style].index_of_nth_char (index);
                unichar punctuation = PUNCTUATION_RULE[punctuation_style].get_char (index);
                _produced.add (RomKanaCharacter () {
                        output = punctuation.to_string (),
                        input = uc.to_string ()
                    });
                _pending_input.erase ();
                _pending_output.erase ();
                current_node = rule.root_node;
                return true;
            }
            return false;
        }

        /**
         * Append a character to the internal buffer.
         *
         * @param uc an ASCII character
         *
         * @return `true` if the character is handled, `false` otherwise
         */
        public bool append (unichar uc) {
            var child_node = current_node.children[uc];
            if (child_node == null) {
                // No such transition path in trie.
                var retval = flush_partial ();
                if (append_punctuation (uc)) {
                    return true;
                } else if (rule.root_node.children[uc] == null) {
                    _pending_input.erase ();
                    _pending_output.erase ();
                    current_node = rule.root_node;
                    return retval;
                } else if (current_node.entry != null) {
                    _produced.add (RomKanaCharacter () {
                            output = _pending_output.str,
                            input = _pending_input.str
                        });
                    current_node = rule.root_node;
                    _pending_input.erase ();
                    _pending_output.erase ();
                    return append (uc);
                } else {
                    // Abandon the pending input and restart lookup
                    // from the root with uc.
                    _pending_input.erase ();
                    _pending_output.erase ();
                    current_node = rule.root_node;
                    return append (uc);
                }
            } else if (child_node.n_children > 0) {
                // Node is non-terminal.
                if (child_node.entry != null) {
                    _pending_input.append_unichar (uc);
                    _pending_output.append (
                        child_node.entry.get_kana (kana_mode,
                                                   false));
                } else {
                    _pending_input.append_unichar (uc);
                    _pending_output.append_unichar (uc);
                }
                current_node = child_node;
                return true;
            } else {
                // Node is terminal.
                if (append_punctuation (uc))
                    return true;
                var str = child_node.entry.get_kana (kana_mode, false);
                _pending_input.append_unichar (uc);
                _produced.add (RomKanaCharacter () {
                        output = str, input = _pending_input.str
                    });
                _pending_input.erase ();
                _pending_output.erase ();
                current_node = rule.root_node;
                for (int i = 0; i < child_node.entry.carryover.length; i++) {
                    append (child_node.entry.carryover[i]);
                }
                return true;
            }
        }

        /**
         * Check if a character will be consumed by the current conversion.
         *
         * @param uc an ASCII character
         * @param no_carryover return false if there will be carryover
         *
         * @return `true` if the character can be consumed
         */
        public bool can_consume (unichar uc,
                                 bool no_carryover = true)
        {
            var child_node = current_node.children[uc];
            if (child_node == null)
                return false;
            if (no_carryover &&
                child_node.entry != null && child_node.entry.carryover != "")
                return false;
            return true;
        }

        /**
         * Reset the internal state of the converter.
         */
        public void reset () {
            clear_produced ();
            _pending_input.erase ();
            _pending_output.erase ();
            current_node = rule.root_node;
        }

        /**
         * Delete the trailing character from the internal buffer.
         *
         * @return `true` if any character is removed, `false` otherwise
         */
        public bool delete () {
            if (_pending_output.len > 0) {
                current_node = current_node.parent;
                if (current_node == null)
                    current_node = rule.root_node;
                _pending_output.truncate (
                    _pending_output.str.index_of_nth_char (
                        _pending_output.str.char_count () - 1));
                _pending_input.truncate (
                    _pending_input.str.index_of_nth_char (
                        _pending_input.str.char_count () - 1));
                return true;
            }
            if (_produced.size > 0) {
                _produced.remove_at (_produced.size - 1);
                return true;
            }
            return false;
        }
    }
}
