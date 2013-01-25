/*
 * Copyright (C) 2012-2013 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2012-2013 Red Hat, Inc.
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

static string opt_model = null;
static bool opt_im = false;

static const OptionEntry[] options = {
    { "model", 'm', 0, OptionArg.STRING, ref opt_model,
      N_("Language model"), null },
    { "im", '\0', 0, OptionArg.NONE, ref opt_im,
      N_("Run in input method testing mode"), null },
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

	Kkc.LanguageModel model;
	try {
		model = Kkc.LanguageModel.load (opt_model == null ? "sorted3" : opt_model);
	} catch (Kkc.LanguageModelError e) {
		stderr.printf ("%s\n", e.message);
		return 1;
	}

	Repl repl;
	if (opt_im) {
		var context = new Kkc.Context (model);
		repl = new RomKanaRepl (context);
	} else {
		var decoder = Kkc.Decoder.create (model);
		repl = new DecoderRepl (decoder);
	}
    if (!repl.run ())
        return 1;
    return 0;
}

interface Repl : Object {
    public abstract bool run ();	
}

class RomKanaRepl : Object, Repl {
    Kkc.Context context;
    public bool run () {
        string? line;
        while ((line = stdin.read_line ()) != null) {
            context.process_key_events (line);
            var input = context.input;
            var output = context.poll_output ();
            stdout.printf (
                "{ \"input\": \"%s\", " +
                "\"output\": \"%s\" }\n",
                input.replace ("\"", "\\\""),
                output.replace ("\"", "\\\""));
            context.reset ();
            context.clear_output ();
        }
        return true;
    }

    public RomKanaRepl (Kkc.Context context) {
        this.context = context;
    }
}

class DecoderRepl : Object, Repl {
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
    public DecoderRepl (Kkc.Decoder decoder) {
        this.decoder = decoder;
    }
}

