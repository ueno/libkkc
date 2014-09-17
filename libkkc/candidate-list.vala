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
using Gee;

namespace Kkc {
    /**
     * Object representing a candidate list.
     */
    public class CandidateList : Object {
        ArrayList<Candidate> _candidates = new ArrayList<Candidate> ();

        // Don't make this a object property.  In some cases we need
        // to update the cursor position without property
        // notification.  See clear().
        int _cursor_pos;
        /**
         * Current cursor position.
         */
        public int cursor_pos {
            get {
                return _cursor_pos;
            }
            set {
                _cursor_pos = value;
            }
        }

        /**
         * Get the current candidate at the given index.
         *
         * @param index candidate position (-1 for the current cursor position)
         *
         * @return a Candidate
         */
        public new Candidate @get (int index = -1) {
            if (index < 0)
                index = _cursor_pos;
            assert (0 <= index && index < size);
            return _candidates.get (index);
        }

        /**
         * The number of candidate in the candidate list.
         */
        public int size {
            get {
                return _candidates.size;
            }
        }

        Map<string, Candidate> seen = new Gee.HashMap<string, Candidate> ();

        internal void clear () {
            bool is_populated = false;
            bool is_cursor_changed = false;
            seen.clear ();
            if (_candidates.size > 0) {
                _candidates.clear ();
                is_populated = true;
            }
            if (_cursor_pos >= 0) {
                _cursor_pos = -1;
                is_cursor_changed = true;
            }

            // To avoid race condition in the caller side where
            // monitoring the property changes, emit signals after
            // modifying _candidates and _cursor_pos.
            if (is_populated) {
                populated ();
            }
            if (is_cursor_changed) {
                notify_property ("cursor-pos");
            }
        }

        internal bool contains (Candidate candidate) {
            return candidate.output in seen;
        }

        internal bool add (Candidate candidate) {
            if (candidate.output in seen) {
                var c = seen.get (candidate.output);
                // If the given candidate has annotation and the
                // existing one doesn't, copy it.
                if (c.annotation == null && candidate.annotation != null)
                    c.annotation = candidate.annotation;
                return false;
            } else {
                _candidates.add (candidate);
                seen.set (candidate.output, candidate);
                return true;
            }
        }

        internal bool add_all (CandidateList other) {
            bool retval = false;
            foreach (var c in other._candidates) {
                if (add (c))
                    retval = true;
            }
            return retval;
        }

        internal Candidate[] to_array () {
            return _candidates.to_array ();
        }

        uint get_page_start_cursor_pos (uint pos) {
            return (pos / page_size) * page_size;
        }

        /**
         * Select a candidate in the current page.
         *
         * @param index_in_page cursor position in the page to select
         *
         * @return `true` if a candidate is selected, `false` otherwise
         */
        public bool select_at (uint index_in_page) {
            assert (index_in_page < page_size);
            var page_offset = get_page_start_cursor_pos (cursor_pos);
            if (page_offset + index_in_page < size) {
                _cursor_pos = (int) (page_offset + index_in_page);
                notify_property ("cursor-pos");
                select ();
                return true;
            }
            return false;
        }

        /**
         * Select the current candidate.
         */
        public void select () {
            Candidate candidate = this.get ();
            selected (candidate);
        }

        /**
         * Create a new CandidateList.
         *
         * @param page_start starting index of pagination
         * @param page_size page size
         * @param round whether to loop over the candidate list
         *
         * @return a new CandidateList
         */
        public CandidateList (uint page_start = 4,
                              uint page_size = 7,
                              bool round = false)
        {
            this.page_start = page_start;
            this.page_size = page_size;
            this.round = round;
        }

        /**
         * Select the first candidate.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public bool first () {
            if (_candidates.size > 0) {
                _cursor_pos = 0;
                notify_property ("cursor-pos");
                return true;
            }
            return false;
        }

        /**
         * Move cursor forward.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public virtual bool next () {
            if (cursor_pos < page_start) {
                return cursor_down ();
            } else {
                return page_down ();
            }
        }

        /**
         * Move cursor backward.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public virtual bool previous () {
            if (cursor_pos <= page_start) {
                return cursor_up ();
            } else {
                return page_up ();
            }
        }

        bool cursor_move (int step) {
            if (_candidates.is_empty || step == 0)
                return false;

            if (round) {
                var pos = (_cursor_pos + step) % _candidates.size;
                if (pos < 0)
                    pos += _candidates.size;
                _cursor_pos = pos;
                notify_property ("cursor-pos");
                return true;
            } else {
                var pos = _cursor_pos + step;
                if (0 <= pos && pos < _candidates.size) {
                    _cursor_pos = pos;
                    notify_property ("cursor-pos");
                    return true;
                }
            }

            return false;
        }

        /**
         * Move cursor to the previous candidate.
         *
         * @return `true` if cursor position has changed, `false` otherwise.
         */
        public bool cursor_up () {
            return cursor_move (-1);
        }

        /**
         * Move cursor to the next candidate.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public bool cursor_down () {
            return cursor_move (1);
        }

        bool page_move (int step) {
            if (_candidates.is_empty || step == 0)
                return false;

            if (round) {
                var pos = (_cursor_pos + page_size * step) % _candidates.size;
                if (pos < 0)
                    pos += _candidates.size;
                pos = get_page_start_cursor_pos (pos);
                if (pos != _cursor_pos) {
                    _cursor_pos = (int) pos;
                    notify_property ("cursor-pos");
                    return true;
                }
            } else {
                var pos = _cursor_pos + page_size * step;
                if (0 <= pos && pos < _candidates.size) {
                    pos = get_page_start_cursor_pos (pos);
                    if (pos != _cursor_pos) {
                        _cursor_pos = (int) pos;
                        notify_property ("cursor-pos");
                        return true;
                    }
                }
            }
            return false;
        }

        /**
         * Move cursor to the previous page.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public bool page_up () {
            return page_move (-1);
        }

        /**
         * Move cursor to the next page.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public bool page_down () {
            return page_move (1);
        }

        /**
         * Starting index of paging.
         */
        public uint page_start { get; set; }

        /**
         * Page size.
         */
        public uint page_size { get; set; }

        /**
         * Flag to indicate whether to loop over the candidates.
         */
        public bool round { get; set; }

        /**
         * Flag to indicate whether page (lookup table) is visible.
         */
        public bool page_visible {
            get {
                return _cursor_pos >= (int) page_start;
            }
        }

        /**
         * Signal emitted when candidates are filled and ready for traversal.
         */
        public signal void populated ();

        /**
         * Signal emitted when a candidate is selected.
         *
         * @param candidate selected candidate
         */
        public signal void selected (Candidate candidate);
    }
}
