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
     * Base interface of segment dictionaries.
     */
    public interface SegmentDictionary : Object, Dictionary {
        /**
         * Lookup candidates in the dictionary.
         *
         * @param midasi a midasi (title) string to lookup
         * @param okuri whether to search okuri-ari entries or
         * okuri-nasi entries
         * @param candidates output location of candidates
         *
         * @return `true` if found, `false` otherwise
         */
        public abstract bool lookup_candidates (string midasi,
                                                bool okuri,
                                                out Candidate[] candidates);

        /**
         * Return an array of strings which matches midasi.
         *
         * @param midasi a midasi (title) string to lookup
         *
         * @return an array of strings
         */
        public abstract string[] complete (string midasi);

        /**
         * Select a candidate in the dictionary.
         *
         * @param candidate an Candidate
         *
         * @return `true` if the dictionary is modified, `false` otherwise.
         */
        public virtual bool select_candidate (Candidate candidate) {
            // FIXME: throw an error when the dictionary is read only
            return false;
        }

        /**
         * Purge a candidate in the dictionary.
         *
         * @param candidate an Candidate
         *
         * @return `true` if the dictionary is modified, `false` otherwise.
         */
        public virtual bool purge_candidate (Candidate candidate) {
            // FIXME: throw an error when the dictionary is read only
            return false;
        }
    }

    /**
     * Null implementation of Dictionary.
     */
    public class EmptySegmentDictionary : Object, Dictionary, SegmentDictionary {
        /**
         * {@inheritDoc}
         */
        public void reload () throws GLib.Error {
        }

        /**
         * {@inheritDoc}
         */
        public bool lookup_candidates (string midasi,
                                       bool okuri,
                                       out Candidate[] candidates) {
            candidates = new Candidate[0];
            return false;
        }

        /**
         * {@inheritDoc}
         */
        public string[] complete (string midasi) {
            return new string[0];
        }

        /**
         * {@inheritDoc}
         */
        public bool read_only {
            get {
                return true;
            }
        }
    }
}
