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
     * Object representing a candidate in dictionaries.
     */
    public class Candidate : Object {
        /**
         * Midasi word which generated this candidate.
         */
        public string midasi { get; private set; }

        /**
         * Flag to indicate whether this candidate is generated as a
         * result of okuri-ari conversion.
         */
        public bool okuri { get; private set; }

        /**
         * Base string value of the candidate.
         */
        public string text { get; set; }

        /**
         * Optional annotation text associated with the candidate.
         */
        public string? annotation { get; set; }

        /**
         * Output string shown instead of text.
         *
         * This is particularly useful to display a candidate of
         * numeric conversion.
         */
        public string output { get; set; }

        /**
         * Convert the candidate to string.
         * @return a string representing the candidate
         */
        public string to_string () {
            if (annotation != null) {
                return text + ";" + annotation;
            } else {
                return text;
            }
        }

        /**
         * Create a new Candidate.
         *
         * @param midasi midasi (index) word which generate the candidate
         * @param okuri whether the candidate is a result of okuri-ari conversion
         * @param text base string value of the candidate
         * @param annotation optional annotation text to the candidate
         * @param output optional output text used instead of text
         *
         * @return a new KkcCandidate
         */
        public Candidate (string midasi,
                          bool okuri,
                          string text,
                          string? annotation = null,
                          string? output = null)
        {
            this.midasi = midasi;
            this.okuri = okuri;
            this.text = text;
            this.annotation = annotation;
            this.output = output == null ? text : output;
        }
    }
}
