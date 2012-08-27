/*
 * Copyright (C) 2012 Daiki Ueno <ueno@unixuser.org>
 * Copyright (C) 2012 Red Hat, Inc.
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
    public abstract class Decoder : Object {
        public abstract Segment[] decode (string input,
                                          int nbest,
                                          int[] constraints);

        public static Decoder? new_for_dict (Dict dict) throws Error {
            if (dict is TrigramDict) {
                return new TrigramDecoder (dict as TrigramDict);
            } else if (dict is BigramDict) {
                return new BigramDecoder (dict as BigramDict);
            } else {
                throw new Error.UNSUPPORTED_DICT (
                    "Unsupported dictionary type: %s",
                    dict.get_type ().name ());
            }
        }
    }
}
