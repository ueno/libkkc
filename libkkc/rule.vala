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

        internal KeymapMapFile (RuleMetadata metadata, string mode) throws RuleParseError
        {
            base (metadata, "keymap", mode);
            if (has_map ("keymap")) {
                var map = get ("keymap");
                keymap = new Keymap ();
                foreach (var key in map.keys) {
                    var value = map.get (key);
                    keymap.set (key, value.get_string ());
                }
            } else {
                throw new RuleParseError.FAILED ("no keymap entry");
            }
        }
    }

    class RomKanaMapFile : MapFile {
        internal RomKanaNode root_node;

        RomKanaNode parse_rule (Map<string,Json.Node> map) throws RuleParseError
        {
            var node = new RomKanaNode (null);
            foreach (var key in map.keys) {
                var value = map.get (key);
                if (value.get_node_type () == Json.NodeType.ARRAY) {
                    var components = value.get_array ();
                    var length = components.get_length ();
                    if (2 <= length && length <= 4) {
                        var carryover = components.get_string_element (0);
                        var hiragana = components.get_string_element (1);
                        var katakana = length >= 3 ?
                            components.get_string_element (2) :
                            RomKanaUtils.get_katakana (hiragana);
                        var hankaku_katakana = length == 4 ?
                            components.get_string_element (3) :
                            RomKanaUtils.get_hankaku_katakana (katakana);

                        RomKanaEntry entry = {
                            key,
                            carryover,
                            hiragana,
                            katakana,
                            hankaku_katakana
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
            return node;
        }

        public RomKanaMapFile (RuleMetadata metadata) throws RuleParseError {
            base (metadata, "rom-kana", "default");
            if (has_map ("rom-kana")) {
                root_node = parse_rule (get ("rom-kana"));
            } else {
                throw new RuleParseError.FAILED ("no rom-kana entry");
            }
        }
    }

    public errordomain RuleParseError {
        FAILED
    }

    /**
     * Object describing a rule.
     */
    public struct RuleMetadata {
        /**
         * Base directory.
         */
        string base_dir;

        /**
         * Name of the rule.
         */
        string name;

        /**
         * Label string of the rule.
         */
        string label;

        /**
         * Description of the rule.
         */
        string description;

        /**
         * Name of key event filter.
         */
        string filter;

        /**
         * Return the path of the map file.
         *
         * @param type type of the map file
         * @param name name of the map file
         *
         * @return the absolute path of the map file
         */
        public string? locate_map_file (string type, string name) {
            var filename = Path.build_filename (base_dir, type, name + ".json");
            if (FileUtils.test (filename, FileTest.EXISTS)) {
                return filename;
            }
            return null;
        }
    }

    /**
     * Object representing a typing rule.
     */
    public class Rule : Object {
        /**
         * Metadata associated with the rule.
         */
        public RuleMetadata metadata { get; private set; }
        internal KeymapMapFile[] keymaps = new KeymapMapFile[InputMode.LAST];
        internal RomKanaMapFile rom_kana;

        // We can't use Entry<InputMode,*> here because of Vala bug:
        // https://bugzilla.gnome.org/show_bug.cgi?id=684262
        struct KeymapNameEntry {
            InputMode key;
            string value;
        }

        static const KeymapNameEntry[] keymap_names = {
            { InputMode.HIRAGANA, "hiragana" },
            { InputMode.KATAKANA, "katakana" },
            { InputMode.HANKAKU_KATAKANA, "hankaku-katakana" },
            { InputMode.LATIN, "latin" },
            { InputMode.WIDE_LATIN, "wide-latin" },
            { InputMode.DIRECT, "direct" }
        };

        static string[] rules_path;

        KeyEventFilter? filter;

        // Make the value type boxed to avoid unwanted ulong -> uint cast:
        // https://bugzilla.gnome.org/show_bug.cgi?id=660621
        static Map<string,Type?> filter_types = 
            new HashMap<string,Type?> ();

        static construct {
            rules_path = Utils.build_data_path ("rules");
            filter_types.set ("simple", typeof (SimpleKeyEventFilter));
            filter_types.set ("nicola", typeof (NicolaKeyEventFilter));
        }

        static RuleMetadata load_metadata (string filename) throws RuleParseError
        {
            Json.Parser parser = new Json.Parser ();
            try {
                if (!parser.load_from_file (filename)) {
                    throw new RuleParseError.FAILED ("can't load %s",
                                                     filename);
                }
                var root = parser.get_root ();
                if (root.get_node_type () != Json.NodeType.OBJECT) {
                    throw new RuleParseError.FAILED (
                        "metadata must be a JSON object");
                }

                var object = root.get_object ();
                Json.Node member;

                if (!object.has_member ("name")) {
                    throw new RuleParseError.FAILED (
                        "name is not defined in metadata");
                }

                member = object.get_member ("name");
                var name = member.get_string ();

                if (!object.has_member ("description")) {
                    throw new RuleParseError.FAILED (
                        "description is not defined in metadata");
                }

                member = object.get_member ("description");
                var description = member.get_string ();

                string? filter;
                if (object.has_member ("filter")) {
                    member = object.get_member ("filter");
                    filter = member.get_string ();
                    if (!filter_types.has_key (filter)) {
                        throw new RuleParseError.FAILED (
                            "unknown filter type %s",
                            filter);
                    }
                } else {
                    filter = "simple";
                }

                return RuleMetadata () { label = name,
                        description = description,
                        filter = filter,
                        base_dir = Path.get_dirname (filename) };

            } catch (GLib.Error e) {
                throw new RuleParseError.FAILED ("can't load rule: %s",
                                                 e.message);
            }
        }

        internal KeyEventFilter get_filter () {
            if (filter == null) {
                var type = filter_types.get (metadata.filter);
                filter = (KeyEventFilter) Object.new (type);
            }
            return filter;
        }

        /**
         * Create a rule.
         *
         * @param name name of the rule to load
         *
         * @return a new Rule
         */
        public Rule (string name) throws RuleParseError {
            var metadata = find_rule (name);
            if (metadata == null) {
                throw new RuleParseError.FAILED (
                    "can't find metadata for \"%s\"",
                    name);
            }
            this.metadata = metadata;

            var default_metadata = find_rule ("default");
            foreach (var entry in keymap_names) {
                var _metadata = metadata;
                if (metadata.locate_map_file ("keymap", entry.value) == null) {
                    _metadata = default_metadata;
                }
                keymaps[entry.key] = new KeymapMapFile (_metadata, entry.value);
            }

            if (metadata.locate_map_file ("rom-kana", "default") == null) {
                _metadata = default_metadata;
            }
            rom_kana = new RomKanaMapFile (_metadata);
        }

        ~Rule () {
            if (filter != null) {
                filter.reset ();
                filter = null;
            }
        }

        static Map<string,RuleMetadata?> rule_cache = new HashMap<string,RuleMetadata?> ();

        /**
         * Locate a rule by name.
         *
         * @param name name of the rule
         *
         * @return a RuleMetadata or `null`
         */
        public static RuleMetadata? find_rule (string name) {
            if (rule_cache.has_key (name)) {
                return rule_cache.get (name);
            }
            foreach (var dir in rules_path) {
                var base_dir_filename = Path.build_filename (dir, name);
                var metadata_filename = Path.build_filename (base_dir_filename,
                                                             "metadata.json");
                if (FileUtils.test (metadata_filename, FileTest.EXISTS)) {
                    try {
                        var metadata = load_metadata (metadata_filename);
                        metadata.name = name;
                        rule_cache.set (name, metadata);
                        return metadata;
                    } catch (RuleParseError e) {
                        continue;
                    }
                }
            }
            return null;
        }

        /**
         * List rules.
         *
         * @return an array of RuleMetadata
         */
        public static RuleMetadata[] list () {
            Set<string> names = new HashSet<string> ();
            RuleMetadata[] rules = {};
            foreach (var dir in rules_path) {
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
                            var metadata = load_metadata (metadata_filename);
                            names.add (name);
                            metadata.name = name;
                            rules += metadata;
                        } catch (RuleParseError e) {
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
