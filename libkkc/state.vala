/*
 * Copyright (C) 2011-2014 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2011-2014 Red Hat, Inc.
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
    const double MIN_UNIGRAM_COST = -5.0;

    const double DECODER_MAX_DISTANCE = 2.0;
    const double DECODER_MIN_PATH_COST = -3.0;
    const int DECODER_NBEST = 20;

    class State : Object {
        internal Type handler_type;
        InputMode _input_mode;
        [CCode(notify = false)]
        internal InputMode input_mode {
            get {
                return _input_mode;
            }
            set {
                var _last_input_mode = _input_mode;
                _input_mode = value;
                if (_input_mode >= KanaMode.HIRAGANA &&
                    _input_mode <= KanaMode.WIDE_LATIN)
                    rom_kana_converter.kana_mode = (KanaMode) _input_mode;
                if (_last_input_mode != _input_mode) {
                    notify_property ("input-mode");
                }
            }
        }

        internal void finish_input_editing () {
            rom_kana_converter.flush_partial ();
            if (input_characters_cursor_pos >= 0)
                input_characters.insert_all (input_characters_cursor_pos,
                                             rom_kana_converter.produced);
            else
                input_characters.add_all (rom_kana_converter.produced);
            rom_kana_converter.reset ();
        }

        internal void convert_segment_by_kana_mode (KanaMode mode) {
            int start_char_pos = segments.get_offset (segments.cursor_pos);
            int stop_char_pos = start_char_pos + segments[segments.cursor_pos].input.char_count ();
            var characters = input_characters.slice (start_char_pos, stop_char_pos);
            segments[segments.cursor_pos].output =
                convert_rom_kana_characters_by_kana_mode (characters, mode);
        }

        internal string convert_rom_kana_characters_by_kana_mode (RomKanaCharacterList characters, KanaMode mode) {
            update_latin_conversion_case (mode);

            switch (mode) {
            case KanaMode.HIRAGANA:
            case KanaMode.KATAKANA:
            case KanaMode.HANKAKU_KATAKANA:
                return RomKanaUtils.convert_by_kana_mode (
                    characters.get_output (),
                    mode);
            case KanaMode.LATIN:
            case KanaMode.WIDE_LATIN:
                return RomKanaUtils.convert_by_kana_mode (
                    latin_conversion_upper ?
                    characters.get_input ().up () :
                    characters.get_input (),
                    mode);
            }
            return_val_if_reached (null);
        }

        void update_latin_conversion_case (KanaMode mode) {
            if (mode == KanaMode.LATIN || mode == KanaMode.WIDE_LATIN) {
                if (last_command_key != null && this_command_key != null) {
                    var last_command = lookup_key (last_command_key);
                    var this_command = lookup_key (this_command_key);
                    if (last_command == this_command)
                        latin_conversion_upper = !latin_conversion_upper;
                    else
                        latin_conversion_upper = false;
                } else
                    latin_conversion_upper = false;
            }
        }

        internal LanguageModel model;
        internal Decoder decoder;
        internal SegmentList segments;
        bool segments_changed = false;
        internal CandidateList candidates;
        internal DictionaryList dictionaries;

        internal RomKanaConverter rom_kana_converter;
        internal RomKanaCharacterList input_characters = new RomKanaCharacterList ();
        internal int input_characters_cursor_pos = -1;

        internal int input_cursor_pos {
            get {
                if (input_characters_cursor_pos >= 0) {
                    var index = 0;
                    var offset = 0;
                    for (; index < input_characters_cursor_pos; index++) {
                        offset += input_characters[index].output.char_count ();
                    }
                    // Hack for Kana typing rule: add the length of
                    // unfinished Kana input.  Suppose the following
                    // input when moving cursor in the initial state:
                    //
                    //   F|F|FFFFF (F = finished characters, | = cursor)
                    //
                    // If user types a finished character (e.g. A, I):
                    //
                    //   FX|F|FFFFF
                    // 
                    // On the other hand, if user types an unfinished
                    // character (e.g. KA, CHI, which may be followed
                    // by sonant marks):
                    //
                    //   F|X|FFFFFF
                    //
                    // For consistency, move the cursor by the width
                    // of the unfisnished character.
                    offset += rom_kana_converter.pending_output.char_count ();
                    return offset;
                }
                return input_characters_cursor_pos;
            }
        }

        internal uint input_cursor_width {
            get {
                if (input_characters_cursor_pos >= 0)
                    return input_characters[input_characters_cursor_pos].output.char_count ();
                return input_characters_cursor_pos;
            }
        }

        internal string get_input () {
            if (overriding_input != null)
                return overriding_input;

            var builder = new StringBuilder ();
            var stop = input_characters_cursor_pos >= 0 ?
                input_characters_cursor_pos :
                input_characters.size;
            for (var i = 0; i < stop; i++)
                builder.append (input_characters[i].output);
            builder.append (rom_kana_converter.pending_output);
            for (; stop < input_characters.size; stop++)
                builder.append (input_characters[stop].output);
            return builder.str;
        }

        internal StringBuilder selection = new StringBuilder ();
        internal StringBuilder output = new StringBuilder ();
        internal bool quoted = false;
        internal KeyEvent? this_command_key = null;
        internal KeyEvent? last_command_key = null;
        bool latin_conversion_upper = false;

        internal string? overriding_input = null;
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

        internal bool auto_correct {
            get {
                return rom_kana_converter.auto_correct;
            }
            set {
                rom_kana_converter.auto_correct = value;
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
            var keymap = _typing_rule.get_keymap (input_mode);
            return_val_if_fail (keymap != null, null);
            return keymap.lookup_key (key);
        }

        internal State (LanguageModel model, DictionaryList dictionaries) {
            this.model = model;
            this.decoder = Decoder.create (model);
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
                var metadata = RuleMetadata.find ("default");
                assert (metadata != null);
                _typing_rule = new Rule (metadata);
            } catch (Error e) {
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
            dictionaries.call (
                typeof (SegmentDictionary),
                (dictionary) => {
                    var segment_dict = dictionary as SegmentDictionary;
                    segment_dict.select_candidate (candidate);
                    return DictionaryCallbackReturn.CONTINUE;
                });
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
            _typing_rule.filter.reset ();
            segments.clear ();
            segments_changed = false;
            candidates.clear ();
            input_characters.clear ();
            input_characters_cursor_pos = -1;
            overriding_input = null;
            completion_iterator = null;
            completion.clear ();
            quoted = false;
            latin_conversion_upper = false;
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
                               (dictionary) => {
                                   if (!(dictionary is UserDictionary))
                                       return DictionaryCallbackReturn.CONTINUE;
                                   result = lookup_single_for_dictionary (
                                       dictionary,
                                       normalized_input);
                                   if (result != null)
                                       return DictionaryCallbackReturn.REMOVE;
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
            if (result != null)
                return result;

            if (normalized_input.char_count () > 1) {
                var entries = model.unigram_entries (normalized_input);
                foreach (var entry in entries) {
                    if (entry.output != normalized_input &&
                        ((UnigramLanguageModel) model).unigram_cost (entry) > MIN_UNIGRAM_COST)
                        return entry.output;
                }
            }

            dictionaries.call (typeof (SegmentDictionary),
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
            candidates.add (original);

            // 1. Look up candidates from user segment dictionaries.
            lookup_template (new NumericTemplate (normalized_input), true);
            lookup_template (new SimpleTemplate (normalized_input), true);
            lookup_template (new OkuriganaTemplate (normalized_input), true);

            // 2. Look up the most frequently used unigram from language model.
            if (normalized_input.char_count () > 1) {
                var entries = model.unigram_entries (normalized_input);
                foreach (var entry in entries) {
                    if (((UnigramLanguageModel) model).unigram_cost (entry) > MIN_UNIGRAM_COST) {
                        var unigram = new Candidate (
                            normalized_input,
                            false,
                            entry.output);
                        candidates.add (unigram);
                        break;
                    }
                }
            }

            // 3. Look up candidates from system segment dictionaries.
            lookup_template (new NumericTemplate (normalized_input), false);
            lookup_template (new SimpleTemplate (normalized_input), false);
            lookup_template (new OkuriganaTemplate (normalized_input), false);

            // 4. Do sentence conversion with N-best search.

            // 4.1. Create Kana candidates to be excluded.
            var kana_candidates = new CandidateList ();
            var enum_class = (EnumClass) typeof (KanaMode).class_ref ();
            for (int i = enum_class.minimum; i <= enum_class.maximum; i++) {
                var enum_value = enum_class.get_value (i);
                if (enum_value != null) {
                    var output = RomKanaUtils.convert_by_kana_mode (
                        normalized_input,
                        (KanaMode) enum_value.value);
                    if (output != original.output) {
                        var candidate = new Candidate (normalized_input,
                                                       false,
                                                       output);
                        kana_candidates.add (candidate);
                    }
                }
            }

            // 4.2. Do sentence lookup, excluding Kana candidates.
            var _segments = decoder.decode_with_costs (normalized_input,
                                                       DECODER_NBEST,
                                                       new int[0],
                                                       DECODER_MAX_DISTANCE,
                                                       DECODER_MIN_PATH_COST);
            foreach (var _segment in _segments) {
                var builder = new StringBuilder ();
                while (_segment != null) {
                    builder.append (_segment.output);
                    _segment = _segment.next;
                }
                var sentence = new Candidate (
                    normalized_input,
                    false,
                    builder.str);
                if (!kana_candidates.contains (sentence))
                    candidates.add (sentence);
            }

            // 4.3. Add Kana candidates at the end.
            candidates.add_all (kana_candidates);

            candidates.populated ();
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
                    var text = Expression.eval (candidate.text);
                    candidate.output = template.expand (text);
                    // Annotation may also be an expression.
                    if (candidate.annotation != null) {
                        candidate.annotation = Expression.eval (
                            candidate.annotation);
                    }
                    candidates.add (candidate);
                }
            }
        }

        void lookup_template (Template template, bool user) {
            dictionaries.call (typeof (SegmentDictionary),
                               (dictionary) => {
                                   if (user && !(dictionary is UserDictionary))
                                       return DictionaryCallbackReturn.CONTINUE;
                                   lookup_template_for_dictionary (dictionary,
                                                                   template);
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
        }

        void merge_possible_okurigana_segments (int start) {
            var _segments = new ArrayList<Segment> ();
            foreach (var segment in segments) {
                _segments.add (segment);
            }
            segments.clear ();

            var index = 0;
            var offset = 0;
            for (; index < _segments.size && offset < start; index++) {
                offset += _segments[index].output.char_count ();
                segments.add (_segments[index]);
            }

            Segment? previous = null;
            for (; index < _segments.size; index++) {
                if (previous != null) {
                    if (RomKanaUtils.is_hiragana (_segments[index].output)) {
                        previous.input += _segments[index].input;
                        previous.output += _segments[index].output;
                    } else {
                        segments.add (previous);
                        previous = _segments[index];
                    }
                } else {
                    previous = _segments[index];
                }
            }
            if (previous != null)
                segments.add (previous);
        }

        internal void convert_sentence (string input,
                                        int[]? constraint = null)
        {
            var normalized_input = RomKanaUtils.normalize (input);
            var _segments = decoder.decode (normalized_input,
                                            1,
                                            constraint ?? new int[0]);

            segments.set_segments (_segments[0]);

            if (constraint == null) {
                apply_constraint (input);
            }

            apply_phrase ();

            merge_possible_okurigana_segments (
                constraint == null ? 0 : constraint[constraint.length - 1]);
        }

        void apply_constraint_for_dictionary (Dictionary dictionary,
                                              string input)
        {
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
                var _input = string.joinv ("", prefix.sequence);
                if (sentence_dict.lookup_constraint (_input,
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
                                if (last_offset < _offset &&
                                    _offset < _constraint[0] + prefix.offset) {
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
                    } else if (prefix.offset > 0) {
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
#if DEBUG
            print ("constraint: ");
            for (var i = 0; i < constraint.size; i++) {
                print ("%d ", constraint[i]);
                
            }
            print ("\n");
#endif
            segments.set_segments (_segments[0]);
        }

        void apply_constraint (string input) {
            dictionaries.call (typeof (SentenceDictionary),
                               (dictionary) => {
                                   apply_constraint_for_dictionary (dictionary,
                                                                    input);
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
                               (dictionary) => {
                                   apply_phrase_for_dictionary (dictionary);
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
        }

        internal void resize_segment (int amount) {
            if (segments.cursor_pos >= 0 &&
                segments.cursor_pos < segments.size) {
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
                               (dictionary) => {
                                   var segment_dict = dictionary as SegmentDictionary;
                                   segment_dict.purge_candidate (candidate);
                                   return DictionaryCallbackReturn.CONTINUE;
                               });
        }

        internal void completion_start (string input) {
            completion.clear ();
            dictionaries.call (typeof (SegmentDictionary),
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
            if (!completion_iterator.next ()) {
                completion_iterator = null;
            }
        }

        public signal void request_selection_text ();
    }

    interface CommandHandler : Object {
        public abstract bool call (string? command, State state, KeyEvent key);
    }

    delegate bool CommandCallback (string? command, State state, KeyEvent key);

    class CallbackCommandHandler : CommandHandler, Object {
        unowned CommandCallback cb;

        public CallbackCommandHandler (CommandCallback cb) {
            this.cb = cb;
        }

        public bool call (string? command,
                          State state,
                          KeyEvent key)
        {
            return this.cb (command, state, key);
        }
    }

    abstract class StateHandler : Object {
        Map<string, CommandHandler> command_handlers =
            new HashMap<string, CommandHandler> ();
        CommandHandler? default_command_handler = null;

        public void register_command_handler (string? command,
                                              CommandHandler handler)
        {
            if (command != null)
                command_handlers.set (command, handler);
            else
                default_command_handler = handler;
        }

        public void register_command_callback (string? command,
                                               CommandCallback cb)
        {
            register_command_handler (command, new CallbackCommandHandler (cb));
        }

        public bool dispatch_command (State state, KeyEvent key) {
            var command = state.lookup_key (key);
            if (command != null && command_handlers.has_key (command))
                return command_handlers.get (command).call (command,
                                                            state,
                                                            key);
            return default_command_handler.call (command, state, key);
        }

        public abstract bool process_key_event (State state, KeyEvent key);
    }
}
