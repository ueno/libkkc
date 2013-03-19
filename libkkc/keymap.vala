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
    struct KeymapCommandEntry {
        string name;
        string label;
    }

    public struct KeymapEntry {
        KeyEvent key;
        string? command;
    }

    public class Keymap : Object {
        static const KeymapCommandEntry Commands[] = {
            { "abort", N_("Abort") },
            { "commit", N_("Commit") },
            { "complete", N_("Complete") },
            { "delete", N_("Delete") },
            { "quote", N_("Quoted Insert") },
            { "register", N_("Register Word") },
            { "next-candidate", N_("Next Candidate") },
            { "previous-candidate", N_("Previous Candidate") },
            { "purge-candidate", N_("Purge Candidate") },
            { "next-segment", N_("Next Segment") },
            { "previous-segment", N_("Previous Segment") },
            { "expand-segment", N_("Expand Segment") },
            { "shrink-segment", N_("Shrink Segment") },
            { "set-input-mode-hiragana", N_("Switch to Hiragana Input Mode") },
            { "set-input-mode-katakana", N_("Switch to Katakana Input Mode") },
            { "set-input-mode-hankaku-katakana", N_("Switch to Hankaku Katakana Input Mode") },
            { "set-input-mode-latin", N_("Switch to Latin Input Mode") },
            { "set-input-mode-wide-latin", N_("Switch to Wide Latin Input Mode") },
            { "set-input-mode-direct", N_("Switch to Direct Input Mode") }
        };

        static Map<string,string> _CommandTable =
            new HashMap<string,string> ();

        static construct {
            for (var i = 0; i < Commands.length; i++) {
                var label = dgettext (Config.GETTEXT_PACKAGE,
                                      Commands[i].label);
                _CommandTable.set (Commands[i].name, label);
            }
        }

        public static string[] commands () {
            return _CommandTable.keys.to_array ();
        }

        public static string get_command_label (string command) {
            return _CommandTable.get (command);
        }

        Map<KeyEvent,string> _entries =
            new HashMap<KeyEvent,string> ((HashFunc) key_hash,
                                          (EqualFunc) key_equal);

        static bool key_equal (KeyEvent a, KeyEvent b) {
            return a.keyval == b.keyval && a.modifiers == b.modifiers;
        }

        static uint key_hash (KeyEvent a) {
            return int_hash ((int) a.keyval) +
                int_hash ((int) a.modifiers);
        }

        public KeymapEntry[] entries () {
            KeymapEntry[] result = {};
            var iter = _entries.map_iterator ();
            if (iter.first ()) {
                do {
                    var key = iter.get_key ();
                    var command = iter.get_value ();
                    KeymapEntry entry = {
                        key,
                        command
                    };
                    result += entry;
                } while (iter.next ());
            }
            return result;
        }

        public new void @set (KeyEvent key, string? command) {
            _entries.set (key, command);
        }

        public string? lookup_key (KeyEvent key) {
            return _entries.get (key);
        }

        public KeyEvent? where_is (string command) {
            var iter = _entries.map_iterator ();
            if (iter.first ()) {
                do {
                    if (iter.get_value () == command)
                        return iter.get_key ();
                } while (iter.next ());
            }
            return null;
        }
    }
}
