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
        bool segments_changed = false;
        internal CandidateList candidates;
        internal DictionaryList dictionaries;

        internal RomKanaConverter rom_kana_converter;
        internal StringBuilder input_buffer = new StringBuilder ();
        internal string input {
            owned get {
                return input_buffer.str + rom_kana_converter.preedit;
            }
        }
        internal StringBuilder selection = new StringBuilder ();
        internal StringBuilder output = new StringBuilder ();
        internal bool quoted = false;

        ArrayList<string> completion = new ArrayList<string> ();
        internal Iterator<string> completion_iterator;

        internal PunctuationStyle punctuation_style {
            get {
                return rom_kana_converter.punctuation_style;
            }
            set {
                rom_kana_converter.punctuation_style = value;
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

        internal State (Decoder decoder, DictionaryList dictionaries) {
            this.decoder = decoder;
            this.dictionaries = dictionaries;
            this.segments = new SegmentList ();
            this.candidates = new CandidateList ();
            this.candidates.round = true;
            this.candidates.notify["cursor-pos"].connect (
                candidates_cursor_pos_changed);
            this.candidates.selected.connect (
                candidates_selected);

            rom_kana_converter = new RomKanaConverter ();

            try {
                _typing_rule = new Rule ("default");
            } catch (RuleParseError e) {
                warning ("cannot load default rule: %s",
                         e.message);
                assert_not_reached ();
            }

            reset ();
        }

        ~State () {
            reset ();
        }

        void candidates_cursor_pos_changed (Object s, ParamSpec? p) {
            if (segments.cursor_pos >= 0 && candidates.cursor_pos >= 0) {
                var candidate = candidates.get (candidates.cursor_pos);
                if (segments[segments.cursor_pos].output != candidate.output) {
                    segments[segments.cursor_pos].output = candidate.output;
                    segments_changed = true;
                }
            }
        }

        void candidates_selected (Candidate candidate) {
            if (segments.cursor_pos >= 0 && candidates.cursor_pos >= 0) {
                Candidate[] _candidates = {};

                _candidates += candidates.get (candidates.cursor_pos);
                dictionaries.call (
                    typeof (SegmentDictionary),
                    true,
                    (dictionary) => {
                        select_candidates (dictionary, _candidates);
                        return DictionaryCallbackReturn.CONTINUE;
                    });
            }
            candidates.clear ();
        }

        void select_candidates (Dictionary dictionary,
                                Candidate[] _candidates)
        {
            var segment_dict = dictionary as SegmentDictionary;
            foreach (var candidate in _candidates) {
                segment_dict.select_candidate (candidate);
            }
        }

        void select_sentence_for_dictionary (Dictionary dictionary,
                                             Gee.List<PrefixEntry?> prefixes)
        {
            var sentence_dict = dictionary as SentenceDictionary;
            foreach (var prefix in prefixes) {
                var _segments = segments.to_array ();
                var stop = prefix.offset + prefix.sequence.length;
                _segments = _segments[prefix.offset:stop];
                sentence_dict.select_segments (_segments);
            }
        }

        internal void select_sentence () {
            if (!segments_changed)
                return;

            string[] sequence = new string[segments.size];
            for (var i = 0; i < sequence.length; i++) {
                sequence[i] = segments[i].input;
            }
            var prefixes = SequenceUtils.enumerate_prefixes (
                sequence,
                int.min (2, segments.size),
                int.min (5, segments.size));

            dictionaries.call (typeof (SentenceDictionary),
                               true,
                               (dictionary) => {
                                   select_sentence_for_dictionary (dictionary,
                                                                   prefixes);
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
        }

        internal void reset () {
            // output and input_mode won't change
            handler_type = typeof (InitialStateHandler);
            rom_kana_converter.reset ();
            _typing_rule.get_filter ().reset ();
            segments.clear ();
            segments_changed = false;
            candidates.clear ();
            input_buffer.erase ();
            completion_iterator = null;
            completion.clear ();
            quoted = false;
        }

        string? lookup_single_for_dictionary (Dictionary dictionary,
                                              string input)
        {
            var segment_dict = dictionary as SegmentDictionary;
            Candidate[] _candidates;
            Template template;
            template = new SimpleTemplate (input);
            if (segment_dict.lookup_candidates (template.source,
                                                template.okuri,
                                                out _candidates)) {
                return template.expand (_candidates[0].text);
            }
            template = new OkuriganaTemplate (input);
            if (segment_dict.lookup_candidates (template.source,
                                                template.okuri,
                                                out _candidates)) {
                return template.expand (_candidates[0].text);
            }
            return null;
        }

        internal string? lookup_single (string input) {
            var normalized_input = RomKanaUtils.normalize (input);
            string? result = null;
            dictionaries.call (typeof (SegmentDictionary),
                               false,
                               (dictionary) => {
                                   result = lookup_single_for_dictionary (
                                       dictionary,
                                       normalized_input);
                                   if (result != null)
                                       return DictionaryCallbackReturn.REMOVE;
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
            return result;
        }

        internal void lookup (Segment segment) {
            candidates.clear ();

            var normalized_input = RomKanaUtils.normalize (segment.input);
            var original = new Candidate (
                normalized_input,
                false,
                segment.output);
            candidates.add_candidates (new Candidate[] { original });

            lookup_template (new SimpleTemplate (normalized_input));
            lookup_template (new OkuriganaTemplate (normalized_input));
            lookup_template (new NumericTemplate (normalized_input));

            for (int mode = KanaMode.HIRAGANA; mode < KanaMode.LAST; mode++) {
                var output = RomKanaUtils.convert_by_kana_mode (
                    normalized_input,
                    (KanaMode) mode);
                var candidate = new Candidate (normalized_input, false, output);
                candidates.add_candidates (new Candidate[] { candidate });
            }

            candidates.add_candidates_end ();
        }

        void lookup_template_for_dictionary (Dictionary dictionary,
                                             Template template)
        {
            var segment_dict = dictionary as SegmentDictionary;
            Candidate[] _candidates;
            if (segment_dict.lookup_candidates (template.source,
                                                template.okuri,
                                                out _candidates)) {
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

        void lookup_template (Template template) {
            dictionaries.call (typeof (SegmentDictionary),
                               false,
                               (dictionary) => {
                                   lookup_template_for_dictionary (dictionary,
                                                                   template);
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
        }

        internal void convert_sentence (string input,
                                        int[]? constraint = null)
        {
            var _segments = decoder.decode (input,
                                            1,
                                            constraint ?? new int[0]);
            segments.set_segments (_segments[0]);

            if (constraint == null) {
                apply_constraint ();
            }

            apply_phrase ();
        }

        void apply_constraint_for_dictionary (Dictionary dictionary) {
            var sentence_dict = dictionary as SentenceDictionary;
            var sequence = Utils.split_utf8 (input);
            var prefixes = SequenceUtils.enumerate_prefixes (
                sequence,
                int.min (4, sequence.length),
                sequence.length);
            var next_offset = 0;
            var next_constraint_index = 0;
            var constraint = new ArrayList<int> ();
            foreach (var prefix in prefixes) {
                if (prefix.offset < next_offset)
                    continue;
                int[] _constraint;
                var input = string.joinv ("", prefix.sequence);
                if (sentence_dict.lookup_constraint (input,
                                                     out _constraint)) {
                    assert (_constraint.length > 0);
                    var constraint_index = 0;

                    if (constraint.size > 0) {
                        var last_offset = constraint.get (constraint.size - 1);
                        if (last_offset < _constraint[0] + prefix.offset) {
                            // Fill the gap between the last offset and
                            // the beginning of the constraint.
                            var _offset = 0;
                            for (var i = 0; i < segments.size; i++) {
                                _offset += segments[i].input.char_count ();
                                if (last_offset < _offset
                                    && _offset < _constraint[0] + prefix.offset) {
                                    constraint.add (_offset);
                                }
                            }
                            next_constraint_index = constraint.size;
                        } else {
                            // Make sure that the found constraint matches
                            // the current constraint.
                            bool found_overlap = false;
                            for (var i = next_constraint_index;
                                 i < constraint.size;
                                 i++) {
                                if (constraint[i]
                                    != _constraint[i - next_constraint_index] + prefix.offset) {
                                    found_overlap = true;
                                    break;
                                }
                                constraint_index++;
                            }
                            if (found_overlap)
                                continue;
                            next_constraint_index++;
                        }
                    } else {
                        // Fill the gap between the first segment and
                        // the beginning of the constraint.
                        var _offset = 0;
                        for (var i = 0; i < segments.size; i++) {
                            _offset += segments[i].input.char_count ();
                            if (_offset < _constraint[0] + prefix.offset) {
                                constraint.add (_offset);
                            }
                        }
                        next_constraint_index = constraint.size;
                    }

                    for (var i = constraint_index; i < _constraint.length; i++)
                        constraint.add (_constraint[i] + prefix.offset);

                    next_offset = _constraint[0] + prefix.offset;
                }
            }
            var _segments = decoder.decode (input,
                                            1,
                                            constraint.to_array ());
#if false
            print ("constraint: ");
            for (var i = 0; i < constraint.size; i++) {
                print ("%d ", constraint[i]);
                
            }
            print ("\n");
#endif
            segments.set_segments (_segments[0]);
        }

        void apply_constraint () {
            dictionaries.call (typeof (SentenceDictionary),
                               false,
                               (dictionary) => {
                                   apply_constraint_for_dictionary (dictionary);
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
        }

        void apply_phrase_for_dictionary (Dictionary dictionary) {
            var sentence_dict = dictionary as SentenceDictionary;
            string[] sequence = new string[segments.size];
            for (var i = 0; i < segments.size; i++) {
                sequence[i] = segments[i].input;
            }
            var prefixes = SequenceUtils.enumerate_prefixes (
                sequence,
                int.min (2, sequence.length),
                int.min (5, sequence.length));
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

        void apply_phrase () {
            dictionaries.call (typeof (SentenceDictionary),
                               false,
                               (dictionary) => {
                                   apply_phrase_for_dictionary (dictionary);
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
        }

        internal void resize_segment (int amount) {
            if (segments.cursor_pos >= 0
                && segments.cursor_pos < segments.size) {
                // Can't expand the last segment.
                if (amount > 0 && segments.cursor_pos > segments.size - 1)
                    return;
                // Can't shrink the segment to zero-length.
                int segment_size = segments[segments.cursor_pos].input.char_count () + amount;
                if (segment_size <= 0)
                    return;

                int[] constraint = {};
                int offset = 0;
                for (var i = 0; i < segments.cursor_pos; i++) {
                    offset += segments[i].input.char_count ();
                    constraint += offset;
                }

                offset += segment_size;
                constraint += offset;

                string[] output = new string[segments.cursor_pos];
                for (var i = 0; i < output.length; i++)
                    output[i] = segments[i].output;
                int cursor_pos = segments.cursor_pos;
                convert_sentence (segments.get_input (), constraint);
                apply_phrase ();
                segments.cursor_pos = cursor_pos;
                for (var i = 0; i < output.length; i++)
                    segments[i].output = output[i];
                segments_changed = true;
            }
        }

        internal void purge_candidate (Candidate candidate) {
            dictionaries.call (typeof (SegmentDictionary),
                               true,
                               (dictionary) => {
                                   var segment_dict = dictionary as SegmentDictionary;
                                   segment_dict.purge_candidate (candidate);
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
        }

        internal void completion_start (string input) {
            dictionaries.call (typeof (SegmentDictionary),
                               false,
                               (dictionary) => {
                                   var segment_dict = dictionary as SegmentDictionary;
                                   string[] _completion = segment_dict.complete (input);
                                   foreach (var word in _completion) {
                                       completion.add (word);
                                   }
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
            completion.sort ();
            completion_iterator = completion.iterator ();
            if (!completion_iterator.first ()) {
                completion_iterator = null;
            }
        }

        public signal void request_selection_text ();
    }

    abstract class StateHandler : Object {
        internal abstract bool process_key_event (State state, ref KeyEvent key);
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
            { "set-input-mode-wide-latin", InputMode.WIDE_LATIN },
            { "set-input-mode-direct", InputMode.DIRECT }
        };

        internal override bool process_key_event (State state,
                                                  ref KeyEvent key)
        {
            var command = state.lookup_key (key);
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
                        state.selection.erase ();
                        state.input_mode = entry.value;
                        return true;
                    }
                }
            }

            if (state.input_mode == InputMode.DIRECT)
                return false;

            // insert quoted
            if (command == "quote") {
                state.quoted = true;
                return true;
            }

            if (state.quoted &&
                (key.modifiers == 0 ||
                 key.modifiers == Kkc.ModifierType.SHIFT_MASK) &&
                0x20 <= key.code && key.code < 0x7F) {
                state.rom_kana_converter.output_nn_if_any ();
                state.input_buffer.append (state.rom_kana_converter.output);
                state.rom_kana_converter.output = "";
                state.input_buffer.append_c ((char) key.code);
                state.quoted = false;
                return true;
            }

            // check state transition
            if (command == "next-candidate") {
                if (state.input_buffer.len == 0)
                    return false;
                if (state.selection.len > 0) {
                    var input = state.input_buffer.str;
                    var segment = new Segment (input, state.selection.str);
                    state.selection.erase ();
                    state.segments.set_segments (segment);
                    state.segments.first_segment ();
                    state.candidates.first ();
                    state.handler_type = typeof (ConvertSegmentStateHandler);
                    return true;
                }
                if (state.segments.size == 0) {
                    state.rom_kana_converter.output_nn_if_any ();
                    state.input_buffer.append (state.rom_kana_converter.output);
                    string input = RomKanaUtils.get_hiragana (
                        state.input_buffer.str);
                    var output = state.lookup_single (input);
                    if (output != null) {
                        var segment = new Segment (input, output);
                        state.segments.set_segments (segment);
                    } else {
                        state.convert_sentence (input);
                    }
                    state.segments.first_segment ();
                    state.handler_type = typeof (ConvertSentenceStateHandler);
                    return true;
                }
            }

            // word registration
            if (command == "register") {
                state.request_selection_text ();
                return true;
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
            else if (command == "complete") {
                state.rom_kana_converter.output_nn_if_any ();
                state.input_buffer.append (state.rom_kana_converter.output);
                state.rom_kana_converter.output = "";
                if (state.input_buffer.len > 0) {
                    if (state.completion_iterator == null) {
                        state.completion_start (state.input_buffer.str);
                    }
                    if (state.completion_iterator != null) {
                        string input = state.completion_iterator.get ();
                        state.input_buffer.assign (input);
                        if (state.completion_iterator.has_next ()) {
                            state.completion_iterator.next ();
                        }
                    }
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
                    var kana = RomKanaUtils.convert_by_kana_mode (
                        command["insert-kana-".length:command.length],
                        (KanaMode) state.input_mode);
                    state.input_buffer.append (kana);
                    return true;
                }
                if ((key.modifiers == 0 ||
                     key.modifiers == Kkc.ModifierType.SHIFT_MASK) &&
                    0x20 <= key.code && key.code < 0x7F) {
                    if (state.rom_kana_converter.append (key.code)) {
                        state.input_buffer.append (
                            state.rom_kana_converter.output);
                        state.rom_kana_converter.output = "";
                        return true;
                    } else {
                        state.input_buffer.append_c ((char) key.code);
                        state.rom_kana_converter.output = "";
                        return true;
                    }
                }
                break;
            case InputMode.LATIN:
                if ((key.modifiers == 0 ||
                     key.modifiers == Kkc.ModifierType.SHIFT_MASK) &&
                    0x20 <= key.code && key.code < 0x7F) {
                    state.input_buffer.append_c ((char) key.code);
                    return true;
                }
                break;
            case InputMode.WIDE_LATIN:
                if ((key.modifiers == 0 ||
                     key.modifiers == Kkc.ModifierType.SHIFT_MASK) &&
                    0x20 <= key.code && key.code < 0x7F) {
                    state.input_buffer.append_unichar (
                        RomKanaUtils.get_wide_latin_char ((char) key.code));
                    return true;
                }
                break;
            default:
                break;
            }

            bool retval = state.input_buffer.len > 0 ||
                state.rom_kana_converter.preedit.length > 0;
            state.rom_kana_converter.output_nn_if_any ();
            state.output.append (state.input_buffer.str);
            state.output.append (state.rom_kana_converter.output);
            state.output.append (state.rom_kana_converter.preedit);
            state.reset ();
            return retval;
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
                        RomKanaUtils.convert_by_kana_mode (
                            state.rom_kana_converter.output,
                            (KanaMode) entry.value));
                    state.rom_kana_converter.reset ();
                    return true;
                }
            }

            if (command == "next-candidate"
                || command == "previous-candidate"
                || command == "purge-candidate") {
                state.handler_type = typeof (ConvertSegmentStateHandler);
                state.lookup (state.segments[state.segments.cursor_pos]);
                state.candidates.first ();
                return false;
            }
            if (command != null && command.has_prefix ("insert-kana-")) {
                var kana = RomKanaUtils.convert_by_kana_mode (
                    command["insert-kana-".length:command.length],
                    (KanaMode) state.input_mode);
                state.rom_kana_converter.output = kana;
                return true;
            }
            else if (command == "expand-segment") {
                if (state.segments.cursor_pos < state.segments.size - 1)
                    state.resize_segment (1);
                return true;
            }
            else if (command == "shrink-segment") {
                if (state.segments[state.segments.cursor_pos].input.char_count () > 1)
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
                // If the key is not bound or won't be further
                // processed by InitialStateHandler, update preedit.
                return command != null || command == "commit" ||
                    !((key.modifiers == 0 ||
                       key.modifiers == Kkc.ModifierType.SHIFT_MASK) &&
                      0x20 <= key.code && key.code < 0x7F);
            }
        }
    }

    class ConvertSegmentStateHandler : StateHandler {
        internal override bool process_key_event (State state,
                                                  ref KeyEvent key)
        {
            var command = state.lookup_key (key);
            if (command == "previous-candidate") {
                state.candidates.cursor_up ();
                return true;
            }
            else if (command == "next-candidate") {
                state.candidates.cursor_down ();
                return true;
            }
            else if (command == "purge-candidate") {
                if (state.candidates.cursor_pos >= 0) {
                    var candidate = state.candidates.get ();
                    state.purge_candidate (candidate);
                    state.reset ();
                }
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
