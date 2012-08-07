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

static string opt_dict = null;

static const OptionEntry[] options = {
    { "dict", 'd', 0, OptionArg.STRING, ref opt_dict,
      N_("Dictionary name"), null },
    { null }
};

static int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Config.GETTEXT_PACKAGE);

    var option_context = new OptionContext (
        _("- perform kana-kanji conversion on the command line"));
    option_context.add_main_entries (options, "libkkc");
    try {
        option_context.parse (ref args);
    } catch (OptionError e) {
        stderr.printf ("%s\n", e.message);
        return 1;
    }

    Kkc.init ();

    Kkc.Dict dict = Kkc.Dict.load (opt_dict == null ? "sorted3" : opt_dict);
    Kkc.Decoder decoder = Kkc.Decoder.new_for_dict (dict);

    var repl = new Repl (decoder);
    if (!repl.run ())
        return 1;
    return 0;
}

class Repl : Object {
    Kkc.Decoder decoder;

    public bool run () {
        string? line;
        stdout.printf ("Type kana sentence in the following form:\n" +
                       "SENTENCE [N-BEST [SEGMENT-BOUNDARY...]]\n");
        while (true) {
            stdout.printf (">> ");
            stdout.flush ();
            line = stdin.read_line ();
            if (line == null)
                break;
            var nbest = 1;
            var strv = line.strip ().split (" ");
            if (strv.length == 0)
                continue;
            if (strv.length >= 2)
                nbest = int.parse (strv[1]);
            int[] constraints = new int[strv.length > 2 ? strv.length - 2 : 0];
            for (var i = 0; i < constraints.length; i++) {
                constraints[i] = int.parse (strv[2 + i]);
            }
            var segments = decoder.decode (strv[0], nbest, constraints);
            for (var index = 0; index < segments.length; index++) {
                stdout.printf ("%d: ", index);
                var segment = segments[index];
                while (segment != null) {
                    stdout.printf ("<%s/%s>", segment.output, segment.input);
                    segment = segment.next;
                }
                stdout.printf ("\n");
            }
        }
        return true;
    }

    public Repl (Kkc.Decoder decoder) {
        this.decoder = decoder;
    }
}
