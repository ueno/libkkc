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
     * Helper class which can be used as a single user dictionary.
     *
     * It implements both SegmentDictionary and SentenceDictionary,
     * with write access.
     */
    public class UserDictionary : Object, Dictionary, SegmentDictionary, SentenceDictionary {
        UserSegmentDictionary segment_dict;
        UserSentenceDictionary sentence_dict;

        public UserDictionary (string basedir) throws GLib.Error {
            DirUtils.create_with_parents (Path.get_dirname (basedir), 448);
            segment_dict = new UserSegmentDictionary (
                Path.build_filename (basedir, "segment"));
            sentence_dict = new UserSentenceDictionary (
                Path.build_filename (basedir, "sentence"));
        }

        /**
         * {@inheritDoc}
         */
        public bool read_only {
            get {
                return false;
            }
        }

        /**
         * {@inheritDoc}
         */
        public void reload () throws GLib.Error {
            segment_dict.reload ();
            sentence_dict.reload ();
        }

        /**
         * {@inheritDoc}
         */
        public void save () throws GLib.Error {
            segment_dict.save ();
            sentence_dict.save ();
        }

        /**
         * {@inheritDoc}
         */
        public bool lookup_candidates (string midasi,
                                       bool okuri,
                                       out Candidate[] candidates) {
            return segment_dict.lookup_candidates (midasi,
                                                   okuri,
                                                   out candidates);
        }

        /**
         * {@inheritDoc}
         */
        public string[] complete (string midasi) {
            return segment_dict.complete (midasi);
        }

        /**
         * {@inheritDoc}
         */
        public bool select_candidate (Candidate candidate) {
            return segment_dict.select_candidate (candidate);
        }

        /**
         * {@inheritDoc}
         */
        public bool purge_candidate (Candidate candidate) {
            return segment_dict.purge_candidate (candidate);
        }

        /**
         * {@inheritDoc}
         */
        public bool lookup_constraint (string input,
                                        out int[] constraint) {
            return sentence_dict.lookup_constraint (input, out constraint);
        }

        /**
         * {@inheritDoc}
         */
        public bool lookup_phrase (string[] input,
                                   out string[] phrase) {
            return sentence_dict.lookup_phrase (input, out phrase);
        }

        /**
         * {@inheritDoc}
         */
        public bool select_segments (Segment[] input) {
            return sentence_dict.select_segments (input);
        }
    }
}
