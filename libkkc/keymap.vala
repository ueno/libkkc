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
    class Keymap : Object {
        Map<string,string> entries = new HashMap<string,string> ();

        public new void @set (string key, string command) {
            try {
                var ev = new KeyEvent.from_string (key);
                entries.set (ev.to_string (), command);
            } catch (KeyEventFormatError e) {
                warning ("can't get key event from string %s: %s",
                         key, e.message);
            }
        }

        public string? lookup_key (KeyEvent key) {
            return entries.get (key.to_string ());
        }

        public KeyEvent? where_is (string command) {
            var iter = entries.map_iterator ();
            if (iter.first ()) {
                do {
                    if (iter.get_value () == command) {
                        var key = iter.get_key ();
                        try {
                            return new KeyEvent.from_string (key);
                        } catch (KeyEventFormatError e) {
                            warning ("can't get key event from string %s: %s",
                                     key, e.message);
                        }
                    }
                } while (iter.next ());
            }
            return null;
        }
    }
}
