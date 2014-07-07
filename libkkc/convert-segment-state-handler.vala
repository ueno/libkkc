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

namespace Kkc {

    class ConvertSegmentStateHandler : StateHandler {
        construct {
            register_command_callback ("next-candidate",
                                       do_next_candidate);
            register_command_callback ("previous-candidate",
                                       do_previous_candidate);
            register_command_callback ("purge-candidate",
                                       do_purge_candidate);
            register_command_callback ("abort",
                                       do_clear_unhandled);
            register_command_callback ("next-segment",
                                       do_select_unhandled);
            register_command_callback ("previous-segment",
                                       do_select_unhandled);
            register_command_callback ("first-segment",
                                       do_select_unhandled);
            register_command_callback ("last-segment",
                                       do_select_unhandled);
            register_command_callback ("delete",
                                       do_clear_unhandled);
            register_command_callback ("original-candidate",
                                       do_clear_unhandled);

            var enum_class = (EnumClass) typeof (KanaMode).class_ref ();
            for (int i = enum_class.minimum; i <= enum_class.maximum; i++) {
                var enum_value = enum_class.get_value (i);
                if (enum_value != null)
                    register_command_callback (
                        "convert-" + enum_value.value_nick,
                        do_clear_unhandled);
            }

            register_command_callback (null, do_select_unhandled);
        }

        bool do_next_candidate (string? command, State state, KeyEvent key) {
            state.candidates.cursor_down ();
            return true;
        }

        bool do_previous_candidate (string? command, State state, KeyEvent key) {
            state.candidates.cursor_up ();
            return true;
        }

        bool do_purge_candidate (string? command, State state, KeyEvent key) {
            if (state.candidates.cursor_pos >= 0) {
                var candidate = state.candidates.get ();
                state.purge_candidate (candidate);
                state.reset ();
            }
            return true;
        }

        bool do_select_unhandled (string? command, State state, KeyEvent key) {
            if (state.candidates.cursor_pos >= 0)
                state.candidates.select ();
            state.handler_type = typeof (ConvertSentenceStateHandler);
            return false;
        }

        bool do_clear_unhandled (string? command, State state, KeyEvent key) {
            state.candidates.clear ();
            state.handler_type = typeof (ConvertSentenceStateHandler);
            return false;
        }
                    
        public override bool process_key_event (State state, KeyEvent key) {
            return dispatch_command (state, key);
        }
    }
}
