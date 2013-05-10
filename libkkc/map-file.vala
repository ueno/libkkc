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
    abstract class MapFile : Object {
        Map<string,Map<string,Json.Node>> maps =
            new HashMap<string,Map<string,Json.Node>> ();
        Map<string,Map<string,Json.Node>> parent_maps =
            new HashMap<string,Map<string,Json.Node>> ();

        void load_map (Map<string,Json.Node> map, Json.Object object) {
            var keys = object.get_members ();
            foreach (var key in keys) {
                var value = object.get_member (key);
                var _key = uniquify (key);
                map.set (_key, value);
            }
        }

        protected virtual string uniquify (string key) {
            return key;
        }

        void load (RuleMetadata metadata,
                   string type,
                   string name,
                   Set<string> parents,
                   Map<string,Map<string,Json.Node>> maps,
                   Map<string,Map<string,Json.Node>> parent_maps) throws RuleParseError
        {
            var filename = metadata.locate_map_file (type, name);
            if (filename == null) {
                throw new RuleParseError.FAILED (
                    "can't locate map file for %s/%s", type, name);
            }

            Json.Parser parser = new Json.Parser ();
            try {
                if (!parser.load_from_file (filename))
                    throw new RuleParseError.FAILED ("");
            } catch (GLib.Error e) {
                throw new RuleParseError.FAILED (
                    "can't load %s: %s".printf (filename, e.message));
            }
            var root = parser.get_root ();
            if (root.get_node_type () != Json.NodeType.OBJECT) {
                throw new RuleParseError.FAILED (
                    "root element must be an object");
            }
            var object = root.get_object ();

            Json.Node member;
            if (object.has_member ("include")) {
                member = object.get_member ("include");
                if (member.get_node_type () != Json.NodeType.ARRAY) {
                    throw new RuleParseError.FAILED (
                        "\"include\" element must be an array");
                }
                var include = member.get_array ();
                var elements = include.get_elements ();
                foreach (var element in elements) {
                    var parent = element.get_string ();
                    if (parent in parents) {
                        throw new RuleParseError.FAILED (
                            "found circular include of %s", parent);
                    }
                    string parent_rule, parent_name;
                    var index = parent.index_of ("/");
                    if (index < 0) {
                        parent_rule = metadata.name;
                        parent_name = parent;
                    } else {
                        parent_rule = parent[0:index];
                        parent_name = parent[index + 1:parent.length];
                    }
                    var parent_metadata = RuleMetadata.find (parent_rule);
                    if (parent_metadata == null) {
                        throw new RuleParseError.FAILED ("can't find rule %s",
                                                         parent_rule);
                    }
                    parents.add (parent);
                    load (parent_metadata,
                          type,
                          parent_name,
                          parents,
                          parent_maps,
                          parent_maps);
                }
            }

            if (object.has_member ("define")) {
                member = object.get_member ("define");
                if (member.get_node_type () != Json.NodeType.OBJECT) {
                    throw new RuleParseError.FAILED (
                        "\"define\" element must be an object");
                }
                var define = member.get_object ();
                var keys = define.get_members ();
                foreach (var key in keys) {
                    if (!maps.has_key (key)) {
                        var map = new HashMap<string,Json.Node> ();
                        maps.set (key, map);
                    }
                    member = define.get_member (key);
                    if (member.get_node_type () != Json.NodeType.OBJECT) {
                        throw new RuleParseError.FAILED (
                            "map element must be an object");
                    }
                    load_map (maps.get (key), member.get_object ());
                }
            }
        }

        internal MapFile (RuleMetadata metadata,
                          string type,
                          string name) throws RuleParseError
        {
            Set<string> parents = new HashSet<string> ();
            load (metadata, type, name, parents, maps, parent_maps);
        }

        internal new Map<string,Json.Node> @get (string name) {
            if (maps.has_key (name))
                return maps.get (name);
            return new HashMap<string,Json.Node> ();
        }

        internal new Map<string,Json.Node> @get_parent (string name) {
            if (parent_maps.has_key (name))
                return parent_maps.get (name);
            return new HashMap<string,Json.Node> ();
        }
    }
}
