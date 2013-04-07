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
    public errordomain KeyEventFormatError {
        PARSE_FAILED,
        KEYSYM_NOT_FOUND
    }

    /**
     * A set of bit-flags to indicate the state of modifier keys.
     */
    public enum ModifierType {
        NONE = 0,
        SHIFT_MASK = 1 << 0,
        LOCK_MASK = 1 << 1,
        CONTROL_MASK = 1 << 2,
        MOD1_MASK = 1 << 3,
        MOD2_MASK = 1 << 4,
        MOD3_MASK = 1 << 5,
        MOD4_MASK = 1 << 6,
        MOD5_MASK = 1 << 7,

        // dummy modifiers for NICOLA
        LSHIFT_MASK = 1 << 22,
        RSHIFT_MASK = 1 << 23,

        SUPER_MASK = 1 << 26,
        HYPER_MASK = 1 << 27,
        META_MASK = 1 << 28,
        RELEASE_MASK = 1 << 30
    }

    /**
     * Object representing a key event.
     */
    public class KeyEvent : Object {
        /**
         * The base name of the KeyEvent.
         */
        public string name { get; construct set; }

        /**
         * The base unicode output of the KeyEvent.
         */
        public unichar code { get; construct set; }

        /**
         * X keyval.
         */
        public uint keyval { get; construct set; }

        /**
         * X keycode.
         */
        public uint keycode { get; construct set; }

        /**
         * Modifier mask.
         */
        public ModifierType modifiers { get; construct set; }

        /**
         * Create a key event from string.
         *
         * @param key a string representation of a key event
         *
         * @return a new KeyEvent
         */
        public KeyEvent.from_string (string key) throws KeyEventFormatError {
            ModifierType _modifiers = 0;
            string _name = null;
            if (key.has_prefix ("(") && key.has_suffix (")")) {
                var strv = key[1:-1].split (" ");
                int index = 0;
                for (; index < strv.length - 1; index++) {
                    if (strv[index] == "shift") {
                        _modifiers |= ModifierType.SHIFT_MASK;
                    } else if (strv[index] == "control") {
                        _modifiers |= ModifierType.CONTROL_MASK;
                    } else if (strv[index] == "meta") {
                        _modifiers |= ModifierType.META_MASK;
                    } else if (strv[index] == "hyper") {
                        _modifiers |= ModifierType.HYPER_MASK;
                    } else if (strv[index] == "super") {
                        _modifiers |= ModifierType.SUPER_MASK;
                    } else if (strv[index] == "alt") {
                        _modifiers |= ModifierType.MOD1_MASK;
                    } else if (strv[index] == "lshift") {
                        _modifiers |= ModifierType.LSHIFT_MASK;
                    } else if (strv[index] == "rshift") {
                        _modifiers |= ModifierType.RSHIFT_MASK;
                    } else if (strv[index] == "release") {
                        _modifiers |= ModifierType.RELEASE_MASK;
                    } else {
                        throw new KeyEventFormatError.PARSE_FAILED (
                            "unknown modifier %s", strv[index]);
                    }
                }
                _name = strv[index];
            }
            else {
                int index = key.last_index_of ("-");
                if (index > 0) {
                    // support only limited _modifiers in this form
                    string[] mods = key.substring (0, index).split ("-");
                    foreach (var mod in mods) {
                        if (mod == "S") {
                            _modifiers |= ModifierType.SHIFT_MASK;
                        } else if (mod == "C") {
                            _modifiers |= ModifierType.CONTROL_MASK;
                        } else if (mod == "A") {
                            _modifiers |= ModifierType.MOD1_MASK;
                        } else if (mod == "M") {
                            _modifiers |= ModifierType.META_MASK;
                        } else if (mod == "G") {
                            _modifiers |= ModifierType.MOD5_MASK;
                        }
                    }
                    _name = key.substring (index + 1);
                } else {
                    _modifiers = ModifierType.NONE;
                    _name = key;
                }
            }
            from_x_event (KeyEventUtils.keyval_from_name (_name),
                          0,
                          _modifiers);
        }

        /**
         * Convert the KeyEvent to string.
         *
         * @return a string representing the KeyEvent
         */
        public string to_string () {
            string _base = name != null ? name : code.to_string ();
            if (modifiers != 0) {
                ArrayList<string?> elements = new ArrayList<string?> ();
                if ((modifiers & ModifierType.SHIFT_MASK) != 0) {
                    elements.add ("shift");
                }
                if ((modifiers & ModifierType.CONTROL_MASK) != 0) {
                    elements.add ("control");
                }
                if ((modifiers & ModifierType.META_MASK) != 0) {
                    elements.add ("meta");
                }
                if ((modifiers & ModifierType.HYPER_MASK) != 0) {
                    elements.add ("hyper");
                }
                if ((modifiers & ModifierType.SUPER_MASK) != 0) {
                    elements.add ("super");
                }
                if ((modifiers & ModifierType.MOD1_MASK) != 0) {
                    elements.add ("alt");
                }
                if ((modifiers & ModifierType.LSHIFT_MASK) != 0) {
                    elements.add ("lshift");
                }
                if ((modifiers & ModifierType.RSHIFT_MASK) != 0) {
                    elements.add ("rshift");
                }
                if ((modifiers & ModifierType.RELEASE_MASK) != 0) {
                    elements.add ("release");
                }
                elements.add (_base);
                elements.add (null); // make sure that strv ends with null
                return "(" + string.joinv (" ", elements.to_array ()) + ")";
            } else {
                return _base;
            }
        }

        /**
         * Create a key event from an X event.
         *
         * @param keyval an X keysym
         * @param keycode an X keycode
         * @param modifiers modifier mask
         *
         * @return a new KeyEvent
         */
        public KeyEvent.from_x_event (uint keyval,
                                      uint keycode,
                                      ModifierType modifiers)
        {
            name = KeyEventUtils.keyval_name (keyval);
            code = KeyEventUtils.keyval_code (keyval);

            // Clear shift modifier when code is ASCII and not SPC.
            // FIXME: check the keymap if the key has level 2
            if (0x21 <= keyval && keyval < 0x7F)
                modifiers &= ~ModifierType.SHIFT_MASK;
            this.keyval = keyval;
            this.keycode = keycode;
            this.modifiers = modifiers; 
        }
    }
}
