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
namespace Kkc {
    /**
     * Base abstract class of dictionaries.
     */
    public abstract class Dict : Object {
        /**
         * Parse a line consisting of candidates separated by "/".
         *
         * @param line a line consisting of candidates
         * @return an array of Candidates
         */
        protected Candidate[] split_candidates (string midasi,
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
        protected string join_candidates (Candidate[] candidates) {
            var strv = new string[candidates.length];
            for (int i = 0; i < candidates.length; i++) {
                strv[i] = candidates[i].to_string ();
            }
            return "/" + string.joinv ("/", strv) + "/";
        }

        /**
         * Reload the dictionary.
         *
         * @throws GLib.Error when reading the dictionary failed.
         */
        public abstract void reload () throws GLib.Error;

        /**
         * Lookup candidates in the dictionary.
         *
         * @param midasi a midasi (title) string to lookup
         * @param okuri whether to search okuri-ari entries or
         * okuri-nasi entries
         *
         * @return an array of Candidate
         */
        public abstract Candidate[] lookup (string midasi, bool okuri = false);

        /**
         * Return an array of strings which matches midasi.
         *
         * @param midasi a midasi (title) string to lookup
         *
         * @return an array of strings
         */
        public abstract string[] complete (string midasi);

        /**
         * Flag to indicate whether the dictionary is read only.
         */
        public abstract bool read_only { get; }

        /**
         * Select a candidate in the dictionary.
         *
         * @param candidate an Candidate
         *
         * @return `true` if the dictionary is modified, `false` otherwise.
         */
        public virtual bool select_candidate (Candidate candidate)
        {
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
        public virtual bool purge_candidate (Candidate candidate)
        {
            // FIXME: throw an error when the dictionary is read only
            return false;
        }

        /**
         * Save the dictionary on disk.
         *
         * @throws GLib.Error if the dictionary cannot be saved.
         */
        public virtual void save () throws GLib.Error {
            // FIXME: throw an error when the dictionary is read only
        }
    }

    /**
     * Null implementation of Dict.
     */
    public class EmptyDict : Dict {
        /**
         * {@inheritDoc}
         */
        public override void reload () throws GLib.Error {
        }

        /**
         * {@inheritDoc}
         */
        public override Candidate[] lookup (string midasi, bool okuri = false) {
            return new Candidate[0];
        }

        /**
         * {@inheritDoc}
         */
        public override string[] complete (string midasi) {
            return new string[0];
        }

        /**
         * {@inheritDoc}
         */
        public override bool read_only {
            get {
                return true;
            }
        }
    }

    errordomain DictError {
        NOT_READABLE,
        MALFORMED_INPUT
    }
}
