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

    /**
     * Object representing a minimal unit of a transliterated character.
     */
    public struct RomKanaCharacter {
        string output;
        string input;
    }

    /**
     * A list of RomKanaCharacter
     */
    public class RomKanaCharacterList : Object {
        Gee.List<RomKanaCharacter?> _characters = new ArrayList<RomKanaCharacter?> ();

        /**
         * The number of characters in the character list.
         */
        public int size {
            get {
                return _characters.size;
            }
        }

        /**
         * Append a character to the character list.
         *
         * @param character a RomKanaCharacter
         */
        public void add (RomKanaCharacter character) {
            _characters.add (character);
        }

        /**
         * Append all characters in other character list to the character list.
         *
         * @param other RomKanaCharacterList
         */
        public void add_all (RomKanaCharacterList other) {
            _characters.add_all (other._characters);
        }

        /**
         * Add a character to the character list at the specified
         * position.
         *
         * @param index index
         * @param character RomKanaCharacter
         */
        public void insert (int index, RomKanaCharacter character) {
            _characters.insert (index, character);
        }

        /**
         * Add all characters in other character list to the character
         * list at the specified position.
         *
         * @param index index
         * @param other RomKanaCharacterList
         */
        public void insert_all (int index, RomKanaCharacterList other) {
            _characters.insert_all (index, other._characters);
        }

        /**
         * Get a character at the given index.
         *
         * @param index index
         *
         * @return a RomKanaCharacter
         */
        public new RomKanaCharacter @get (int index) {
            return _characters.get (index);
        }

        /**
         * Remove all characters from the character list.
         */
        public void clear () {
            _characters.clear ();
        }

        /**
         * Return a slice of this character list.
         *
         * @param start_char_pos zero-based index of the begin of the slice
         * @param stop_char_pos zero-based index after the end of the slice
         *
         * @return a RomKanaCharacterList
         */
        public RomKanaCharacterList slice (int start_char_pos,
                                           int stop_char_pos)
        {
            int start, stop, char_pos = 0;
            for (start = 0; start < _characters.size; start++) {
                if (char_pos >= start_char_pos)
                    break;
                char_pos += _characters[start].output.char_count ();
            }
            for (stop = start; stop < _characters.size; stop++) {
                char_pos += _characters[stop].output.char_count ();
                if (char_pos >= stop_char_pos)
                    break;
            }

            var result = new RomKanaCharacterList ();
            for (; start <= stop; start++) {
                result.add (_characters[start]);
            }
            return result;
        }

        /**
         * Remove a character at the given index.
         *
         * @param index index
         */
        public void remove_at (int index) {
            _characters.remove_at (index);
        }

        /**
         * Return the concatenation of all character output as a string.
         *
         * @return a string
         */
        public string get_output () {
            var builder = new StringBuilder ();
            foreach (var character in _characters) {
                builder.append (character.output);
            }
            return builder.str;
        }

        /**
         * Return the concatenation of all character input as a string.
         *
         * @return a string
         */
        public string get_input () {
            var builder = new StringBuilder ();
            foreach (var character in _characters) {
                builder.append (character.input);
            }
            return builder.str;
        }
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

        /**
         * The current kana mode.
         */
        public KanaMode kana_mode { get; set; default = KanaMode.HIRAGANA; }

        /**
         * The current punctuation style.
         */
        public PunctuationStyle punctuation_style { get; set; default = PunctuationStyle.JA_JA; }

        /**
         * The current auto correct flag.
         */
        public bool auto_correct { get; set; default = true; }

        StringBuilder _pending_output = new StringBuilder ();
        /**
         * The output being processed.
         */
        public string pending_output {
            get {
                return _pending_output.str;
            }
        }

        StringBuilder _pending_input = new StringBuilder ();
        /**
         * The input being processed.
         */
        public string pending_input {
            get {
                return _pending_input.str;
            }
        }

        RomKanaCharacterList _produced = new RomKanaCharacterList ();
        /**
         * A list of already processed characters.
         */
        public RomKanaCharacterList produced {
            get {
                return _produced;
            }
        }

        /**
         * Return the concatenation of the produced output characters.
         *
         * @return a string
         */
        public string get_produced_output () {
            var builder = new StringBuilder ();
            foreach (var c in _produced) {
                builder.append (c.output);
            }
            return builder.str;
        }

        /**
         * Create a new RomKanaConverter.
         *
         * @return a new RomKanaConverter
         */
        public RomKanaConverter () {
            try {
                _rule = new RomKanaMapFile (RuleMetadata.find ("default"));
                current_node = _rule.root_node;
            } catch (RuleParseError e) {
                warning ("can't find default rom-kana rule: %s",
                         e.message);
                assert_not_reached ();
            }
        }

        /**
         * Check if a character is a valid conversion input.
         *
         * @param uc unichar
         * @return `true` if uc is in a valid range, `false` otherwise
         */
        public bool is_valid (unichar uc) {
            if (uc > 256)
                return false;
            uint8 mask = (uint8) (1 << (uc % 8));
            return (current_node.valid[uc / 8] & mask) != 0 ||
                (_rule.root_node.valid[uc / 8] & mask) != 0;
        }

        /**
         * Finish pending input, if any.
         *
         * Note that this does not reset pending input/output and the
         * current node if there is no partial output.
         *
         * @return `true` if there is partial output, `false` otherwise
         */
        public bool flush_partial () {
            string output;
            if (current_node.entry != null &&
                (output = current_node.entry.get_kana (kana_mode, true)).length > 0) {
                _produced.add (RomKanaCharacter () {
                        output = output, input = _pending_input.str
                    });
                _pending_input.erase ();
                _pending_output.erase ();
                current_node = rule.root_node;
                return true;
            }

            if (!auto_correct && _pending_output.len > 0) {
                _produced.add (RomKanaCharacter () {
                        output = _pending_output.str, input = _pending_input.str
                        });
                _pending_input.erase ();
                _pending_output.erase ();
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
            // Directly produce characters under Latin Kana mode.
            if (kana_mode == KanaMode.LATIN ||
                kana_mode == KanaMode.WIDE_LATIN) {
                var input = uc.to_string ();
                var output = RomKanaUtils.convert_by_kana_mode (input,
                                                                kana_mode);
                _produced.add (RomKanaCharacter () {
                        output = output, input = input
                    });
                return true;
            }

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
                    _pending_input.erase ();
                    _pending_output.erase ();
                    current_node = rule.root_node;
                    return append (uc);
                } else if (auto_correct) {
                    // Abandon the pending input and restart lookup
                    // from the root with uc.
                    _pending_input.erase ();
                    _pending_output.erase ();
                    current_node = rule.root_node;
                    return append (uc);
                } else {
                    _produced.add (RomKanaCharacter () {
                            output = _pending_output.str,
                            input = _pending_input.str
                        });
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
                _pending_input.append_unichar (uc);
                _produced.add (RomKanaCharacter () {
                        output = child_node.entry.get_kana (kana_mode, false),
                        input = _pending_input.str
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
            _produced.clear ();
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
