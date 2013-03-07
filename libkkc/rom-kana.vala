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
        WIDE_LATIN,

        LAST
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
        bool preserve_preedit;

        public KanaMode kana_mode { get; set; default = KanaMode.HIRAGANA; }
        public PunctuationStyle punctuation_style { get; set; default = PunctuationStyle.JA_JA; }

        StringBuilder _output = new StringBuilder ();
        StringBuilder _preedit = new StringBuilder ();

        public string output {
            get {
                return _output.str;
            }
            internal set {
                _output.assign (value);
            }
        }
        public string preedit {
            get {
                return _preedit.str;
            }
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
         * Flush partial output, if any.
         */
        public bool flush_partial () {
            if (current_node.entry != null) {
                var partial = current_node.entry.get_kana (kana_mode, true);
                if (partial.length > 0) {
                    _output.append (partial);
                    _preedit.erase ();
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
                if (preserve_preedit)
                    _output.append (_preedit.str);
                index = PUNCTUATION_RULE[punctuation_style].index_of_nth_char (index);
                unichar punctuation = PUNCTUATION_RULE[punctuation_style].get_char (index);
                _output.append_unichar (punctuation);
                _preedit.erase ();
                current_node = rule.root_node;
                preserve_preedit = false;
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
                // no such transition path in trie
                var retval = flush_partial ();
                if (append_punctuation (uc)) {
                    return true;
                } else if (rule.root_node.children[uc] == null) {
                    _preedit.erase ();
                    current_node = rule.root_node;
                    preserve_preedit = false;
                    // there may be "NN" output
                    return retval;
                } else if (preserve_preedit) {
                    _output.append (_preedit.str);
                    current_node = rule.root_node;
                    preserve_preedit = false;
                    _preedit.erase ();
                    return append (uc);
                } else {
                    // abandon the current preedit and restart lookup from
                    // the root with uc
                    _preedit.erase ();
                    current_node = rule.root_node;
                    preserve_preedit = false;
                    return append (uc);
                }
            } else if (child_node.n_children > 0) {
                // node is not a terminal
                if (child_node.entry != null) {
                    _preedit.append (child_node.entry.get_kana (kana_mode,
                                                                false));
                    preserve_preedit = true;
                } else {
                    _preedit.append_unichar (uc);
                    preserve_preedit = false;
                }
                current_node = child_node;
                return true;
            } else {
                if (append_punctuation (uc))
                    return true;
                _output.append (child_node.entry.get_kana (kana_mode, false));
                _preedit.erase ();
                current_node = rule.root_node;
                preserve_preedit = false;
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
         * @param preedit_only only checks if preedit is active
         * @param no_carryover return false if there will be carryover
         * @return `true` if the character can be consumed
         */
        public bool can_consume (unichar uc,
                                 bool preedit_only = false,
                                 bool no_carryover = true)
        {
            if (preedit_only && _preedit.len == 0)
                return false;
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
            _output.erase ();
            _preedit.erase ();
            current_node = rule.root_node;
        }

        /**
         * Delete the trailing character from the internal buffer.
         *
         * @return `true` if any character is removed, `false` otherwise
         */
        public bool delete () {
            if (_preedit.len > 0) {
                current_node = current_node.parent;
                if (current_node == null)
                    current_node = rule.root_node;
                _preedit.truncate (
                    _preedit.str.index_of_nth_char (
                        _preedit.str.char_count () - 1));
                return true;
            }
            if (_output.len > 0) {
                _output.truncate (
                    _output.str.index_of_nth_char (
                        _output.str.char_count () - 1));
                return true;
            }
            return false;
        }
    }
}
