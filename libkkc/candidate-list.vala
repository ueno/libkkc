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
     * Object representing a candidate list.
     */
    public class CandidateList : Object {
        ArrayList<Candidate> _candidates = new ArrayList<Candidate> ();

        int _cursor_pos;
        /**
         * Current cursor position.
         */
        public int cursor_pos {
            get {
                return _cursor_pos;
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

        Set<string> seen = new HashSet<string> ();

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
            // to avoid race condition, emit signals after modifying
            // _candidates and _cursor_pos
            if (is_populated) {
                populated ();
            }
            if (is_cursor_changed) {
                notify_property ("cursor-pos");
            }
        }

        internal void add_candidates (Candidate[] array) {
            foreach (var c in array) {
                if (!(c.output in seen)) {
                    _candidates.add (c);
                    seen.add (c.output);
                }
            }
        }

        internal void add_candidates_end () {
            populated ();
        }

        /**
         * Return cursor position of the beginning of the current page.
         *
         * @return cursor position
         */
        uint get_page_start_cursor_pos () {
            var pages = (cursor_pos - page_start) / page_size;
            return pages * page_size + page_start;
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
            var page_offset = get_page_start_cursor_pos ();
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

        public CandidateList (uint page_start = 4,
                                    uint page_size = 7,
                                    bool round = false)
        {
            _page_start = (int) page_start;
            _page_size = (int) page_size;
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

        /**
         * Move cursor to the previous candidate.
         *
         * @return `true` if cursor position has changed, `false` otherwise.
         */
        public bool cursor_up () {
            if (round) {
                _cursor_pos = (_cursor_pos - 1) % _candidates.size;
                if (_cursor_pos < 0)
                    _cursor_pos += _candidates.size;
                notify_property ("cursor-pos");
                return true;
            } else {
                assert (_cursor_pos >= 0);
                if (_cursor_pos > 0) {
                    _cursor_pos--;
                    notify_property ("cursor-pos");
                    return true;
                }
            }
            return false;
        }

        /**
         * Move cursor to the next candidate.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public bool cursor_down () {
            if (round) {
                _cursor_pos = (_cursor_pos + 1) % _candidates.size;
                if (_cursor_pos < 0)
                    _cursor_pos += _candidates.size;
                notify_property ("cursor-pos");
                return true;
            } else {
                assert (_cursor_pos >= 0);
                if (_cursor_pos < _candidates.size - 1) {
                    _cursor_pos++;
                    notify_property ("cursor-pos");
                    return true;
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
            if (round) {
                _cursor_pos = (_cursor_pos - _page_size) % _candidates.size;
                if (_cursor_pos < 0)
                    _cursor_pos += _candidates.size;
                _cursor_pos = (int) get_page_start_cursor_pos ();
                return true;
            } else {
                assert (_cursor_pos >= 0);
                if (_cursor_pos >= _page_start + _page_size) {
                    _cursor_pos -= _page_size;
                    _cursor_pos = (int) get_page_start_cursor_pos ();
                    notify_property ("cursor-pos");
                    return true;
                }
            }
            return false;
        }

        /**
         * Move cursor to the next page.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public bool page_down () {
            if (round) {
                _cursor_pos = (_cursor_pos + _page_size) % _candidates.size;
                if (_cursor_pos < 0)
                    _cursor_pos += _candidates.size;
                _cursor_pos = (int) get_page_start_cursor_pos ();
                return true;
            } else {
                assert (_cursor_pos >= 0);
                if (_cursor_pos >= _page_start &&
                    _cursor_pos < _candidates.size - _page_size) {
                    _cursor_pos += _page_size;
                    _cursor_pos = (int) get_page_start_cursor_pos ();
                    notify_property ("cursor-pos");
                    return true;
                }
            }
            return false;
        }

        int _page_start;
        /**
         * Starting index of paging.
         */
        public uint page_start {
            get {
                return (uint) _page_start;
            }
            set {
                _page_start = (int) value;
            }
        }

        int _page_size;
        /**
         * Page size.
         */
        public uint page_size {
            get {
                return (uint) _page_size;
            }
            set {
                _page_size = (int) value;
            }
        }

        /**
         * Flag to indicate whether to loop over the candidates.
         */
        public bool round { get; set; }

        /**
         * Flag to indicate whether page (lookup table) is visible.
         */
        public bool page_visible {
            get {
                return _cursor_pos >= _page_start;
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
