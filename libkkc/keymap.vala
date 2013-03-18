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
    public class Keymap : Object {
        public Map<KeyEvent,string> entries =
            new HashMap<KeyEvent,string> ((HashFunc) key_hash,
                                          (EqualFunc) key_equal);

        static bool key_equal (KeyEvent a, KeyEvent b) {
            return a.keyval == b.keyval && a.modifiers == b.modifiers;
        }

        static uint key_hash (KeyEvent a) {
            return int_hash ((int) a.keyval) +
                int_hash ((int) a.modifiers);
        }

        public new void @set (KeyEvent key, string command) {
            entries.set (key, command);
        }

        public string? lookup_key (KeyEvent key) {
            return entries.get (key);
        }

        public KeyEvent? where_is (string command) {
            var iter = entries.map_iterator ();
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
