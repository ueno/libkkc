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

enum ServerErrorCode {
    PARSE_ERROR = -32700,
    INVALID_REQUEST = -32600,
    METHOD_NOT_FOUND = -32601,
    INVALID_PARAMS = -32602,
    INTERNAL_ERROR = -32603
}

struct ServerError {
    ServerErrorCode code;
    string message;
    Json.Node? data;

    public void append (Json.Builder builder) {
        builder.begin_object ();
        builder.set_member_name ("code");
        builder.add_int_value (code);
        builder.set_member_name ("message");
        builder.add_string_value (message);
        if (data != null) {
            builder.set_member_name ("data");
            builder.add_value (data);
        }
        builder.end_object ();
    }
}

struct ServerResponse {
    Json.Node? result;
    ServerError? error;

    public void append (Json.Builder builder, Json.Node? id = null) {
        return_if_fail (result == null || error == null);

        builder.begin_object ();
        builder.set_member_name ("jsonrpc");
        builder.add_string_value ("2.0");
        if (result != null) {
            builder.set_member_name ("result");
            builder.add_value (result);
        }
        if (error != null) {
            builder.set_member_name ("error");
            error.append (builder);
        }
        if (id != null) {
            builder.set_member_name ("id");
            builder.add_value (id);
        }
        builder.end_object ();
    }
}

delegate ServerResponse CommandCallback (Json.Node? params);

class CommandHandler : Object {
    unowned CommandCallback cb;

    public CommandHandler (CommandCallback cb) {
        this.cb = cb;
    }

    public ServerResponse call (Json.Node? params) {
        return this.cb (params);
    }
}

class ServerRepl : Object, Repl {
    Kkc.Context context;
    Map<string, CommandHandler> command_handlers;

    construct {
        command_handlers = new HashMap<string, CommandHandler> ();
        command_handlers.set ("processKeyEvents",
                              new CommandHandler (do_process_key_events));
        command_handlers.set ("pollOutput",
                              new CommandHandler (do_poll_output));
        command_handlers.set ("getSegments",
                              new CommandHandler (do_get_segments));
        command_handlers.set ("getInput",
                              new CommandHandler (do_get_input));
        command_handlers.set ("reset",
                              new CommandHandler (do_reset));
    }

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

        context = new Kkc.Context (model);

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

        string? line;
        var generator = new Json.Generator ();
        var parser = new Json.Parser ();
        while ((line = stdin.read_line ()) != null) {
            try {
                parser.load_from_data (line);
            } catch (Error e) {
                var response = create_error_response (
                    ServerErrorCode.PARSE_ERROR,
                    e.message);
                var builder = new Json.Builder ();
                response.append (builder, null);
                generator.set_root (builder.get_root ());
                size_t length;
                stdout.printf ("%s\n", generator.to_data (out length));
                continue;
            }

            var root = parser.get_root ();
            if (root.get_node_type () != Json.NodeType.OBJECT) {
                var response = create_error_response (
                    ServerErrorCode.INVALID_REQUEST,
                    "request is not an object");
                var builder = new Json.Builder ();
                response.append (builder, null);
                generator.set_root (builder.get_root ());
                size_t length;
                stdout.printf ("%s\n", generator.to_data (out length));
                continue;
            }

            var object = root.get_object ();
            if (!object.has_member ("jsonrpc")) {
                var response = create_error_response (
                    ServerErrorCode.INVALID_REQUEST,
                    "missing jsonrpc member");
                var builder = new Json.Builder ();
                response.append (builder, null);
                generator.set_root (builder.get_root ());
                size_t length;
                stdout.printf ("%s\n", generator.to_data (out length));
                continue;
            }

            var jsonrpc = object.get_string_member ("jsonrpc");
            if (jsonrpc != "2.0") {
                var response = create_error_response (
                    ServerErrorCode.INVALID_REQUEST,
                    "unsupported jsonrpc version %s".printf (jsonrpc));
                var builder = new Json.Builder ();
                response.append (builder, null);
                generator.set_root (builder.get_root ());
                size_t length;
                stdout.printf ("%s\n", generator.to_data (out length));
                continue;
            }

            if (!object.has_member ("method")) {
                var response = create_error_response (
                    ServerErrorCode.INVALID_REQUEST,
                    "no method member");
                var builder = new Json.Builder ();
                response.append (builder, null);
                generator.set_root (builder.get_root ());
                size_t length;
                stdout.printf ("%s\n", generator.to_data (out length));
                continue;
            }
            var method = object.get_string_member ("method");
            if (!command_handlers.has_key (method)) {
                var response = create_error_response (
                    ServerErrorCode.METHOD_NOT_FOUND,
                    "no such method %s".printf (method));
                var builder = new Json.Builder ();
                response.append (builder, null);
                generator.set_root (builder.get_root ());
                size_t length;
                stdout.printf ("%s\n", generator.to_data (out length));
                continue;
            }

            Json.Node? params = null;
            if (object.has_member ("params")) {
                params = object.get_member ("params");
            }

            Json.Node? id = null;
            if (object.has_member ("id")) {
                id = object.get_member ("id");
            }

            var handler = command_handlers.get (method);
            var response = handler.call (params);
            var builder = new Json.Builder ();
            response.append (builder, id);
            generator.set_root (builder.get_root ());
            size_t length;
            stdout.printf ("%s\n", generator.to_data (out length));

            MainContext.default ().iteration (false);
        }
        return true;
    }

    ServerResponse create_error_response (ServerErrorCode code,
                                          string message,
                                          Json.Node? data = null)
    {
        var error = ServerError () {
            code = code,
            message = message,
            data = null
        };
        var response = ServerResponse () {
            result = null,
            error = error
        };
        return response;
    }

    ServerResponse do_process_key_events (Json.Node? params) {
        if (params == null || params.get_node_type () != Json.NodeType.ARRAY)
            return create_error_response (ServerErrorCode.INVALID_PARAMS,
                                          "params should be array");

        bool retval = false;
        var array = params.get_array ();
        for (var index = 0; index < array.get_length (); index++) {
            var str = array.get_string_element (index);
            Kkc.KeyEvent key;
            try {
                key = new Kkc.KeyEvent.from_string (str);
            } catch (Kkc.KeyEventFormatError e) {
                break;
            }
            if (context.process_key_event (key))
                retval = true;
        }

        var node = new Json.Node (Json.NodeType.VALUE);
        node.set_boolean (retval);
        var response = ServerResponse () {
            result = node,
            error = null
        };
        return response;
    }

    ServerResponse do_poll_output (Json.Node? params) {
        var output = context.poll_output ();
        var node = new Json.Node (Json.NodeType.VALUE);
        node.set_string (output);
        var response = ServerResponse () {
            result = node,
            error = null
        };
        return response;
    }

    ServerResponse do_get_segments (Json.Node? params) {
        var array = new Json.Array ();
        foreach (var segment in context.segments) {
            var object = new Json.Object ();
            object.set_string_member ("input", segment.input);
            object.set_string_member ("output", segment.output);
            array.add_object_element (object);
        }
        var node = new Json.Node (Json.NodeType.ARRAY);
        node.set_array (array);
        var response = ServerResponse () {
            result = node,
            error = null
        };
        return response;
    }

    ServerResponse do_get_input (Json.Node? params) {
        var node = new Json.Node (Json.NodeType.VALUE);
        node.set_string (context.input);
        var response = ServerResponse () {
            result = node,
            error = null
        };
        return response;
    }

    ServerResponse do_reset (Json.Node? params) {
        context.reset ();
        var node = new Json.Node (Json.NodeType.NULL);
        var response = ServerResponse () {
            result = node,
            error = null
        };
        return response;
    }
}
