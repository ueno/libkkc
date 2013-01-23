/*
 * Copyright (C) 2012-2013 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2012-2013 Red Hat, Inc.
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
    public class SegmentList : Object {
        Gee.List<Segment> segments = new ArrayList<Segment> ();

        int _cursor_pos = -1;
        public int cursor_pos {
            get {
                return _cursor_pos;
            }
            set {
                _cursor_pos = value;
            }
        }

        public int size {
            get {
                return segments.size;
            }
        }

        ArrayList<int> input_offsets = new ArrayList<int> ();

        public void clear () {
            segments.clear ();
            input_offsets.clear ();
            cursor_pos = -1;
        }

        public new Segment @get (int index) {
            return segments.get (index);
        }

        public void set_segments (Segment segment) {
            segments.clear ();
            input_offsets.clear ();
            int offset = 0;
            input_offsets.add (0);
            while (segment != null) {
                segments.add (segment);
                offset += segment.input.char_count ();
                if (segment.next != null)
                    input_offsets.add (offset);
                segment = segment.next;
            }
        }

        public int get_input_offset (int index) {
            if (index >= 0 && index < input_offsets.size)
                return input_offsets[index];
            return -1;
        }

        public bool first_segment () {
            if (segments.size > 0) {
                cursor_pos = 0;
                return true;
            }
            return false;
        }

        public void next_segment () {
            if (cursor_pos == -1)
                return;
            cursor_pos = (cursor_pos + 1).clamp (0, size - 1);
        }

        public void previous_segment () {
            if (cursor_pos == -1)
                return;
            cursor_pos = (cursor_pos - 1).clamp (0, size - 1);
        }

        public string get_output () {
            var builder = new StringBuilder ();
            foreach (var segment in segments) {
                builder.append (segment.output);
            }
            return builder.str;
        }

        public string get_input () {
            var builder = new StringBuilder ();
            foreach (var segment in segments) {
                builder.append (segment.input);
            }
            return builder.str;
        }

        // Extract phrase at other.cursor_pos.
        internal Gee.List<Segment> extract_phrase (SegmentList other)
        {
            assert (other.cursor_pos >= 0);

            var cursor_offset = other.get_input_offset (
                other.cursor_pos);
            var cursor_length = other.get (
                other.cursor_pos).output.char_count ();
            var cursor_end_offset = cursor_offset + cursor_length;

            var start = -1;
            for (var i = other.cursor_pos; i >= 0; i--) {
                for (var j = 0; j <= cursor_end_offset; j++) {
                    if (other.get_input_offset (i)
                        == this.get_input_offset (j)) {
                        start = i;
                        break;
                    }
                }
                if (start >= 0)
                    break;
            }
            if (start < 0)
                start = 0;

            var stop = -1;
            for (var i = other.cursor_pos + 1; i < other.size; i++) {
                for (var j = 0; j < this.size; j++) {
                    if (other.get_input_offset (i)
                        == this.get_input_offset (j)) {
                        stop = i;
                        break;
                    }
                }
                if (stop >= 0)
                    break;
            }
            if (stop < 0)
                stop = this.size;

            return other.segments.slice (start, stop);
        }
    }
}
