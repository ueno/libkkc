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

namespace Kkc {

    class ConvertSentenceStateHandler : StateHandler {
        class ConvertCommandHandler : CommandHandler, Object {
            KanaMode mode;

            public ConvertCommandHandler (KanaMode mode) {
                this.mode = mode;
            }

            public bool call (string? command, State state, KeyEvent key) {
                state.convert_segment_by_kana_mode (mode);
                return true;
            }
        }

        construct {
            register_command_callback ("next-candidate",
                                       do_start_segment_conversion);
            register_command_callback ("previous-candidate",
                                       do_start_segment_conversion);
            register_command_callback ("purge-candidate",
                                       do_start_segment_conversion);

            register_command_callback ("original-candidate",
                                       do_original_candidate);
            register_command_callback ("expand-segment",
                                       do_expand_segment);
            register_command_callback ("shrink-segment",
                                       do_shrink_segment);

            register_command_callback ("next-segment",
                                       do_next_segment);
            register_command_callback ("previous-segment",
                                       do_previous_segment);

            register_command_callback ("abort", do_clear_unhandled);
            register_command_callback ("delete", do_clear_unhandled);

            var enum_class = (EnumClass) typeof (KanaMode).class_ref ();
            for (int i = enum_class.minimum; i <= enum_class.maximum; i++) {
                var enum_value = enum_class.get_value (i);
                if (enum_value != null)
                    register_command_handler (
                        "convert-" + enum_value.value_nick,
                        new ConvertCommandHandler (
                            (KanaMode) enum_value.value));
            }

            register_command_callback (null, do_);
        }

        bool do_original_candidate (string? command, State state, KeyEvent key) {
            var segment = state.segments[state.segments.cursor_pos];
            segment.output = segment.input;
            return true;
        }

        bool do_expand_segment (string? command, State state, KeyEvent key) {
            if (state.segments.cursor_pos < state.segments.size - 1)
                state.resize_segment (1);
            return true;
        }

        bool do_shrink_segment (string? command, State state, KeyEvent key) {
            if (state.segments[state.segments.cursor_pos].input.char_count () > 1)
                state.resize_segment (-1);
            return true;
        }

        bool do_next_segment (string? command, State state, KeyEvent key) {
            state.segments.next_segment ();
            return true;
        }

        bool do_previous_segment (string? command, State state, KeyEvent key) {
            state.segments.previous_segment ();
            return true;
        }

        bool do_start_segment_conversion (string? command, State state, KeyEvent key) {
            state.lookup (state.segments[state.segments.cursor_pos]);
            state.candidates.first ();
            state.handler_type = typeof (ConvertSegmentStateHandler);
            return false;
        }

        bool do_clear_unhandled (string? command, State state, KeyEvent key) {
            state.segments.clear ();
            state.handler_type = typeof (InitialStateHandler);
            return true;
        }

        bool do_ (string? command, State state, KeyEvent key) {
            state.output.append (state.segments.get_output ());
            state.select_sentence ();
            state.reset ();

            if (command == "commit")
                return true;

            if (command == null &&
                (key.modifiers == 0 ||
                 key.modifiers == Kkc.ModifierType.SHIFT_MASK))
                return false;

            return true;
        }

        public override bool process_key_event (State state, KeyEvent key) {
            return dispatch_command (state, key);
        }
    }
}
