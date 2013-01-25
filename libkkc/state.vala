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
        internal Gee.List<Dictionary> dictionaries;

        internal RomKanaConverter rom_kana_converter;
        internal StringBuilder input_buffer = new StringBuilder ();
        internal string input {
            owned get {
                return input_buffer.str + rom_kana_converter.preedit;
            }
        }

        internal StringBuilder output = new StringBuilder ();

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

        internal State (Decoder decoder, Gee.List<Dictionary> dictionaries) {
            this.decoder = decoder;
            this.dictionaries = dictionaries;
            this.segments = new SegmentList ();
            this.segments.notify["cursor-pos"].connect (
                segments_cursor_pos_changed);
            this.candidates = new SimpleCandidateList ();
            this.candidates.round = true;
            this.candidates.notify["cursor-pos"].connect (
                candidates_cursor_pos_changed);
            this.candidates.selected.connect (
                candidates_selected);

            rom_kana_converter = new RomKanaConverter ();

            try {
                _typing_rule = new Rule ("default");
            } catch (RuleParseError e) {
                assert_not_reached ();
            }

            reset ();
        }

        ~State () {
            reset ();
        }

        void segments_cursor_pos_changed (Object s, ParamSpec? p) {
            if (segments.cursor_pos >= 0) {
                lookup (segments[segments.cursor_pos]);
            }
        }

        void candidates_cursor_pos_changed (Object s, ParamSpec? p) {
            if (segments.cursor_pos >= 0 && candidates.cursor_pos >= 0) {
                var candidate = candidates.get (candidates.cursor_pos);
                segments[segments.cursor_pos].output = candidate.output;
            }
        }

        void candidates_selected (Candidate candidate) {
            if (segments.cursor_pos >= 0 && candidates.cursor_pos >= 0) {
                Candidate[] _candidates = {};

                _candidates += candidates.get (candidates.cursor_pos);
                save_candidates (_candidates);
            }
            candidates.clear ();
        }

        void save_candidates (Candidate[] _candidates) {
            foreach (var dict in dictionaries) {
                var _dict = dict as SegmentDictionary;
                if (_dict == null || _dict.read_only)
                    continue;

                foreach (var candidate in _candidates) {
                    _dict.select_candidate (candidate);
                }

                try {
                    _dict.save ();
                } catch (Error e) {
                    warning ("couldn't save candidate into dictionary: %s",
                             e.message);
                }
            }
        }

        internal void select_sentence () {
            string[] sequence = new string[segments.size];
            for (var i = 0; i < sequence.length; i++) {
                sequence[i] = segments[i].input;
            }
            var prefixes = SequenceUtils.enumerate_prefixes (
                sequence,
                4,
                5);

            foreach (var dict in dictionaries) {
                var _dict = dict as SentenceDictionary;
                if (_dict == null || _dict.read_only)
                    continue;

                foreach (var prefix in prefixes) {
                    var _segments = segments.to_array ();
                    var stop = prefix.offset + prefix.sequence.length;
                    _segments = _segments[prefix.offset:stop];
                    _dict.select_segments (_segments);
                }

                try {
                    _dict.save ();
                } catch (Error e) {
                    warning ("couldn't save sentence into dictionary: %s",
                             e.message);
                }
            }
        }

        internal void reset () {
            // output and input_mode won't change
            handler_type = typeof (InitialStateHandler);
            rom_kana_converter.reset ();
            _typing_rule.get_filter ().reset ();
            segments.clear ();
            candidates.clear ();
            input_buffer.erase ();
        }

        internal void lookup (Segment segment) {
            candidates.clear ();

            lookup_internal (new SimpleTemplate (segment.input));
            lookup_internal (new OkuriganaTemplate (segment.input));
            lookup_internal (new NumericTemplate (segment.input));

            var hiragana = new Candidate (
                segment.input,
                false,
                segment.input);
            candidates.add_candidates (new Candidate[] { hiragana });

            var katakana = new Candidate (
                segment.input,
                false,
                RomKanaUtils.get_katakana (segment.input));
            candidates.add_candidates (new Candidate[] { katakana });

            var original = new Candidate (
                segment.input,
                false,
                segment.output);
            candidates.add_candidates (new Candidate[] { original });

            candidates.add_candidates_end ();
        }

        void lookup_internal (Template template) {
            foreach (var dict in dictionaries) {
                var _dict = dict as SegmentDictionary;
                if (_dict == null)
                    continue;
                var _candidates = _dict.lookup (template.source,
                                                template.okuri);
                foreach (var candidate in _candidates) {
                    string text;
                    text = Expression.eval (candidate.text);
                    text = template.expand (text);
                    candidate.output = text;
                    // annotation may be an expression
                    if (candidate.annotation != null) {
                        candidate.annotation = Expression.eval (
                            candidate.annotation);
                    }
                }
                candidates.add_candidates (_candidates);
            }
        }

        internal void convert_sentence (string input,
                                        int[]? constraints = null)
        {
            var _segments = decoder.decode (input,
                                            1,
                                            constraints ?? new int[0]);
            segments.set_segments (_segments[0]);

            if (constraints == null) {
                apply_constraints ();
            }

            apply_phrase ();
        }

        SentenceDictionary? find_setence_dictionary (bool writable) {
            foreach (var dict in dictionaries) {
                var sentence_dict = dict as SentenceDictionary;
                if (sentence_dict != null
                    && (!writable || !sentence_dict.read_only))
                    return sentence_dict;
            }
            return null;
        }

        void apply_constraints () {
            var sentence_dict = find_setence_dictionary (false);
            var sequence = Utils.split_utf8 (input);
            var prefixes = SequenceUtils.enumerate_prefixes (
                sequence,
                4,
                sequence.length);
            var offset = 0;
            var constraints = new ArrayList<int> ();
            foreach (var prefix in prefixes) {
                if (prefix.offset < offset)
                    continue;
                int[] _constraints;
                var input = string.joinv ("", prefix.sequence);
                if (sentence_dict.lookup_constraints (input,
                                                      out _constraints)) {
                    assert (_constraints.length > 0);
                    var _offset = 0;
                    for (var i = 0; i < segments.size; i++) {
                        _offset += segments[i].input.char_count ();
                        if (offset < _offset
                            && _offset < _constraints[0] + prefix.offset) {
                            constraints.add (_offset);
                        }
                    }

                    for (var i = 0; i < _constraints.length; i++) {
                        constraints.add (_constraints[i] + prefix.offset);
                    }
                    offset = constraints.get (constraints.size - 1);
                }
            }
            var _segments = decoder.decode (input,
                                            1,
                                            constraints.to_array ());
            segments.set_segments (_segments[0]);
        }

        void apply_phrase () {
            var sentence_dict = find_setence_dictionary (false);
            string[] sequence = new string[segments.size];
            for (var i = 0; i < segments.size; i++) {
                sequence[i] = segments[i].input;
            }
            var prefixes = SequenceUtils.enumerate_prefixes (
                sequence,
                4,
                5);
            var offset = 0;
            foreach (var prefix in prefixes) {
                if (prefix.offset < offset)
                    continue;
                string[] _value;
                if (sentence_dict.lookup_phrase (prefix.sequence,
                                         out _value)) {
                    for (var i = 0; i < _value.length; i++) {
                        segments[prefix.offset + i].output = _value[i];
                    }
                    offset += _value.length;
                }
            }
        }

        internal void resize_segment (int amount) {
            if (segments.cursor_pos >= 0
                && segments.cursor_pos < segments.size) {
                int[] constraints = {};
                int offset = 0;
                for (var i = 0; i < segments.size; i++) {
                    int segment_size = segments[i].input.char_count ();
                    if (i == segments.cursor_pos)
                        segment_size += amount;
                    offset += segment_size;
                    constraints += offset;
                    if (i == segments.cursor_pos)
                        break;
                }
                select_sentence ();
                int cursor_pos = segments.cursor_pos;
                convert_sentence (segments.get_input (), constraints);
                segments.cursor_pos = cursor_pos;
                apply_phrase ();
            }
        }
    }

    delegate bool CommandHandler (State state);

    abstract class StateHandler : Object {
        internal abstract bool process_key_event (State state, ref KeyEvent key);
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

    class InitialStateHandler : StateHandler {
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
                bool retval = state.input_buffer.len > 0 ||
                    state.rom_kana_converter.preedit.length > 0;
                state.reset ();
                return retval;
            } else if (command == "commit") {
                bool retval = state.input_buffer.len > 0 ||
                    state.rom_kana_converter.preedit.length > 0;
                state.rom_kana_converter.output_nn_if_any ();
                state.output.append (state.input_buffer.str);
                state.output.append (state.rom_kana_converter.output);
                state.reset ();
                return retval;
            }
            else if (command == "next-candidate") {
                if (state.input_buffer.len == 0)
                    return false;
                if (state.segments.size == 0) {
                    string input = RomKanaUtils.get_hiragana (
                        state.input_buffer.str);
                    state.convert_sentence (input);
                    state.segments.first_segment ();
                    state.handler_type = typeof (ConvertSentenceStateHandler);
                    return true;
                }
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
                if (state.input_buffer.len > 0) {
                    state.input_buffer.truncate (
                        state.input_buffer.str.index_of_nth_char (
                            state.input_buffer.str.char_count () - 1));
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
                    state.input_buffer.append (state.rom_kana_converter.output);
                    state.rom_kana_converter.output = "";
                    state.handler_type = typeof (ConvertSentenceStateHandler);
                    return false;
                }
                if (command != null && command.has_prefix ("insert-kana-")) {
                    var kana = RomKanaUtils.convert_by_input_mode (
                        command["insert-kana-".length:command.length],
                        state.input_mode);
                    state.input_buffer.append (kana);
                    return true;
                }
                if (key.modifiers == 0 ||
                    key.modifiers == Kkc.ModifierType.SHIFT_MASK) {
                    bool retval = false;
                    if (state.rom_kana_converter.append (key.code)) {
                        state.input_buffer.append (
                            state.rom_kana_converter.output);
                        state.rom_kana_converter.output = "";
                        retval = true;
                    }
                    else if (0x20 <= key.code && key.code <= 0x7F) {
                        state.input_buffer.append_c ((char) key.code);
                        state.rom_kana_converter.output = "";
                        retval = true;
                    }
                    else {
                        state.rom_kana_converter.output = "";
                        retval = false;
                    }
                    return retval;
                }
                break;
            case InputMode.LATIN:
                if (key.modifiers == 0 &&
                    key.modifiers == Kkc.ModifierType.SHIFT_MASK &&
                    0x20 <= key.code && key.code <= 0x7F) {
                    state.input_buffer.append_c ((char) key.code);
                    return true;
                }
                break;
            case InputMode.WIDE_LATIN:
                if (key.modifiers == 0 &&
                    key.modifiers == Kkc.ModifierType.SHIFT_MASK &&
                    0x20 <= key.code && key.code <= 0x7F) {
                    state.input_buffer.append_unichar (
                        RomKanaUtils.get_wide_latin_char ((char) key.code));
                    return true;
                }
                break;
            }
            return false;
        }
    }

    class ConvertSentenceStateHandler : StateHandler {
        static const InputModeCommandEntry[] end_preedit_commands = {
            { "set-input-mode-hiragana", InputMode.HIRAGANA },
            { "set-input-mode-katakana", InputMode.KATAKANA },
            { "set-input-mode-hankaku-katakana", InputMode.HANKAKU_KATAKANA }
        };

        internal override bool process_key_event (State state,
                                                  ref KeyEvent key)
        {
            var command = state.lookup_key (key);
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

            if (command == "next-candidate"
                || command == "previous-candidate") {
                state.handler_type = typeof (ConvertSegmentStateHandler);
                state.candidates.first ();
                return true;
            }
            if (command != null && command.has_prefix ("insert-kana-")) {
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
            else if (command == "abort" || command == "delete") {
                state.segments.clear ();
                state.handler_type = typeof (InitialStateHandler);
                return true;
            }
            else {
                state.output.append (state.segments.get_output ());
                state.select_sentence ();
                state.reset ();
                return command != null;
            }
        }
    }

    class ConvertSegmentStateHandler : StateHandler {
        internal override bool process_key_event (State state,
                                                  ref KeyEvent key)
        {
            var command = state.lookup_key (key);
            if (command == "previous-candidate") {
                state.candidates.previous ();
                return true;
            }
            else if (command == "next-candidate") {
                state.candidates.next ();
                return true;
            }
            else if (command == "abort") {
                state.candidates.clear ();
                state.handler_type = typeof (ConvertSentenceStateHandler);
                return true;
            }
            else if (command == "next-segment") {
                if (state.candidates.cursor_pos >= 0)
                    state.candidates.select ();
                state.handler_type = typeof (ConvertSentenceStateHandler);
                return false;
            }
            else if (command == "previous-segment") {
                if (state.candidates.cursor_pos >= 0)
                    state.candidates.select ();
                state.handler_type = typeof (ConvertSentenceStateHandler);
                return false;
            }
            else if (command == "delete") {
                state.candidates.clear ();
                state.handler_type = typeof (ConvertSentenceStateHandler);
                return false;
            }
            else {
                if (state.candidates.cursor_pos >= 0)
                    state.candidates.select ();
                state.handler_type = typeof (ConvertSentenceStateHandler);
                return false;
            }
        }
    }
}
