/*
 * Copyright (C) 2011-2015 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2011-2015 Red Hat, Inc.
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

namespace Kkc
{
    namespace DBusUtils {
        internal static void send_property_change (DBusConnection connection,
                                                   string object_path,
                                                   string interface_name,
                                                   string name,
                                                   Variant value)
        {
            var builder = new VariantBuilder (VariantType.ARRAY);
            var invalid_builder = new VariantBuilder (new VariantType ("as"));

            builder.add ("{sv}", name, value);

            try {
                connection.emit_signal (null,
                                        object_path,
                                        "org.freedesktop.DBus.Properties",
                                        "PropertiesChanged",
                                        new Variant ("(sa{sv}as)",
                                                     interface_name,
                                                     builder,
                                                     invalid_builder)
                    );
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }
        }
    }

    [DBus (name = "org.du_a.Kkc.CandidateList")]
    public class DBusCandidateList : Object
    {
        DBusConnection connection;
        string object_path;
        Kkc.CandidateList candidates;

        public DBusCandidateList (DBusConnection connection,
                                  string object_path,
                                  Kkc.CandidateList candidates)
        {
            this.connection = connection;
            this.object_path = object_path;
            this.candidates = candidates;
            this.candidates.populated.connect (() => {
                    this.populated ();
                });
            this.candidates.selected.connect ((candidate) => {
                    this.selected (candidate.midasi,
                                   candidate.okuri,
                                   candidate.text,
                                   candidate.annotation ?? "");
                });
            this.candidates.notify["cursor-pos"].connect ((p) => {
                    DBusUtils.send_property_change (
                        connection,
                        object_path,
                        "org.du_a.Kkc.CandidateList",
                        "CursorPos",
                        new Variant.int32 (cursor_pos));
                });
            register ();
        }

        ~DBusCandidateList () {
            unregister ();
        }

        public int cursor_pos {
            get {
                return this.candidates.cursor_pos;
            }
        }

        public int size {
            get {
                return this.candidates.size;
            }
        }

        public bool select_at (uint index_in_page) {
            return this.candidates.select_at (index_in_page);
        }

        public void select () {
            this.candidates.select ();
        }

        public bool first () {
            return this.candidates.first ();
        }

        public bool next () {
            return this.candidates.next ();
        }

        public bool previous () {
            return this.candidates.previous ();
        }

        public bool cursor_up () {
            return this.candidates.cursor_up ();
        }

        public bool cursor_down () {
            return this.candidates.cursor_down ();
        }

        public bool page_up () {
            return this.candidates.page_up ();
        }

        public bool page_down () {
            return this.candidates.page_down ();
        }

        public uint page_start {
            get {
                return this.candidates.page_start;
            }
        }

        public uint page_size {
            get {
                return this.candidates.page_size;
            }
        }

        public bool round {
            get {
                return this.candidates.round;
            }
        }

        public bool page_visible {
            get {
                return this.candidates.page_visible;
            }
        }

        public signal void populated ();

        public signal void selected (string midasi, bool okuri,
                                     string text, string annotation);

        public new void @get (int index, out string midasi, out bool okuri,
                              out string text, out string annotation)
        {
            var candidate = this.candidates.get (index);
            midasi = candidate.midasi;
            okuri = candidate.okuri;
            text = candidate.text;
            annotation = candidate.annotation ?? "";
        }

        uint register_id = 0;

        void register () {
            try {
                register_id = connection.register_object (object_path, this);
            } catch (IOError e) {
                error ("Could not register D-Bus object at %s: %s",
                       object_path, e.message);
            }
        }

        internal void unregister () {
            if (register_id > 0) {
                connection.unregister_object (register_id);
                register_id = 0;
            }
        }
    }

    [DBus (name = "org.du_a.Kkc.SegmentList")]
    public class DBusSegmentList : Object
    {
        DBusConnection connection;
        string object_path;
        Kkc.SegmentList segments;

        public DBusSegmentList (DBusConnection connection,
                                string object_path,
                                Kkc.SegmentList segments)
        {
            this.connection = connection;
            this.object_path = object_path;
            this.segments = segments;
            this.segments.notify["cursor-pos"].connect ((p) => {
                    DBusUtils.send_property_change (
                        connection,
                        object_path,
                        "org.du_a.Kkc.SegmentList",
                        "CursorPos",
                        new Variant.int32 (cursor_pos));
                });
            register ();
        }

        ~DBusSegmentList () {
            unregister ();
        }

        public int cursor_pos {
            get {
                return this.segments.cursor_pos;
            }
        }

        public int size {
            get {
                return this.segments.size;
            }
        }

        public new void @get (int index, out string input, out string output) {
            var segment = this.segments.get (index);
            input = segment.input;
            output = segment.output;
        }

        public bool first_segment () {
            return this.segments.first_segment ();
        }

        public bool last_segment () {
            return this.segments.last_segment ();
        }

        public void next_segment () {
            this.segments.next_segment ();
        }

        public void previous_segment () {
            this.segments.previous_segment ();
        }

        public string get_output () {
            return this.segments.get_output ();
        }

        public string get_input () {
            return this.segments.get_input ();
        }

        uint register_id = 0;

        void register () {
            try {
                register_id = connection.register_object (object_path, this);
            } catch (IOError e) {
                error ("Could not register D-Bus object at %s: %s",
                       object_path, e.message);
            }
        }

        internal void unregister () {
            if (register_id > 0) {
                connection.unregister_object (register_id);
                register_id = 0;
            }
        }
    }

    [DBus (name = "org.du_a.Kkc.Context")]
    public class DBusContext : Object
    {
        DBusConnection connection;
        string object_path;
        Kkc.Context context;
        DBusCandidateList candidates;
        DBusSegmentList segments;

        public DBusContext (DBusConnection connection,
                            string object_path,
                            Kkc.Context context)
        {
            this.connection = connection;
            this.object_path = object_path;
            this.context = context;
            this.candidates = new DBusCandidateList (
                connection,
                "%s/CandidateList".printf (object_path),
                context.candidates);
            this.segments = new DBusSegmentList (
                connection,
                "%s/SegmentList".printf (object_path),
                context.segments);
            context.notify["input"].connect ((p) => {
                    DBusUtils.send_property_change (
                        connection,
                        object_path,
                        "org.du_a.Kkc.Context",
                        "Input",
                        new Variant.string (input));
                });
            context.notify["input_cursor_pos"].connect ((p) => {
                    DBusUtils.send_property_change (
                        connection,
                        object_path,
                        "org.du_a.Kkc.Context",
                        "InputCursorPos",
                        new Variant.int32 ((int32) input_cursor_pos));
                });
            register ();
        }

        ~DBusContext () {
            unregister ();
        }

        public string input {
            owned get {
                return this.context.input;
            }
        }

        public int input_cursor_pos {
            get {
                return this.context.input_cursor_pos;
            }
        }

        public uint input_mode {
            get {
                return (uint) this.context.input_mode;
            }
            set {
                this.context.input_mode = (InputMode) value;
            }
        }

        public uint punctuation_style {
            get {
                return (uint) this.context.punctuation_style;
            }
            set {
                this.context.punctuation_style = (PunctuationStyle) value;
            }
        }

        public bool auto_correct {
            get {
                return this.context.auto_correct;
            }
            set {
                this.context.auto_correct = value;
            }
        }

        public bool process_key_event (uint keyval, uint keycode,
                                       uint modifiers)
        {
            var event = new Kkc.KeyEvent (keyval, keycode,
                                          (ModifierType) modifiers);
            return this.context.process_key_event (event);
        }

        public bool process_command_event (string command) {
            return this.context.process_command_event (command);
        }

        public void reset () {
            this.context.reset ();
        }

        public bool has_output () {
            return this.context.has_output ();
        }

        public string peek_output () {
            return this.context.peek_output ();
        }

        public string poll_output () {
            return this.context.poll_output ();
        }

        public void clear_output () {
            this.context.clear_output ();
        }

        uint register_id = 0;

        void register () {
            try {
                register_id = connection.register_object (object_path, this);
            } catch (IOError e) {
                error ("Could not register D-Bus object at %s: %s",
                       object_path, e.message);
            }
        }

        internal void unregister () {
            if (register_id > 0) {
                connection.unregister_object (register_id);
                candidates.unregister ();
                segments.unregister ();
                register_id = 0;
            }
        }
    }

    [DBus (name = "org.du_a.Kkc.Server")]
    public class DBusServer : Object {
        DBusConnection connection;
        Kkc.LanguageModel model;
        Kkc.DictionaryList dictionaries;
        Kkc.Rule? typing_rule;
        uint own_name_id;
        uint context_id = 0;

        public DBusServer (DBusConnection connection,
                           Kkc.LanguageModel model,
                           Kkc.DictionaryList dictionaries,
                           Kkc.Rule? typing_rule) {
            this.connection = connection;
            this.model = model;
            this.dictionaries = dictionaries;
            this.typing_rule = typing_rule;
            own_name_id = Bus.own_name_on_connection (
                connection,
                "org.du_a.Kkc.Server",
                BusNameOwnerFlags.NONE,
                on_name_acquired, on_name_lost);
        }

        ~DBusServer () {
            Bus.unown_name (own_name_id);
        }

        void on_name_acquired (DBusConnection connection, string name) {
            try {
                connection.register_object ("/org/du_a/Kkc/Server", this);
            } catch (IOError e) {
                error ("Could not register D-Bus service %s: %s",
                       name, e.message);
            }
        }

        void on_name_lost (DBusConnection connection, string name) {
        }

        public string create_context (BusName sender) {
            var context = new Kkc.Context (this.model);
            context.dictionaries = dictionaries;
            if (typing_rule != null)
                context.typing_rule = typing_rule;
            var object_path = "/org/du_a/Kkc/Context_%u".printf (context_id++);
            var dbus_context = new DBusContext (connection,
                                                object_path,
                                                context);
            contexts.set (object_path, dbus_context);
            Bus.watch_name_on_connection (
                connection,
                sender,
                BusNameWatcherFlags.NONE,
                null,
                (c, n) => {
                    destroy_context (object_path);
                });
            return object_path;
        }

        Map<string,DBusContext> contexts = new HashMap<string,DBusContext> ();

        public void destroy_context (string object_path) {
            DBusContext context;
            if (contexts.unset (object_path, out context))
                context.unregister ();
        }
    }
}
