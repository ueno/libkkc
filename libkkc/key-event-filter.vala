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
    /**
     * Base class of a key event filter.
     */
    public abstract class KeyEventFilter : Object {
        /**
         * Convert a key event to another.
         *
         * @param key a key event
         *
         * @return a KeyEvent or `null` if the result cannot be
         * fetched immediately
         */
        public abstract KeyEvent? filter_key_event (KeyEvent key);

        /**
         * Signal emitted when a new key event is generated in the filter.
         *
         * @param key a key event
         */
        public signal void forwarded (KeyEvent key);

        /**
         * Reset the filter.
         */
        public virtual void reset () {
        }
    }

    /**
     * Simple implementation of a key event filter.
     *
     * This class is rarely used in programs but specified as "filter"
     * property in rule metadata.
     *
     * @see Rule
     */
    public class SimpleKeyEventFilter : KeyEventFilter {
        const uint[] modifier_keyvals = {
            Keysyms.Shift_L,
            Keysyms.Shift_R,
            Keysyms.Control_L,
            Keysyms.Control_R,
            Keysyms.Meta_L,
            Keysyms.Meta_R,
            Keysyms.Alt_L,
            Keysyms.Alt_R,
            Keysyms.Super_L,
            Keysyms.Super_R,
            Keysyms.Hyper_L,
            Keysyms.Hyper_R
        };

        /**
         * {@inheritDoc}
         */
        public override KeyEvent? filter_key_event (KeyEvent key) {
            // ignore modifier keys
            if (key.keyval in modifier_keyvals)
                return null;
            // ignore key release event
            if ((key.modifiers & ModifierType.RELEASE_MASK) != 0)
                return null;
            return key;
        }
    }

    /**
     * Key event filter for Kana typing rule.
     *
     * This class is rarely used in programs but specified as "filter"
     * property in rule metadata.
     *
     * @see Rule
     */
     public class KanaKeyEventFilter : SimpleKeyEventFilter {
        /**
         * {@inheritDoc}
         */
        public override KeyEvent? filter_key_event (KeyEvent key) {
            var _key = base.filter_key_event (key);
            if (_key == null)
                return null;

            // convert backslash to yen sign if the keycode is 124
            if (_key.keyval == Keysyms.backslash && _key.keycode == 124)
                return new KeyEvent.from_x_event (Keysyms.yen,
                                                  _key.keycode,
                                                  _key.modifiers);
            return _key;
        }
    }
}
