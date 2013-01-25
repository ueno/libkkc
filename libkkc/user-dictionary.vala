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

        public Candidate[] lookup (string midasi, bool okuri = false) {
            return segment_dict.lookup (midasi, okuri);
        }

        public string[] complete (string midasi) {
            return segment_dict.complete (midasi);
        }

        public bool select_candidate (Candidate candidate) {
            return segment_dict.select_candidate (candidate);
        }

        public bool purge_candidate (Candidate candidate) {
            return segment_dict.purge_candidate (candidate);
        }

        public bool lookup_constraints (string input,
                                        out int[] constraints) {
            return sentence_dict.lookup_constraints (input, out constraints);
        }

        public bool lookup_phrase (string[] input,
                                   out string[] phrase) {
            return sentence_dict.lookup_phrase (input, out phrase);
        }

        public bool select_segments (Segment[] input) {
            return sentence_dict.select_segments (input);
        }
    }
}
