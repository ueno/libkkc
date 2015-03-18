/*
 * Copyright (C) 2012-2014 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2012-2014 Red Hat, Inc.
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
static string opt_system_dictionary;
static string opt_user_dictionary;
static string opt_typing_rule;

static const OptionEntry[] model_entries = {
    { "model", 'm', 0, OptionArg.STRING, ref opt_model,
      N_("Language model"), null },
    { null }
};

static OptionGroup model_group;

static const OptionEntry[] decoder_entries = {
    { null }
};

static const OptionEntry[] context_entries = {
    { "system-dictionary", 's', 0, OptionArg.STRING, ref opt_system_dictionary,
      N_("Path to a system dictionary"), null },
    { "user-dictionary", 'u', 0, OptionArg.STRING, ref opt_user_dictionary,
      N_("Path to a user dictionary"), null },
    { "rule", 'r', 0, OptionArg.STRING, ref opt_typing_rule,
      N_("Typing rule (use \"?\" to list available rules)"), null },
    { null }
};

static void usage (string[] args, FileStream output) {
    var o = new OptionContext (_("COMMAND"));
    o.set_help_enabled (false);

    try {
        o.parse (ref args);
    } catch (Error e) {
    }

    o.set_description (
        _("""Commands:
  help         Shows this information
  decoder      Run decoder
  context      Run context
  server       Run server

  Use "%s COMMAND --help" to get help on each command.
""").printf (
              Path.get_basename (args[0])));
    var s = o.get_help (false, null);
    output.printf ("%s", s);
}

static int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Config.GETTEXT_PACKAGE);

    model_group = new OptionGroup ("model",
                                   N_("Model options:"),
                                   N_("Options specifying the language model"));
    model_group.add_entries (model_entries);

    Kkc.init ();

    var new_args = args[1:args.length];
    if (new_args.length < 1)
        new_args += "decoder";

    Environment.set_prgname ("%s %s".printf (args[0], new_args[0]));

    Repl repl;
    if (new_args[0] == "decoder")
        repl = new DecoderRepl ();
    else if (new_args[0] == "context")
        repl = new ContextRepl ();
    else if (new_args[0] == "server")
        repl = new ServerRepl ();
    else if (new_args[0] == "help") {
        usage (args, stdout);
        return 0;
    } else {
        stderr.printf ("Unknown command: %s\n", new_args[0]);
        usage (args, stderr);
        return 1;
    }

    try {
        repl.parse_arguments (new_args);
    } catch (Error e) {
        usage (args, stderr);
        return 1;
    }

    try {
        repl.run ();
    } catch (Error e) {
        return 1;
    }

    return 0;
}

interface Repl : Object {
    public abstract bool parse_arguments (string[] args) throws Error;
    public abstract bool run () throws Error;
}

class DecoderRepl : Object, Repl {
    public bool parse_arguments (string[] args) throws Error {
        var o = new OptionContext (
            _("- run decoder on the command line"));
        o.add_main_entries (decoder_entries, "libkkc");
        o.add_group ((owned) model_group);

        return o.parse (ref args);
    }

    public bool run () throws Error {
        Kkc.LanguageModel model;
        try {
            var name = opt_model == null ? "sorted3" : opt_model;
            model = Kkc.LanguageModel.load (name);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
            return false;
        }

        var decoder = Kkc.Decoder.create (model);

        stdout.printf ("Type kana sentence in the following form:\n" +
                       "SENTENCE [N-BEST [SEGMENT-BOUNDARY...]]\n");
        while (true) {
            stdout.printf (">> ");
            stdout.flush ();
            var line = stdin.read_line ();
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
}

class ContextRepl : Object, Repl {
    public bool parse_arguments (string[] args) throws Error {
        var o = new OptionContext (
            _("- run context on the command line"));
        o.add_main_entries (context_entries, "libkkc");
        o.add_group ((owned) model_group);

        return o.parse (ref args);
    }

    public bool run () throws Error {
        if (opt_typing_rule == "?") {
            var rules = Kkc.Rule.list ();
            foreach (var rule in rules) {
                stdout.printf ("%s - %s: %s\n",
                               rule.name,
                               rule.label,
                               rule.description);
            }
            return true;
        }

        Kkc.LanguageModel model;
        try {
            var name = opt_model == null ? "sorted3" : opt_model;
            model = Kkc.LanguageModel.load (name);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
            return false;
        }

        var context = new Kkc.Context (model);

        if (opt_user_dictionary != null) {
            try {
                context.dictionaries.add (
                    new Kkc.UserDictionary (opt_user_dictionary));
            } catch (GLib.Error e) {
                stderr.printf ("can't open user dictionary %s: %s",
                               opt_user_dictionary, e.message);
                return false;
            }
        }

        if (opt_system_dictionary == null)
            opt_system_dictionary = Path.build_filename (Config.DATADIR,
                                                         "skk", "SKK-JISYO.L");

        try {
            context.dictionaries.add (
                new Kkc.SystemSegmentDictionary (opt_system_dictionary));
        } catch (GLib.Error e) {
            stderr.printf ("can't open system dictionary %s: %s",
                           opt_system_dictionary, e.message);
            return false;
        }

        if (opt_typing_rule != null) {
            try {
                var metadata = Kkc.RuleMetadata.find (opt_typing_rule);
                context.typing_rule = new Kkc.Rule (metadata);
            } catch (Kkc.RuleParseError e) {
                stderr.printf ("can't load rule \"%s\": %s\n",
                               opt_typing_rule,
                               e.message);
                return false;
            }
        }

        stdout.printf ("Type key event sequence separated by space\n");
        while (true) {
            stdout.printf (">> ");
            stdout.flush ();
            var line = stdin.read_line ();
            if (line == null)
                break;
            try {
                context.process_key_events (line);
            } catch (Kkc.KeyEventFormatError e) {
                stderr.printf ("%s\n", e.message);
                continue;
            }
            print ("input: %s\n", context.input);
            print ("segments:\n");
            for (var i = 0; i < context.segments.size; i++) {
                print ("  input[%d]: %s\n", i, context.segments[i].input);
                print ("  output[%d]: %s\n", i, context.segments[i].output);
            }
            print ("output: %s\n", context.poll_output ());
        }
        return true;
    }
}

class ServerRepl : Object, Repl {
    public bool parse_arguments (string[] args) throws Error {
        var o = new OptionContext (
            _("- run server on the command line"));
        o.add_main_entries (context_entries, "libkkc");
        o.add_group ((owned) model_group);

        return o.parse (ref args);
    }

    public bool run () throws Error {
        if (opt_typing_rule == "?") {
            var rules = Kkc.Rule.list ();
            foreach (var rule in rules) {
                stdout.printf ("%s - %s: %s\n",
                               rule.name,
                               rule.label,
                               rule.description);
            }
            return true;
        }

        Kkc.LanguageModel model;
        try {
            var name = opt_model == null ? "sorted3" : opt_model;
            model = Kkc.LanguageModel.load (name);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
            return false;
        }

        var dictionaries = new Kkc.DictionaryList ();
        if (opt_user_dictionary != null) {
            try {
                dictionaries.add (
                    new Kkc.UserDictionary (opt_user_dictionary));
            } catch (GLib.Error e) {
                stderr.printf ("can't open user dictionary %s: %s",
                               opt_user_dictionary, e.message);
                return false;
            }
        }

        if (opt_system_dictionary == null)
            opt_system_dictionary = Path.build_filename (Config.DATADIR,
                                                         "skk", "SKK-JISYO.L");

        try {
            dictionaries.add (
                new Kkc.SystemSegmentDictionary (opt_system_dictionary));
        } catch (GLib.Error e) {
            stderr.printf ("can't open system dictionary %s: %s",
                           opt_system_dictionary, e.message);
            return false;
        }

        Kkc.Rule? typing_rule = null;
        if (opt_typing_rule != null) {
            try {
                var metadata = Kkc.RuleMetadata.find (opt_typing_rule);
                typing_rule = new Kkc.Rule (metadata);
            } catch (Kkc.RuleParseError e) {
                stderr.printf ("can't load rule \"%s\": %s\n",
                               opt_typing_rule,
                               e.message);
                return false;
            }
        }

        var connection = Bus.get_sync (BusType.SESSION);
        var server = new Kkc.DBusServer (connection,
                                         model, dictionaries, typing_rule);
        var loop = new MainLoop (null, true);
        loop.run ();
        return true;
    }
}
