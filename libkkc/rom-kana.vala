// -*- coding: utf-8 -*-
/*
 * Copyright (C) 2011-2012 Daiki Ueno <ueno@unixuser.org>
 * Copyright (C) 2011-2012 Red Hat, Inc.
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

        // we can't simply use string kana[3] here because array
        // initializer in Vala does not support it
        string hiragana;
        string katakana;
        string hankaku_katakana;

        internal string get_kana (KanaMode kana_mode) {
            if (kana_mode == KanaMode.HIRAGANA)
                return hiragana;
            else if (kana_mode == KanaMode.KATAKANA)
                return katakana;
            else if (kana_mode == KanaMode.HANKAKU_KATAKANA)
                return hankaku_katakana;
            return "";
        }
    }

    static const string[] PERIOD_RULE = {"。、", "．，", "。，", "．、"};

    class RomKanaNode : Object {
        internal RomKanaEntry? entry;
        internal weak RomKanaNode parent;
        internal RomKanaNode children[128];
        internal char c;
        internal uint n_children = 0;
        internal bool valid[128];

        internal RomKanaNode (RomKanaEntry? entry) {
            this.entry = entry;
            for (int i = 0; i < children.length; i++) {
                children[i] = null;
            }
        }

        internal void insert (string key, RomKanaEntry entry) {
            var node = this;
            for (var i = 0; i < key.length; i++) {
                if (node.children[key[i]] == null) {
                    var child = node.children[key[i]] = new RomKanaNode (null);
                    child.parent = node;
                }
                node.n_children++;
                node = node.children[key[i]];
                valid[key[i]] = true;
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
        HANKAKU_KATAKANA
    }

    /**
     * Type to specify how "." and "," are converted.
     */
    public enum PeriodStyle {
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

        public KanaMode kana_mode { get; set; default = KanaMode.HIRAGANA; }
        public PeriodStyle period_style { get; set; default = PeriodStyle.JA_JA; }

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

        static const string[] NN = { "ん", "ン", "ﾝ" };

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
            if (uc > 128)
                return false;
            return _rule.root_node.valid[(int)uc];
        }

        /**
         * Output "nn" if preedit ends with "n".
         */
        public bool output_nn_if_any () {
            if (_preedit.str == "n") {
                _output.append (NN[kana_mode]);
                _preedit.erase ();
                current_node = rule.root_node;
                return true;
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
                var retval = output_nn_if_any ();
                // XXX: index_of_char does not work with '\0'
                var index = uc != '\0' ? ".,".index_of_char (uc) : -1;
                if (index >= 0) {
                    index = PERIOD_RULE[period_style].index_of_nth_char (index);
                    unichar period = PERIOD_RULE[period_style].get_char (index);
                    _output.append_unichar (period);
                    _preedit.erase ();
                    current_node = rule.root_node;
                    return true;
                } else if (rule.root_node.children[uc] == null) {
                    _output.append_unichar (uc);
                    _preedit.erase ();
                    current_node = rule.root_node;
                    // there may be "NN" output
                    return retval;
                } else {
                    // abandon current preedit and restart lookup from
                    // the root with uc
                    _preedit.erase ();
                    current_node = rule.root_node;
                    return append (uc);
                }
            } else if (child_node.n_children > 0) {
                // node is not a terminal
                _preedit.append_unichar (uc);
                current_node = child_node;
                return true;
            } else {
                _output.append (child_node.entry.get_kana (kana_mode));
                _preedit.erase ();
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
