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
     * Base abstract class of candidate list.
     */
    public abstract class CandidateList : Object {
        /**
         * Current cursor position.
         */
        public abstract int cursor_pos { get; }

        /**
         * Get the current candidate at the given index.
         *
         * @param index candidate position (-1 for the current cursor position)
         *
         * @return a Candidate
         */
        public abstract new Candidate @get (int index = -1);

        /**
         * The number of candidate in the candidate list.
         */
        public abstract int size { get; }

        internal abstract void clear ();

        internal abstract void add_candidates (Candidate[] array);

        internal abstract void add_candidates_end ();

        /**
         * Move cursor to the previous candidate.
         *
         * @return `true` if cursor position has changed, `false` otherwise.
         */
        public abstract bool cursor_up ();

        /**
         * Move cursor to the next candidate.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public abstract bool cursor_down ();

        /**
         * Move cursor to the previous page.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public abstract bool page_up ();

        /**
         * Move cursor to the next page.
         *
         * @return `true` if cursor position has changed, `false` otherwise
         */
        public abstract bool page_down ();

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
         * Starting index of paging.
         */
        public abstract uint page_start { get; set; }

        /**
         * Page size.
         */
        public abstract uint page_size { get; set; }

        /**
         * Flag to indicate whether page (lookup table) is visible.
         */
        public abstract bool page_visible { get; }

        /**
         * Return cursor position of the beginning of the current page.
         *
         * @return cursor position
         */
        protected uint get_page_start_cursor_pos () {
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
        public abstract bool select_at (uint index_in_page);

        /**
         * Select the current candidate.
         */
        public abstract void select ();

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

    class SimpleCandidateList : CandidateList {
        ArrayList<Candidate> _candidates = new ArrayList<Candidate> ();

        int _cursor_pos;
        public override int cursor_pos {
            get {
                return _cursor_pos;
            }
        }

        public override Candidate @get (int index = -1) {
            if (index < 0)
                index = _cursor_pos;
            assert (0 <= index && index < size);
            return _candidates.get (index);
        }

        public override int size {
            get {
                return _candidates.size;
            }
        }

        Set<string> seen = new HashSet<string> ();

        internal override void clear () {
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

        internal override void add_candidates (Candidate[] array) {
            foreach (var c in array) {
                if (!(c.output in seen)) {
                    _candidates.add (c);
                    seen.add (c.output);
                }
            }
        }

        internal override void add_candidates_end () {
            if (_candidates.size > 0) {
                _cursor_pos = 0;
            }
            populated ();
            notify_property ("cursor-pos");
        }

        public override bool select_at (uint index_in_page) {
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

        public override void select () {
            Candidate candidate = this.get ();
            selected (candidate);
        }

        public SimpleCandidateList (uint page_start = 4, uint page_size = 7) {
            _page_start = (int) page_start;
            _page_size = (int) page_size;
        }

        public override bool cursor_up () {
            assert (_cursor_pos >= 0);
            if (_cursor_pos > 0) {
                _cursor_pos--;
                notify_property ("cursor-pos");
                return true;
            }
            return false;
        }

        public override bool cursor_down () {
            assert (_cursor_pos >= 0);
            if (_cursor_pos < _candidates.size - 1) {
                _cursor_pos++;
                notify_property ("cursor-pos");
                return true;
            }
            return false;
        }

        public override bool page_up () {
            assert (_cursor_pos >= 0);
            if (_cursor_pos >= _page_start + _page_size) {
                _cursor_pos -= _page_size;
                _cursor_pos = (int) get_page_start_cursor_pos ();
                notify_property ("cursor-pos");
                return true;
            }
            return false;
        }

        public override bool page_down () {
            assert (_cursor_pos >= 0);
            if (_cursor_pos >= _page_start &&
                _cursor_pos < _candidates.size - _page_size) {
                _cursor_pos += _page_size;
                _cursor_pos = (int) get_page_start_cursor_pos ();
                notify_property ("cursor-pos");
                return true;
            }
            return false;
        }

        int _page_start;
        public override uint page_start {
            get {
                return (uint) _page_start;
            }
            set {
                _page_start = (int) value;
            }
        }

        int _page_size;
        public override uint page_size {
            get {
                return (uint) _page_size;
            }
            set {
                _page_size = (int) value;
            }
        }

        public override bool page_visible {
            get {
                return _cursor_pos >= _page_start;
            }
        }
    }

    class ProxyCandidateList : CandidateList {
        CandidateList _candidates;
        
        void notify_cursor_pos_cb (Object s, ParamSpec? p) {
            notify_property ("cursor-pos");
        }

        void populated_cb () {
            populated ();
        }

        void selected_cb (Candidate c) {
            selected (c);
        }

        public CandidateList candidates {
            get {
                return _candidates;
            }
            set {
                if (_candidates != value) {
                    // _candidates is initially null
                    if (_candidates != null) {
                        _candidates.notify["cursor-pos"].disconnect (
                            notify_cursor_pos_cb);
                        _candidates.populated.disconnect (populated_cb);
                        _candidates.selected.disconnect (selected_cb);
                    }
                    _candidates = value;
                    _candidates.notify["cursor-pos"].connect (
                        notify_cursor_pos_cb);
                    _candidates.populated.connect (populated_cb);
                    _candidates.selected.connect (selected_cb);
                    populated ();
                }
            }
        }

        public override int cursor_pos {
            get {
                return candidates.cursor_pos;
            }
        }

        public override Candidate @get (int index = -1) {
            return candidates.get (index);
        }

        public override int size {
            get {
                return candidates.size;
            }
        }

        internal override void clear () {
            candidates.clear ();
        }

        internal override void add_candidates (Candidate[] array) {
            candidates.add_candidates (array);
        }

        internal override void add_candidates_end () {
            candidates.add_candidates_end ();
        }

        public override bool select_at (uint index_in_page) {
            return candidates.select_at (index_in_page);
        }

        public override void select () {
            candidates.select ();
        }

        public ProxyCandidateList (CandidateList candidates) {
            this.candidates = candidates;
        }

        public override bool cursor_up () {
            return candidates.cursor_up ();
        }

        public override bool cursor_down () {
            return candidates.cursor_down ();
        }

        public override bool page_up () {
            return candidates.page_up ();
        }

        public override bool page_down () {
            return candidates.page_down ();
        }

        public override uint page_start {
            get {
                return candidates.page_start;
            }
            set {
                candidates.page_start = value;
            }
        }

        public override uint page_size {
            get {
                return candidates.page_size;
            }
            set {
                candidates.page_size = value;
            }
        }

        public override bool page_visible {
            get {
                return candidates.page_visible;
            }
        }
    }
}
