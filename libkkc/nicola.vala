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
    /**
     * Get the current timer count.
     */
    public delegate int64 GetTime ();

    /**
     * Key event filter implementing NICOLA (thumb shift) input
     *
     * This class is rarely used in programs but specified as "filter"
     * property in rule metadata.
     *
     * @see Rule
     */
    public class NicolaKeyEventFilter : KeyEventFilter {
        static int64 get_time () {
            var tv = TimeVal ();
            return (((int64) tv.tv_sec) * 1000000) + tv.tv_usec;
        }

        public GetTime get_time_func = get_time;

        /**
         * Duration where a single key press event is committed
         * without a corresponding key release event.
         */
        public int64 timeout = 100000;

        /**
         * Duration between two overlapping key press events, so they
         * are considered as a doule key press/release event.
         */
        public int64 overlap = 50000;

        /**
         * Maximum duration to wait for the next key event.
         */
        public int64 maxwait = 10000000;

        class TimedEntry<T> {
            public T data;
            public int64 time;

            public TimedEntry (T data, int64 time) {
                this.data = data;
                this.time = time;
            }
        }

        LinkedList<TimedEntry<KeyEvent>> pending = new LinkedList<TimedEntry<KeyEvent>> ();

        static bool is_char (KeyEvent key) {
            return key.code != 0;
        }

        static bool is_lshift (KeyEvent key) {
            return key.name == "Muhenkan";
        }

        static bool is_rshift (KeyEvent key) {
            return key.name == "Henkan";
        }

        static bool is_shift (KeyEvent key) {
            return is_lshift (key) || is_rshift (key);
        }

        KeyEvent? queue (KeyEvent key, int64 time, out int64 wait) {
            // press/release a same key
            if ((key.modifiers & ModifierType.RELEASE_MASK) != 0) {
                if (pending.size > 0 && pending.get (0).data.base_equal (key)) {
                    var entry = pending.get (0);
                    wait = get_next_wait (key, time);
                    pending.clear ();
                    return entry.data;
                }
            }
            // ignore key repeat
            else {
                if (pending.size > 0 && pending.get (0).data.base_equal (key)) {
                    pending.get (0).time = time;
                    wait = get_next_wait (key, time);
                    return key;
                }
                else {
                    if (pending.size > 2) {
                        var iter = pending.list_iterator ();
                        iter.last ();
                        do {
                            iter.remove ();
                        } while (pending.size > 2 && iter.previous ());
                    }
                    pending.insert (0, new TimedEntry<KeyEvent> (key, time));
                }
            }
            wait = maxwait;
            return null;
        }

        int64 get_next_wait (KeyEvent key, int64 time) {
            if (pending.size > 0) {
                var iter = pending.list_iterator ();
                iter.last ();
                do {
                    var entry = iter.get ();
                    if (time - entry.time > timeout) {
                        iter.remove ();
                    }
                } while (iter.previous ());
            }
            if (pending.size > 0) {
                return timeout - (time - pending.last ().time);
            } else {
                return maxwait;
            }
        }

        KeyEvent? dispatch_single (int64 time) {
            var entry = pending.peek ();
            if (time - entry.time > timeout) {
                pending.clear ();
                return entry.data;
            }
            return null;
        }

        void apply_shift (KeyEvent s, KeyEvent c) {
            if (is_lshift (s)) {
                c.modifiers |= ModifierType.LSHIFT_MASK;
            } else if (is_rshift (s)) {
                c.modifiers |= ModifierType.RSHIFT_MASK;
            }
        }

        KeyEvent? dispatch (int64 time) {
            if (pending.size == 3) {
                var b = pending.get (0);
                var s = pending.get (1);
                var a = pending.get (2);
                var t1 = s.time - a.time;
                var t2 = b.time - s.time;
                if (t1 <= t2) {
                    pending.clear ();
                    pending.offer_head (b);
                    var r = dispatch_single (time);
                    apply_shift (s.data, a.data);
                    forwarded (a.data);
                    return r;
                } else {
                    pending.clear ();
                    apply_shift (s.data, b.data);
                    forwarded (a.data);
                    return b.data;
                }
            } else if (pending.size == 2) {
                var b = pending.get (0);
                var a = pending.get (1);
                if (b.time - a.time > overlap) {
                    pending.clear ();
                    pending.offer_head (b);
                    var r = dispatch_single (time);
                    forwarded (a.data);
                    return r;
                } else if ((is_char (a.data) && is_char (b.data)) ||
                           (is_shift (a.data) && is_shift (b.data))) {
                    pending.clear ();
                    pending.offer_head (b);
                    var r = dispatch_single (time);
                    forwarded (a.data);
                    return r;
                } else if (time - a.time > timeout) {
                    pending.clear ();
                    if (is_shift (b.data)) {
                        apply_shift (b.data, a.data);
                        return a.data;
                    } else {
                        apply_shift (a.data, b.data);
                        return b.data;
                    }
                }
            } else if (pending.size == 1) {
                return dispatch_single (time);
            }

            return null;
        }

        bool timeout_func () {
            int64 time = get_time_func ();
            var r = dispatch (time);
            if (r != null) {
                forwarded (r);
            }
            return false;
        }

        uint timeout_id = 0;

        /**
         * {@inheritDoc}
         */
        public override KeyEvent? filter_key_event (KeyEvent key) {
            KeyEvent? output = null;
            int64 time;
            if ((key.modifiers & ~ModifierType.RELEASE_MASK) == 0 &&
                (is_shift (key) || (0x20 <= key.code && key.code <= 0x7E))) {
                time = get_time_func ();
                int64 wait;
                output = queue (key, time, out wait);
                if (wait > 0) {
                    if (timeout_id > 0) {
                        Source.remove (timeout_id);
                    }
                    timeout_id = Timeout.add ((uint) wait, timeout_func);
                }
            } else {
                if ((key.modifiers & ModifierType.RELEASE_MASK) == 0) {
                    return key;
                }
                return null;
            }
            if (output == null) {
                output = dispatch (time);
            }
            return output;
        }

        /**
         * {@inheritDoc}
         */
        public override void reset () {
            pending.clear ();
        }
    }
}
