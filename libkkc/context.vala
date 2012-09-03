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
    /**
     * Main entry point of libkkc.
     */
    public class Context : Object {
		State state;
        Gee.Map<Type, StateHandler> handlers =
            new HashMap<Type, StateHandler> ();

        /**
         * Current candidates.
         */
        public CandidateList candidates {
            get {
                return state.candidates;
            }
        }

        /**
         * Current input mode.
         */
        public InputMode input_mode {
            get {
                return state.input_mode;
            }
            set {
                state.input_mode = value;
            }
        }

        /**
         * Array of strings which triggers automatic conversion.
         */
        public string[] auto_start_henkan_keywords {
            get {
                return state.auto_start_henkan_keywords;
            }
            set {
                state.auto_start_henkan_keywords = value;
            }
        }

        /**
         * Period style used in romaji-to-kana conversion.
         */
        public PeriodStyle period_style {
            get {
                return state.period_style;
            }
            set {
                state.period_style = value;
            }
        }

        void filter_forwarded_cb (KeyEvent key) {
            process_key_event_internal (key);
        }

        /**
         * The name of typing rule.
         */
        public Rule typing_rule {
            get {
                return state.typing_rule;
            }
            set {
                state.typing_rule.get_filter ().forwarded.disconnect (
                    filter_forwarded_cb);
                state.typing_rule = value;
                state.typing_rule.get_filter ().forwarded.connect (
                    filter_forwarded_cb);
            }
        }

        /**
         * Filter which runs before process_key_event.
         *
         * This is particularly useful for NICOLA.
         * @see NicolaKeyEventFilter
         */
        public KeyEventFilter key_event_filter {
            owned get {
                return state.typing_rule.get_filter ();
            }
        }

        /**
         * Create a new Context.
         *
         * @return a new Context
         */
        public Context (Dict dict) {
            handlers.set (typeof (NoneStateHandler),
                          new NoneStateHandler ());
            handlers.set (typeof (StartStateHandler),
                          new StartStateHandler ());
            handlers.set (typeof (SelectStateHandler),
                          new SelectStateHandler ());
			var decoder = Kkc.Decoder.new_for_dict (dict);
            state = new State (decoder);
            connect_state_signals (state);
        }

        ~Context () {
            disconnect_state_signals (state);
        }

        void notify_input_mode_cb (Object s, ParamSpec? p) {
            notify_property ("input-mode");
        }

        bool retrieve_surrounding_text_cb (out string text,
                                           out uint cursor_pos)
        {
            return retrieve_surrounding_text (out text, out cursor_pos);
        }

        bool delete_surrounding_text_cb (int offset, uint nchars) {
            return delete_surrounding_text (offset, nchars);
        }

        void notify_cursor_pos_cb (Object s, ParamSpec? p) {
            if (((CandidateList) candidates).cursor_pos >= 0) {
                update_preedit ();
            }
        }

        void connect_state_signals (State state) {
            state.notify["input-mode"].connect (notify_input_mode_cb);
            state.retrieve_surrounding_text.connect (
                retrieve_surrounding_text_cb);
            state.delete_surrounding_text.connect (
                delete_surrounding_text_cb);
            state.candidates.notify["cursor-pos"].connect (
                notify_cursor_pos_cb);
        }

        void disconnect_state_signals (State state) {
            state.notify["input-mode"].disconnect (notify_input_mode_cb);
            state.retrieve_surrounding_text.disconnect (
                retrieve_surrounding_text_cb);
            state.delete_surrounding_text.disconnect (
                delete_surrounding_text_cb);
            state.candidates.notify["cursor-pos"].disconnect (
                notify_cursor_pos_cb);
        }

        /**
         * Signal emitted when the context requires surrounding-text.
         *
         * @param text surrounding text
         * @param cursor_pos cursor position in text
         *
         * @return `true` on success, `false` on failure
         */
        public signal bool retrieve_surrounding_text (out string text,
                                                      out uint cursor_pos);

        /**
         * Signal emitted when the context requests deletion of
         * surrounding-text.
         *
         * @param offset character offset from the cursor position.
         * @param nchars number of characters to delete.
         *
         * @return `true` on success, `false` on failure
         */
        public signal bool delete_surrounding_text (int offset,
                                                    uint nchars);

        /**
         * Pass key events (separated by spaces) to the context.
         *
         * This function is rarely used in programs but in unit tests.
         *
         * @param keyseq a string representing key events, separated by " "
         *
         * @return `true` if any of key events are handled, `false` otherwise
         */
        public bool process_key_events (string keyseq) {
            Gee.List<string> keys = new ArrayList<string> ();
            var builder = new StringBuilder ();
            bool complex = false;
            bool escaped = false;
            int index = 0;
            unichar uc;
            while (keyseq.get_next_char (ref index, out uc)) {
                if (escaped) {
                    builder.append_unichar (uc);
                    escaped = false;
                    continue;
                }
                switch (uc) {
                case '\\':
                    escaped = true;
                    break;
                case '(':
                    if (complex) {
                        warning ("bare '(' is not allowed in complex keyseq");
                        return false;
                    }
                    complex = true;
                    builder.append_unichar (uc);
                    break;
                case ')':
                    if (!complex) {
                        warning ("bare ')' is not allowed in simple keyseq");
                        return false;
                    }
                    complex = false;
                    builder.append_unichar (uc);
                    keys.add (builder.str);
                    builder.erase ();
                    break;
                case ' ':
                    if (complex) {
                        builder.append_unichar (uc);
                    }
                    else if (builder.len > 0) {
                        keys.add (builder.str);
                        builder.erase ();
                    }
                    break;
                default:
                    builder.append_unichar (uc);
                    break;
                }
            }
            if (complex) {
                warning ("premature end of key events");
                return false;
            }
            if (builder.len > 0) {
                keys.add (builder.str);
            }

            bool retval = false;
            foreach (var key in keys) {
                if (key == "SPC")
                    key = " ";
                else if (key == "TAB")
                    key = "\t";
                else if (key == "RET")
                    key = "\n";
                else if (key == "DEL")
                    key = "\b";

                KeyEvent ev;
                try {
                    ev = new KeyEvent.from_string (key);
                } catch (KeyEventFormatError e) {
                    warning ("can't get key event from string %s: %s",
                             key, e.message);
                    return false;
                }
                if (process_key_event (ev) && !retval)
                    retval = true;
            }
            return retval;
        }

        /**
         * Pass one key event to the context.
         *
         * @param key a key event
         *
         * @return `true` if the key event is handled, `false` otherwise
         */
        public bool process_key_event (KeyEvent key) {
            KeyEvent? _key = key_event_filter.filter_key_event (key);
            if (_key == null)
                return true;
            return process_key_event_internal (_key);
        }

        bool process_key_event_internal (KeyEvent key) {
            KeyEvent _key = key.copy ();
            while (true) {
                var handler_type = state.handler_type;
                var handler = handlers.get (handler_type);
                if (handler.process_key_event (state, ref _key)) {
                    // FIXME should do this only when preedit is really changed
                    update_preedit ();
                    return true;
                }
                // state.handler_type may change if handler cannot
                // handle the event.  In that case retry with the new
                // handler.  Otherwise exit the loop.
                if (handler_type == state.handler_type) {
                    return false;
                }
            }
        }

        /**
         * Reset the context.
         */
        public void reset () {
            // will clear state.candidates but not state.output
            state.reset ();

            // clear output and preedit
            clear_output ();
            preedit = "";
        }

        string retrieve_output (bool clear) {
            var handler = handlers.get (state.handler_type);
            var output = handler.get_output (state);
            if (clear) {
                state.output.erase ();
            }
            return output;
        }

        /**
         * Peek (retrieve, but not remove) the current output string.
         *
         * @return an output string
         */
        public string peek_output () {
            return retrieve_output (false);
        }

        /**
         * Poll (retrieve and remove) the current output string.
         *
         * @return an output string
         */
        public string poll_output () {
            return retrieve_output (true);
        }

        /**
         * Clear the output buffer.
         */
        public void clear_output () {
            state.output.erase ();
        }

        /**
         * Current preedit string.
         */
        [CCode(notify = false)]
        public string preedit { get; private set; default = ""; }

        void update_preedit () {
            var builder = new StringBuilder ();
            var handler = handlers.get (state.handler_type);
            uint offset, nchars;
            builder.append (handler.get_preedit (state,
                                                 out offset,
                                                 out nchars));

            bool changed = false;
            if (preedit != builder.str) {
                preedit = builder.str;
                changed = true;
            }
            if (preedit_underline_offset != offset ||
                preedit_underline_nchars != nchars) {
                preedit_underline_offset = offset;
                preedit_underline_nchars = nchars;
                changed = true;
            }
            if (changed) {
                notify_property ("preedit");
            }
        }

        uint preedit_underline_offset = 0;
        uint preedit_underline_nchars = 0;

        /**
         * Get underlined range of preedit.
         *
         * @param offset starting offset (in chars) of underline
         * @param nchars number of characters to be underlined
         */
        public void get_preedit_underline (out uint offset, out uint nchars) {
            offset = preedit_underline_offset;
            nchars = preedit_underline_nchars;
        }
    }
}
