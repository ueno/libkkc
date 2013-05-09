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
    class InitialStateHandler : StateHandler {
        class ConvertCommandHandler : CommandHandler, Object {
            KanaMode mode;

            public ConvertCommandHandler (KanaMode mode) {
                this.mode = mode;
            }

            public bool call (string? command, State state, KeyEvent key) {
                if (state.input_characters.size > 0) {
                    state.selection.erase ();
                    state.finish_input_editing ();
                    state.overriding_input =
                    state.convert_rom_kana_characters_by_kana_mode (
                        state.input_characters,
                        mode);
                    return true;
                }
                return false;
            }
        }

        construct {
            var enum_class = (EnumClass) typeof (KanaMode).class_ref ();
            for (int i = enum_class.minimum; i <= enum_class.maximum; i++) {
                var enum_value = enum_class.get_value (i);
                if (enum_value != null)
                    register_command_handler (
                        "convert-" + enum_value.value_nick,
                        new ConvertCommandHandler (
                            (KanaMode) enum_value.value));
            }

            register_command_callback ("abort", do_abort);
            register_command_callback ("complete", do_complete);
            register_command_callback ("delete", do_delete);
            register_command_callback ("delete-forward", do_delete_forward);
            register_command_callback ("next-candidate", do_next_candidate);
            register_command_callback ("next-segment", do_next_character);
            register_command_callback ("previous-segment", do_previous_character);
            register_command_callback ("quote", do_quote);
            register_command_callback ("register", do_register);

            register_command_callback (null, do_);
        }

        bool do_quote (string? command, State state, KeyEvent key) {
            state.quoted = true;
            return true;
        }

        bool do_register (string? command, State state, KeyEvent key) {
            state.request_selection_text ();
            return true;
        }

        bool do_abort (string? command, State state, KeyEvent key) {
            if (state.overriding_input != null) {
                state.overriding_input = null;
                return true;
            }

            if (state.has_input ()) {
                state.reset ();
                return true;
            }

            return false;
        }

        bool do_delete (string? command, State state, KeyEvent key) {
            if (state.overriding_input != null) {
                state.overriding_input = null;
                return true;
            }

            if (state.rom_kana_converter.delete ())
                return true;

            if (state.input_characters_cursor_pos >= 0) {
                if (state.input_characters_cursor_pos > 0)
                    state.input_characters.remove_at (
                        --state.input_characters_cursor_pos);
                return true;
            }

            if (state.input_characters.size > 0) {
                state.input_characters.remove_at (
                    state.input_characters.size - 1);
                return true;
            }

            return false;
        }

        bool do_delete_forward (string? command, State state, KeyEvent key) {
            if (state.input_characters_cursor_pos >= 0 &&
                state.input_characters_cursor_pos < state.input_characters.size - 1) {
                state.input_characters.remove_at (
                    state.input_characters_cursor_pos);
                return true;
            }

            return false;
        }

        bool do_complete (string? command, State state, KeyEvent key) {
            state.finish_input_editing ();
            if (state.input_characters.size > 0) {
                if (state.completion_iterator == null)
                    state.completion_start (state.get_input ());

                if (state.completion_iterator != null) {
                    state.overriding_input = state.completion_iterator.get ();
                    if (state.completion_iterator.has_next ())
                        state.completion_iterator.next ();
                }
                return true;
            }
            return false;
        }

        bool do_next_candidate (string? command, State state, KeyEvent key) {
            if (state.input_characters.size == 0)
                return false;

            if (state.selection.len > 0) {
                var input = state.get_input ();
                var segment = new Segment (input, state.selection.str);
                state.selection.erase ();
                state.segments.set_segments (segment);
                state.segments.first_segment ();
                state.lookup (state.segments[state.segments.cursor_pos]);
                state.candidates.first ();
                state.handler_type = typeof (ConvertSegmentStateHandler);
                return true;
            }

            if (state.segments.size == 0) {
                state.finish_input_editing ();
                string input = RomKanaUtils.get_hiragana (state.get_input ());

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

            return true;
        }

        bool do_next_character (string? command, State state, KeyEvent key) {
            if (state.input_characters_cursor_pos >= 0 &&
                state.input_characters_cursor_pos < state.input_characters.size - 1)
                state.input_characters_cursor_pos++;
            return true;
        }

        bool do_previous_character (string? command, State state, KeyEvent key) {
            if (state.input_characters_cursor_pos < 0 &&
                state.input_characters.size > 0) {
                state.finish_input_editing ();
                state.input_characters_cursor_pos = state.input_characters.size - 1;
                return true;
            }

            if (state.input_characters_cursor_pos > 0)
                state.input_characters_cursor_pos--;
            return true;
        }

        bool do_ (string? command, State state, KeyEvent key) {
            bool retval = false;

            if (state.overriding_input != null) {
                state.output.append (state.get_input ());
                state.overriding_input = null;
                state.reset ();
                retval = true;
            }

            if (command != null && command.has_prefix ("insert-kana-")) {
                var kana = RomKanaUtils.convert_by_kana_mode (
                    command["insert-kana-".length:command.length],
                    (KanaMode) state.input_mode);
                state.input_characters.add (RomKanaCharacter () {
                        output = kana,
                        input = key.unicode.to_string ()
                    });
                return true;
            }

            if ((key.modifiers == 0 ||
                 key.modifiers == Kkc.ModifierType.SHIFT_MASK) &&
                state.rom_kana_converter.is_valid (key.unicode)) {
                if (state.rom_kana_converter.append (key.unicode)) {
                    if (state.rom_kana_converter.produced.size > 0) {
                        if (state.input_characters_cursor_pos > 0) {
                            state.input_characters.insert_all (
                                state.input_characters_cursor_pos,
                                state.rom_kana_converter.produced);
                            state.input_characters_cursor_pos++;
                        } else {
                            state.input_characters.add_all (
                                state.rom_kana_converter.produced);
                        }
                        state.rom_kana_converter.produced.clear ();
                    }
                    return true;
                } else {
                    state.input_characters.add (RomKanaCharacter () {
                            output = key.unicode.to_string (),
                            input = key.unicode.to_string ()
                        });
                    state.rom_kana_converter.produced.clear ();
                    return true;
                }
            }

            state.finish_input_editing ();
            var input = state.get_input ();
            state.output.append (input);
            state.reset ();
            return retval || input.length > 0;
        }

        public override bool process_key_event (State state, KeyEvent key) {
            // In the initial state, we need to process some special
            // commands (e.g. quoted insert, input mode switch, etc.)
            // prior to standard commands.
            var command = state.lookup_key (key);

            // Clear completion data set by the last command.
            if (state.last_command_key != null) {
                string last_command = state.lookup_key (state.last_command_key);
                if (last_command == "complete" && command != "complete") {
                    if (state.overriding_input != null) {
                        var builder = new StringBuilder ();
                        builder.append (state.input_characters.get_input ());
                        state.input_characters.clear ();
                        state.input_characters.add (RomKanaCharacter () {
                                output = state.overriding_input,
                                input = builder.str
                            });
                    }
                    state.overriding_input = null;
                    state.completion_iterator = null;
                }
            }

            // Check mode switch events prior to further processing.
            if (command != null && command.has_prefix ("set-input-mode-")) {
                var enum_class = (EnumClass) typeof (InputMode).class_ref ();
                var enum_value = enum_class.get_value_by_nick (
                    command["set-input-mode-".length:command.length]);
                if (enum_value != null) {
                    state.selection.erase ();
                    state.finish_input_editing ();
                    state.output.append (state.get_input ());
                    state.reset ();
                    state.input_mode = (InputMode) enum_value.value;
                    return true;
                }
            }

            // Under direct input mode, don't process any keys, except
            // mode switch keys.
            if (state.input_mode == InputMode.DIRECT)
                return false;

            // Quoted insert.
            if (state.quoted &&
                (key.modifiers == 0 ||
                 key.modifiers == Kkc.ModifierType.SHIFT_MASK)) {
                state.finish_input_editing ();
                state.input_characters.add (RomKanaCharacter () {
                        output = key.unicode.to_string (),
                        input = key.unicode.to_string ()
                    });
                state.quoted = false;
                return true;
            }

            return dispatch_command (state, key);
        }
    }
}
