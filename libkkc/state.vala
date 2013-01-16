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
    static const string[] AUTO_START_HENKAN_KEYWORDS = {
        "を", "、", "。", "．", "，", "？", "」",
        "！", "；", "：", ")", ";", ":", "）",
        "”", "】", "』", "》", "〉", "｝", "］",
        "〕", "}", "]", "?", ".", ",", "!"
    };

    class State : Object {
        internal Type handler_type;
        InputMode _input_mode;
        [CCode(notify = false)]
        internal InputMode input_mode {
            get {
                return _input_mode;
            }
            set {
                output.append (rom_kana_converter.output);
                var last_input_mode = _input_mode;
                reset ();
                _input_mode = value;
                switch (_input_mode) {
                case InputMode.HIRAGANA:
                case InputMode.KATAKANA:
                case InputMode.HANKAKU_KATAKANA:
                    rom_kana_converter.kana_mode = (KanaMode) value;
                    break;
                default:
                    break;
                }
                if (_input_mode != last_input_mode) {
                    notify_property ("input-mode");
                }
            }
        }

        internal Decoder decoder;
        internal SegmentList segments;
        internal CandidateList candidates;
        internal Gee.List<Dict> dictionaries;

        internal RomKanaConverter rom_kana_converter;

        internal StringBuilder output = new StringBuilder ();
        internal StringBuilder preedit = new StringBuilder ();

        internal string[] auto_start_henkan_keywords;
        internal string? auto_start_henkan_keyword = null;

        internal PeriodStyle period_style {
            get {
                return rom_kana_converter.period_style;
            }
            set {
                rom_kana_converter.period_style = value;
            }
        }

        Rule _typing_rule;
        internal Rule typing_rule {
            get {
                return _typing_rule;
            }
            set {
                _typing_rule = value;
                rom_kana_converter.rule = _typing_rule.rom_kana;
            }
        }

        internal string? lookup_key (KeyEvent key) {
            var keymap = _typing_rule.keymaps[input_mode].keymap;
            return_val_if_fail (keymap != null, null);
            return keymap.lookup_key (key);
        }

        internal KeyEvent? where_is (string command) {
            var keymap = _typing_rule.keymaps[input_mode].keymap;
            return_val_if_fail (keymap != null, null);
            return keymap.where_is (command);
        }

        internal bool isupper (KeyEvent key, out unichar lower_code) {
            var command = lookup_key (key);
            if (command != null && command.has_prefix ("upper-")) {
                lower_code = (unichar) command[6];
                return true;
            } else if (key.code.isupper()) {
                lower_code = key.code.tolower();
                return true;
            }
            lower_code = key.code;
            return false;
        }

        Regex numeric_regex;
        Regex numeric_ref_regex;

        internal State (Decoder decoder, Gee.List<Dict> dictionaries) {
            this.decoder = decoder;
            this.dictionaries = dictionaries;
            this.segments = new SegmentList ();
            this.candidates = new SimpleCandidateList ();
            this.candidates.selected.connect (candidate_selected);

            rom_kana_converter = new RomKanaConverter ();
            auto_start_henkan_keywords = AUTO_START_HENKAN_KEYWORDS;

            try {
                _typing_rule = new Rule ("default");
            } catch (RuleParseError e) {
                assert_not_reached ();
            }

            try {
                numeric_regex = new Regex ("[0-9]+");
            } catch (GLib.RegexError e) {
                assert_not_reached ();
            }

            try {
                numeric_ref_regex = new Regex ("#([0-9])");
            } catch (GLib.RegexError e) {
                assert_not_reached ();
            }

            reset ();
        }

        ~State () {
            reset ();
        }

        void candidate_selected (Candidate c) {
            output.append (c.output);
            if (auto_start_henkan_keyword != null) {
                output.append (auto_start_henkan_keyword);
            }
            var _mode = input_mode;
            reset ();
            _input_mode = _mode;
        }

        internal void reset () {
            // output and input_mode won't change
            handler_type = typeof (NoneStateHandler);
            rom_kana_converter.reset ();
            _typing_rule.get_filter ().reset ();
            segments.clear ();
            candidates.clear ();
            preedit.erase ();
            auto_start_henkan_keyword = null;
        }

        string extract_numerics (string midasi, out int[] numerics) {
            MatchInfo info = null;
            int start_pos = 0;
            var numeric_list = new ArrayList<int> ();
            var builder = new StringBuilder ();
            while (true) {
                try {
                    if (!numeric_regex.match_full (midasi,
                                                   -1,
                                                   start_pos,
                                                   0,
                                                   out info)) {
                        break;
                    }
                } catch (GLib.RegexError e) {
                    return_val_if_reached (midasi);
                }

                string numeric = info.fetch (0);
                int match_start_pos, match_end_pos;
                info.fetch_pos (0,
                                out match_start_pos,
                                out match_end_pos);
                numeric_list.add (int.parse (numeric));
                builder.append (midasi[start_pos:match_start_pos]);
                builder.append ("#");
                start_pos = match_end_pos;
            }
            numerics = numeric_list.to_array ();
            builder.append (midasi[start_pos:midasi.length]);
            return builder.str;
        }

        string expand_expr (string text) {
            if (text.has_prefix ("(")) {
                var reader = new ExprReader ();
                int index = 0;
                var node = reader.read_expr (text, ref index);
                var evaluator = new ExprEvaluator ();
                var _text = evaluator.eval (node);
                if (_text != null) {
                    return _text;
                }
            }
            return text;
        }

        string expand_numeric_references (string text, int[] numerics) {
            var builder = new StringBuilder ();
            MatchInfo info = null;
            int start_pos = 0;
            for (int numeric_index = 0;
                 numeric_index < numerics.length;
                 numeric_index++)
            {
                try {
                    if (!numeric_ref_regex.match_full (text,
                                                       -1,
                                                       start_pos,
                                                       0,
                                                       out info)) {
                        break;
                    }
                } catch (GLib.RegexError e) {
                    return_val_if_reached (text);
                }
                            
                int match_start_pos, match_end_pos;
                info.fetch_pos (0,
                                out match_start_pos,
                                out match_end_pos);
                builder.append (text[start_pos:match_start_pos]);

                string type = info.fetch (1);
                switch (type[0]) {
                case '0':
                case '1':
                case '2':
                case '3':
                case '5':
                    builder.append (
                        RomKanaUtils.get_numeric (
                            numerics[numeric_index],
                            (NumericConversionType) (type[0] - '0')));
                    break;
                case '4':
                case '9':
                    // not supported yet
                    break;
                default:
                    warning ("unknown numeric conversion type: %s",
                             type);
                    break;
                }
                start_pos = match_end_pos;
            }
            builder.append (text[start_pos:text.length]);
            return builder.str;
        }

        internal void lookup (string midasi, bool okuri = false) {
            candidates.clear ();
            int[] numerics = new int[0];
            lookup_internal (midasi, numerics, okuri);
            var numeric_midasi = extract_numerics (midasi, out numerics);
            lookup_internal (numeric_midasi, numerics, okuri);
            candidates.add_candidates_end ();
        }

        void lookup_internal (string midasi,
                              int[] numerics,
                              bool okuri = false)
        {
            foreach (var dict in dictionaries) {
                var _candidates = dict.lookup (midasi, okuri);
                foreach (var candidate in _candidates) {
                    var text = candidate.text;
                    text = expand_expr (text);
                    text = expand_numeric_references (text, numerics);
                    candidate.output = text;
                    // annotation may be an expression
                    if (candidate.annotation != null) {
                        candidate.annotation = expand_expr (
                            candidate.annotation);
                    }
                }
                candidates.add_candidates (_candidates);
            }
        }

        internal void convert_sentence (string input,
                                        int[] constraints = new int[0])
        {
            var _segments = decoder.decode (input, 1, constraints);
            segments.clear ();
            segments.add_segments (_segments[0]);
        }

        internal void resize_segment (int amount) {
            if (segments.index >= 0 && segments.index < segments.size) {
                int[] constraints = {};
                int offset = 0;
                for (var i = 0; i < segments.size; i++) {
                    int segment_size = segments[i].input.char_count ();
                    if (i == segments.index)
                        segment_size += amount;
                    offset += segment_size;
                    constraints += offset;
                    if (i == segments.index)
                        break;
                }
                int index = segments.index;
                convert_sentence (segments.get_input (), constraints);
                segments.index = index;
            }
        }

        internal void purge_candidate (Candidate candidate) {
        }
    }

    delegate bool CommandHandler (State state);

    abstract class StateHandler : Object {
        internal abstract bool process_key_event (State state, ref KeyEvent key);
        internal abstract string get_preedit (State state,
                                              out uint underline_offset,
                                              out uint underline_nchars);
        internal virtual string get_output (State state) {
            return state.output.str;
        }
    }

    // We can't use Entry<*,InputMode> here because of Vala bug:
    // https://bugzilla.gnome.org/show_bug.cgi?id=684262
    struct InputModeCommandEntry {
        string key;
        InputMode value;
    }

    class NoneStateHandler : StateHandler {
        static const InputModeCommandEntry[] input_mode_commands = {
            { "set-input-mode-hiragana", InputMode.HIRAGANA },
            { "set-input-mode-katakana", InputMode.KATAKANA },
            { "set-input-mode-hankaku-katakana", InputMode.HANKAKU_KATAKANA },
            { "set-input-mode-latin", InputMode.LATIN },
            { "set-input-mode-wide-latin", InputMode.WIDE_LATIN }
        };

        internal override bool process_key_event (State state,
                                                  ref KeyEvent key)
        {
            var command = state.lookup_key (key);
            // check abort and commit event
            if (command == "abort") {
                bool retval = state.preedit.len > 0 ||
                    state.rom_kana_converter.preedit.length > 0;
                state.reset ();
                return retval;
            } else if (command == "commit") {
                bool retval = state.preedit.len > 0 ||
                    state.rom_kana_converter.preedit.length > 0;
                state.rom_kana_converter.output_nn_if_any ();
                state.output.append (state.preedit.str);
                state.output.append (state.rom_kana_converter.output);
                state.reset ();
                return retval;
            }
            // check mode switch events
            if (command != null && command.has_prefix ("set-input-mode-") &&
                !((state.input_mode == InputMode.HIRAGANA ||
                   state.input_mode == InputMode.KATAKANA ||
                   state.input_mode == InputMode.HANKAKU_KATAKANA) &&
                  key.modifiers == 0 &&
                  state.rom_kana_converter.can_consume (key.code))) {
                foreach (var entry in input_mode_commands) {
                    if (entry.key == command) {
                        state.rom_kana_converter.output_nn_if_any ();
                        state.input_mode = entry.value;
                        return true;
                    }
                }
            }

            // check editing events
            if (command == "delete") {
                if (state.rom_kana_converter.delete ()) {
                    return true;
                }
                if (state.preedit.len > 0) {
                    state.preedit.truncate (
                        state.preedit.str.index_of_nth_char (
                            state.preedit.str.char_count () - 1));
                    return true;
                }
                return false;
            }

            switch (state.input_mode) {
            case InputMode.HIRAGANA:
            case InputMode.KATAKANA:
            case InputMode.HANKAKU_KATAKANA:
                if (command == "next-candidate") {
                    state.rom_kana_converter.output_nn_if_any ();
                    state.preedit.append (state.rom_kana_converter.output);
                    state.rom_kana_converter.output = "";
                    state.handler_type = typeof (StartStateHandler);
                    return false;
                }
                if (command != null && command.has_prefix ("insert-kana-")) {
                    var kana = RomKanaUtils.convert_by_input_mode (
                        command["insert-kana-".length:command.length],
                        state.input_mode);
                    state.preedit.append (kana);
                    return true;
                }
                if (key.modifiers == 0) {
                    bool retval = false;
                    if (state.rom_kana_converter.append (key.code)) {
                        state.preedit.append (state.rom_kana_converter.output);
                        state.rom_kana_converter.output = "";
                        retval = true;
                    }
                    else if (0x20 <= key.code && key.code <= 0x7F) {
                        state.preedit.append_c ((char) key.code);
                        state.rom_kana_converter.output = "";
                        retval = true;
                    }
                    else {
                        state.rom_kana_converter.output = "";
                        retval = false;
                    }
                    if (retval) {
                        return check_auto_conversion (state, ref key);
                    }
                    return retval;
                }
                break;
            case InputMode.LATIN:
                if (key.modifiers == 0 &&
                    0x20 <= key.code && key.code <= 0x7F) {
                    state.preedit.append_c ((char) key.code);
                    return true;
                }
                break;
            case InputMode.WIDE_LATIN:
                if (key.modifiers == 0 &&
                    0x20 <= key.code && key.code <= 0x7F) {
                    state.preedit.append_unichar (
                        RomKanaUtils.get_wide_latin_char ((char) key.code));
                    return true;
                }
                break;
            }
            return false;
        }

        internal override string get_preedit (State state,
                                              out uint underline_offset,
                                              out uint underline_nchars)
        {
            var builder = new StringBuilder ();
            builder.append (state.preedit.str);
            builder.append (state.rom_kana_converter.preedit);
            underline_offset = 0;
            underline_nchars = 0;
            return builder.str;
        }

        bool check_auto_conversion (State state, ref KeyEvent key) {
            foreach (var keyword in state.auto_start_henkan_keywords) {
                if (state.preedit.len > keyword.length &&
                    state.preedit.str.has_suffix (keyword)) {
                    state.auto_start_henkan_keyword = keyword;
                    state.handler_type = typeof (StartStateHandler);
                    key = state.where_is ("next-candidate");
                    return false;
                }
            }
            return true;
        }
    }

    class StartStateHandler : StateHandler {
        static const InputModeCommandEntry[] end_preedit_commands = {
            { "set-input-mode-hiragana", InputMode.HIRAGANA },
            { "set-input-mode-katakana", InputMode.KATAKANA },
            { "set-input-mode-hankaku-katakana", InputMode.HANKAKU_KATAKANA }
        };

        internal override bool process_key_event (State state,
                                                  ref KeyEvent key)
        {
            var command = state.lookup_key (key);
            if (command == "abort") {
                state.reset ();
                return true;
            }

            foreach (var entry in end_preedit_commands) {
                if (entry.key == command) {
                    state.rom_kana_converter.output_nn_if_any ();
                    state.output.assign (
                        RomKanaUtils.convert_by_input_mode (
                            state.rom_kana_converter.output,
                            entry.value));
                    state.rom_kana_converter.reset ();
                    return true;
                }
            }

            if (command == "next-candidate") {
                if (state.segments.size == 0) {
                    string input = RomKanaUtils.get_hiragana (
                        state.preedit.str);
                    state.convert_sentence (input);
                    return true;
                }
                state.handler_type = typeof (SelectStateHandler);
                return false;
            }
            else if (command == "delete") {
                state.reset ();
                return true;
            }
            else if (command != null && command.has_prefix ("insert-kana-")) {
                var kana = RomKanaUtils.convert_by_input_mode (
                    command["insert-kana-".length:command.length],
                    state.input_mode);
                state.rom_kana_converter.output = kana;
                return true;
            }
            else if (command == "expand-segment") {
                state.resize_segment (1);
                return true;
            }
            else if (command == "shrink-segment") {
                state.resize_segment (-1);
                return true;
            }
            else if (command == "next-segment") {
                state.segments.next_segment ();
                return true;
            }
            else if (command == "previous-segment") {
                state.segments.previous_segment ();
                return true;
            }
            else {
                uint underline_offset, underline_nchars;
                state.output.append (get_preedit (state,
                                                  out underline_offset,
                                                  out underline_nchars));
                state.reset ();
                return true;
            }
        }

        internal override string get_preedit (State state,
                                              out uint underline_offset,
                                              out uint underline_nchars) {
            var preedit = state.segments.to_string ();
            Segment segment;
            uint offset = 0;
            for (var i = 0; i < state.segments.index; i++) {
                segment = state.segments[i];
                offset += segment.output.char_count ();
            }
            segment = state.segments[state.segments.index];
            underline_offset = offset;
            underline_nchars = segment.output.char_count ();
            return preedit;
        }
    }

    class SelectStateHandler : StateHandler {
        internal override bool process_key_event (State state,
                                                  ref KeyEvent key)
        {
            var command = state.lookup_key (key);
            if (command == "previous-candidate") {
                if (!state.candidates.previous ()) {
                    state.candidates.clear ();
                    state.handler_type = typeof (StartStateHandler);
                }
                return true;
            }
            else if (command == "purge-candidate") {
                var candidate = state.candidates.get ();
                state.purge_candidate (candidate);
                state.reset ();
                return true;
            }
            else if (command == "next-candidate") {
                if (state.candidates.cursor_pos < 0) {
                    string midasi = state.segments[state.segments.index].input;
                    state.lookup (midasi);
                    if (state.candidates.size > 0) {
                        return true;
                    }
                }
                return true;
            }
            else if (command == "abort") {
                state.candidates.clear ();
                state.handler_type = typeof (StartStateHandler);
                return true;
            }
            else {
                state.candidates.select ();
                var candidate = state.candidates.get ();
                state.segments[state.segments.index].output = candidate.output;
                state.reset ();
                if ((key.modifiers == 0 &&
                     0x20 <= key.code && key.code <= 0x7E) ||
                    command == "delete") {
                    return false;
                }
                else {
                    // mark any other key events are consumed here
                    return true;
                }
            }
        }

        internal override string get_preedit (State state,
                                              out uint underline_offset,
                                              out uint underline_nchars) {
            StringBuilder builder = new StringBuilder ();
            underline_offset = 0;
            underline_nchars = 0;
            for (var i = 0; i < state.segments.size; i++) {
                if (i == state.segments.index) {
                    var text = state.candidates.get ().text;
                    underline_offset = builder.str.char_count ();
                    underline_nchars = text.char_count ();
                    builder.append (text);
                } else
                    builder.append (state.segments[i].output);
            }
            return builder.str;
        }
    }
}
