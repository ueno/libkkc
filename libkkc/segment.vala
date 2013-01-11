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
    public class Segment : Object {
        string _input;
        public string input {
            get {
                return _input;
            }
        }

        string _output;
        public string output {
            get {
                return _output;
            }
        }

        public Segment? next;

        public Segment (string input, string output) {
            _input = input;
            _output = output;
        }
    }
}