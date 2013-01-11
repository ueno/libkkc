/*
 * Copyright (C) 2012-2013 Daiki Ueno <ueno@unixuser.org>
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
    internal class SegmentList : Object {
        Gee.List<Segment> segments = new ArrayList<Segment> ();

        public void add_segments (Segment segment) {
            while (segment != null) {
                segments.add (segment);
                segment = segment.next;
            }
        }

        public int size {
            get {
                return segments.size;
            }
        }

        public void clear () {
            segments.clear ();
        }

        public new Segment @get (int index) {
            return segments.get (index);
        }

        public Iterator iterator () {
            return segments.iterator ();
        }

        public string to_string () {
            var builder = new StringBuilder ();
            foreach (var segment in segments) {
                builder.append (segment.output);
            }
            return builder.str;
        }
    }
}
