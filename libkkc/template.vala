/*
 * Copyright (C) 2011-2014 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2011-2014 Red Hat, Inc.
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
    public interface Template : Object {
        public abstract string source { get; construct set; }
        public abstract bool okuri { get; construct set; }
        public abstract string expand (string text);
    }

    public class SimpleTemplate : Object, Template {
        public string source { get; construct set; }
        public bool okuri { get; construct set; }

        public SimpleTemplate (string source) {
            this.source = source;
            this.okuri = false;
        }

        public string expand (string text) {
            return text;
        }
    }

    public class OkuriganaTemplate : Object, Template {
        public string source { get; construct set; }
        public bool okuri { get; construct set; }

        string? okurigana = null;

        public OkuriganaTemplate (string source, int pos) {
            assert (source.char_count () > 1);
            assert (0 < pos && pos < source.char_count ());

            var last_char_index = source.index_of_nth_char (pos);
            this.okurigana = source[last_char_index:source.length];
            string? prefix = RomKanaUtils.get_okurigana_prefix (this.okurigana);
            this.source = source[0:last_char_index] + prefix;
            this.okuri = true;
        }

        public string expand (string text) {
            if (okuri) {
                return text + okurigana;
            }
            return text;
        }
    }
}
