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
    class KeymapMapFile : MapFile {
        internal Keymap keymap;
        internal Keymap parent_keymap;

        protected override string uniquify (string key) {
            try {
                var event = new KeyEvent.from_string (key);
                return event.to_string ();
            } catch (KeyEventFormatError e) {
                warning (
                    "can't get key event from string %s: %s",
                    key, e.message);
                return key;
            }
        }

        void load_keymap (Keymap keymap, Map<string,Json.Node> map) {
            var iter = map.map_iterator ();
            while (iter.next ()) {
                var key = iter.get_key ();
                var value = iter.get_value ();
                try {
                    keymap.set (new KeyEvent.from_string (key),
                                value.get_string ());
                } catch (KeyEventFormatError e) {
                    warning (
                        "can't get key event from string %s: %s",
                        key, e.message);
                }
            }
        }

        internal KeymapMapFile (RuleMetadata metadata, string mode) throws RuleParseError
        {
            base (metadata, "keymap", mode);

            keymap = new Keymap ();
            load_keymap (keymap, get ("keymap"));

            keymap.parent = new Keymap ();
            load_keymap (keymap.parent, get_parent ("keymap"));
        }
    }

    class RomKanaMapFile : MapFile {
        internal RomKanaNode root_node;

        void load_rom_kana (RomKanaNode node,
                            Map<string,Json.Node> map) throws RuleParseError
        {
            foreach (var key in map.keys) {
                var value = map.get (key);
                if (value.get_node_type () == Json.NodeType.ARRAY) {
                    var components = value.get_array ();
                    var length = components.get_length ();
                    if (2 <= length && length <= 5) {
                        var carryover = components.get_string_element (0);
                        var hiragana = components.get_string_element (1);
                        var katakana = length >= 3 ?
                            components.get_string_element (2) :
                            RomKanaUtils.get_katakana (hiragana);
                        var hiragana_partial = length >= 4 ?
                            components.get_string_element (3) :
                            "";
                        var katakana_partial = length >= 5 ?
                            components.get_string_element (4) :
                            "";

                        RomKanaEntry entry = {
                            key,
                            carryover,
                            hiragana,
                            katakana,
                            hiragana_partial,
                            katakana_partial
                        };
                        node.insert (key, entry);
                    }
                    else {
                        throw new RuleParseError.FAILED (
                            "\"rom-kana\" must have two to four elements");
                    }
                } else {
                    throw new RuleParseError.FAILED (
                        "\"rom-kana\" member must be either an array or null");
                }
            }
        }

        public RomKanaMapFile (RuleMetadata metadata) throws RuleParseError {
            base (metadata, "rom-kana", "default");

            root_node = new RomKanaNode (null);
            var parent_map = get_parent ("rom-kana");
            var map = get ("rom-kana");
            var iter = map.map_iterator ();
            while (iter.next ()) {
                var key = iter.get_key ();
                var value = iter.get_value ();
                if (value.get_node_type () == Json.NodeType.NULL)
                    parent_map.unset (key);
                else
                    parent_map.set (key, value);
            }
            load_rom_kana (root_node, parent_map);
        }
    }

    public errordomain RuleParseError {
        FAILED
    }

    /**
     * Object describing a rule.
     */
    public class RuleMetadata : MetadataFile {
        /**
         * Name of key event filter.
         */
        public string filter { get; construct set; }

        /**
         * Priority of the rule.
         */
        public int priority { get; construct set; default = 0; }

        // Make the value type boxed to avoid unwanted ulong -> uint cast:
        // https://bugzilla.gnome.org/show_bug.cgi?id=660621
        static Map<string,Type?> filter_types;
        static Map<string,RuleMetadata> instance_cache;

        static construct {
            filter_types = new HashMap<string,Type?> ();
            instance_cache = new HashMap<string,RuleMetadata> ();

            filter_types.set ("simple", typeof (SimpleKeyEventFilter));
            filter_types.set ("nicola", typeof (NicolaKeyEventFilter));
            filter_types.set ("kana", typeof (KanaKeyEventFilter));
        }

        public RuleMetadata (string name, string filename) throws Error {
            base (name, filename);
        }

        public override bool parse (Json.Object object) throws Error {
            string filter = "simple";
            if (object.has_member ("filter")) {
                filter = object.get_string_member ("filter");
                if (!filter_types.has_key (filter))
                    throw new MetadataFormatError.INVALID_FIELD (
                        "unknown filter type %s",
                        filter);
            }
            this.filter = filter;

            if (object.has_member ("priority"))
                this.priority = (int) object.get_int_member ("priority");

            return true;
        }

        public KeyEventFilter create_key_event_filter () {
            var type = filter_types.get (filter);
            return (KeyEventFilter) Object.new (type);
        }

        /**
         * Return the path of the map file.
         *
         * @param type type of the map file
         * @param name name of the map file
         *
         * @return the absolute path of the map file
         */
        public string? locate_map_file (string type, string name) {
            var map_filename = Path.build_filename (
                Path.get_dirname (filename),
                type,
                name + ".json");

            if (FileUtils.test (map_filename, FileTest.EXISTS))
                return map_filename;

            return null;
        }

        /**
         * Locate a rule metadata by name.
         *
         * @param name name of the rule
         *
         * @return a RuleMetadata or `null`
         */
        public static RuleMetadata? find (string name) {
            if (instance_cache.has_key (name))
                return instance_cache.get (name);

            var dirs = Utils.build_data_path ("rules");
            foreach (var dir in dirs) {
                var base_dir_filename = Path.build_filename (dir, name);
                var metadata_filename = Path.build_filename (base_dir_filename,
                                                             "metadata.json");
                if (FileUtils.test (metadata_filename, FileTest.EXISTS)) {
                    try {
                        var metadata = new RuleMetadata (name,
                                                         metadata_filename);
                        instance_cache.set (name, metadata);
                        return metadata;
                    } catch (Error e) {
                        continue;
                    }
                }
            }
            return null;
        }
    }

    /**
     * Object representing a typing rule.
     */
    public class Rule : Object, Initable {
        /**
         * Metadata associated with the rule.
         */
        public RuleMetadata metadata { get; construct set; }

        public KeyEventFilter filter { get; construct set; }

        KeymapMapFile[] keymaps;
        internal RomKanaMapFile rom_kana;

        public Keymap get_keymap (InputMode mode) {
            return keymaps[mode].keymap;
        }

        /**
         * Create a rule.
         *
         * @param metadata metadata of the rule
         *
         * @return a new Rule
         */
        public Rule (RuleMetadata metadata) throws Error {
            Object (metadata: metadata);
            init (null);
        }

        ~Rule () {
            if (filter != null) {
                filter.reset ();
                filter = null;
            }
        }

        public bool init (GLib.Cancellable? cancellable = null) throws Error {
            var default_metadata = RuleMetadata.find ("default");
            var enum_class = (EnumClass) typeof (InputMode).class_ref ();
            this.keymaps = new KeymapMapFile[enum_class.maximum + 1];
            for (var i = enum_class.minimum; i <= enum_class.maximum; i++) {
                var enum_value = enum_class.get_value (i);
                if (enum_value != null) {
                    var _metadata = metadata;
                    if (_metadata.locate_map_file ("keymap",
                                                   enum_value.value_nick) ==
                        null)
                        _metadata = default_metadata;
                    this.keymaps[enum_value.value] =
                        new KeymapMapFile (_metadata, enum_value.value_nick);
                }
            }

            var _metadata = metadata;
            if (_metadata.locate_map_file ("rom-kana", "default") == null)
                _metadata = default_metadata;

            rom_kana = new RomKanaMapFile (_metadata);
            filter = _metadata.create_key_event_filter ();

            return true;
        }

        /**
         * List rules.
         *
         * @return an array of RuleMetadata
         */
        public static RuleMetadata[] list () {
            Set<string> names = new HashSet<string> ();
            RuleMetadata[] rules = {};
            var dirs = Utils.build_data_path ("rules");
            foreach (var dir in dirs) {
                Dir handle;
                try {
                    handle = Dir.open (dir);
                } catch (GLib.Error e) {
                    continue;
                }
                string? name;
                while ((name = handle.read_name ()) != null) {
                    if (name in names) {
                        continue;
                    }
                    var metadata_filename =
                        Path.build_filename (dir, name, "metadata.json");
                    if (FileUtils.test (metadata_filename, FileTest.EXISTS)) {
                        try {
                            var metadata = new RuleMetadata (name,
                                                             metadata_filename);
                            names.add (name);
                            metadata.name = name;
                            rules += metadata;
                        } catch (Error e) {
                            warning ("can't load metadata %s: %s",
                                     metadata_filename,
                                     e.message);
                        }
                    }
                }
            }
            return rules;
        }
    }
}
