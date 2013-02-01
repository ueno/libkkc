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
namespace Kkc {
    class DictionaryUtils : Object {
        /**
         * Parse a line consisting of candidates separated by "/".
         *
         * @param line a line consisting of candidates
         * @return an array of Candidates
         */
        public static Candidate[] split_candidates (string midasi,
                                                    bool okuri,
                                                    string line)
        {
            var strv = line.strip ().slice (1, -1).split ("/");
            Candidate[] candidates = new Candidate[strv.length];
            for (int i = 0; i < strv.length; i++) {
                var text_annotation = strv[i].split (";", 2);
                string text, annotation;
                if (text_annotation.length == 2) {
                    text = text_annotation[0];
                    annotation = text_annotation[1];
                } else {
                    text = strv[i];
                    annotation = null;
                }
                candidates[i] = new Candidate (midasi,
                                               okuri,
                                               text,
                                               annotation);
            }
            return candidates;
        }

        /**
         * Format an array of Candidates to be saved in a dictionary file.
         *
         * @param candidates an array of Candidate
         * @return a string
         */
        public static string join_candidates (Candidate[] candidates) {
            var strv = new string[candidates.length];
            for (int i = 0; i < candidates.length; i++) {
                strv[i] = candidates[i].to_string ();
            }
            return "/" + string.joinv ("/", strv) + "/";
        }
    }

    /**
     * Base interface of dictionaries.
     */
    public interface Dictionary : Object {
        /**
         * Flag to indicate whether the dictionary is read only.
         */
        public abstract bool read_only { get; }

        /**
         * Reload the dictionary.
         *
         * @throws GLib.Error when reading the dictionary failed.
         */
        public abstract void reload () throws GLib.Error;

        /**
         * Save the dictionary on disk.
         *
         * @throws GLib.Error if the dictionary cannot be saved.
         */
        public virtual void save () throws GLib.Error {
            // FIXME: throw an error when the dictionary is read only
        }
    }

    public errordomain DictionaryError {
        NOT_READABLE,
        MALFORMED_INPUT
    }
}
