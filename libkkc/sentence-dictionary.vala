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
     * Base interface of sentence dictionaries.
     */
    public interface SentenceDictionary : Object, Dictionary {
        /**
         * Lookup constraint.
         *
         * @param input input string to lookup
         * @param constraint output location of constraint
         *
         * @return `true` if found, `false` otherwise
         */
        public abstract bool lookup_constraint (string input,
                                                 out int[] constraint);

        /**
         * Lookup phrase.
         *
         * @param input input sequence to lookup
         * @param phrase output location of phrase
         *
         * @return `true` if found, `false` otherwise
         */
        public abstract bool lookup_phrase (string[] input,
                                            out string[] phrase);

        public virtual bool select_segments (Segment[] input) {
            // FIXME: throw an error when the dictionary is read only
            return false;
        }
    }
}