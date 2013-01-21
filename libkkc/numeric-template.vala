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
    class NumericTemplate : Object, Template {
        ArrayList<int> numerics = new ArrayList<int> ();

        public string source { get; construct set; }

        Regex regex;
        Regex ref_regex;

        public NumericTemplate (string source) {
            try {
                regex = new Regex ("[0-9]+");
            } catch (GLib.RegexError e) {
                assert_not_reached ();
            }

            try {
                ref_regex = new Regex ("#([0-9])");
            } catch (GLib.RegexError e) {
                assert_not_reached ();
            }

            extract_numerics (source);
        }

        void extract_numerics (string source) {
            MatchInfo info = null;
            int start_pos = 0;
            var builder = new StringBuilder ();
            while (true) {
                try {
                    if (!regex.match_full (source, -1, start_pos, 0, out info))
                        break;
                } catch (GLib.RegexError e) {
                    return_val_if_reached (source);
                }

                string numeric = info.fetch (0);
                int match_start_pos, match_end_pos;
                info.fetch_pos (0,
                                out match_start_pos,
                                out match_end_pos);
                numerics.add (int.parse (numeric));
                builder.append (source[start_pos:match_start_pos]);
                builder.append ("#");
                start_pos = match_end_pos;
            }
            builder.append (source[start_pos:source.length]);
            this.source = builder.str;
        }

        public string expand (string text) {
            var builder = new StringBuilder ();
            MatchInfo info = null;
            int start_pos = 0;
            for (int index = 0; index < numerics.size; index++) {
                try {
                    if (!ref_regex.match_full (text,
                                               -1,
                                               start_pos,
                                               0,
                                               out info))
                        break;
                } catch (GLib.RegexError e) {
                    return_val_if_reached (text);
                }
                            
                int match_start_pos, match_end_pos;
                info.fetch_pos (0,
                                out match_start_pos,
                                out match_end_pos);
                builder.append (text[start_pos:match_start_pos]);

                string type = info.fetch (1);
                switch (type[0]) {
                case '0':
                case '1':
                case '2':
                case '3':
                case '5':
                    builder.append (
                        RomKanaUtils.get_numeric (
                            numerics[index],
                            (NumericConversionType) (type[0] - '0')));
                    break;
                case '4':
                case '9':
                    // not supported yet
                    break;
                default:
                    warning ("unknown numeric conversion type: %s",
                             type);
                    break;
                }
                start_pos = match_end_pos;
            }
            builder.append (text[start_pos:text.length]);
            return builder.str;
        }
    }
}
