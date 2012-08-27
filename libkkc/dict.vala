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

namespace Kkc {
    public errordomain DictError {
        NOT_READABLE,
        MALFORMED_INPUT
    }

    public struct DictEntry {
        string input;
        string output;
        uint id;
    }

    public struct DictMetadata {
        string base_dir;
        string name;
        string description;
        string type;
    }

    public abstract class Dict : Object {
        static string[] dict_path;

        public DictMetadata metadata { get; construct; }

        // Make the value type boxed to avoid unwanted ulong -> uint cast:
        // https://bugzilla.gnome.org/show_bug.cgi?id=660621
        static Map<string,Type?> dict_types = 
            new HashMap<string,Type?> ();

        static construct {
            dict_path = Util.build_data_path ("dict");
            dict_types.set ("text2", typeof (TextBigramDict));
            dict_types.set ("text3", typeof (TextTrigramDict));
            dict_types.set ("sorted2", typeof (SortedBigramDict));
            dict_types.set ("sorted3", typeof (SortedTrigramDict));
        }

        public abstract DictEntry bos { get; }
        public abstract DictEntry eos { get; }
        public abstract Collection<DictEntry?> entries (string input);
        public abstract new DictEntry? @get (string input, string output);

        public static Dict? load (string name) throws DictError {
            foreach (var dir in dict_path) {
                var metadata_filename = Path.build_filename (
                    dir, name,
                    "metadata.json");
                if (FileUtils.test (metadata_filename, FileTest.EXISTS)) {
                    try {
                        var metadata = load_metadata (metadata_filename);
                        var type = dict_types.get (metadata.type);
                        return (Dict) Object.new (type,
                                                  "metadata", metadata,
                                                  null);
                    } catch (DictError e) {
                        warning ("can't load metadata file %s: %s",
                                 metadata_filename,
                                 e.message);
                        continue;
                    }
                }
            }
            return null;
        }

        static DictMetadata load_metadata (string filename) throws DictError
        {
            Json.Parser parser = new Json.Parser ();
            try {
                if (!parser.load_from_file (filename)) {
                    throw new DictError.MALFORMED_INPUT ("can't load %s",
                                                         filename);
                }
                var root = parser.get_root ();
                if (root.get_node_type () != Json.NodeType.OBJECT) {
                    throw new DictError.MALFORMED_INPUT (
                        "metadata must be a JSON object");
                }

                var object = root.get_object ();
                Json.Node member;

                if (!object.has_member ("name")) {
                    throw new DictError.MALFORMED_INPUT (
                        "name is not defined in metadata");
                }

                member = object.get_member ("name");
                var name = member.get_string ();

                if (!object.has_member ("description")) {
                    throw new DictError.MALFORMED_INPUT (
                        "description is not defined in metadata");
                }

                member = object.get_member ("description");
                var description = member.get_string ();

                if (!object.has_member ("type")) {
                    throw new DictError.MALFORMED_INPUT (
                        "type is not defined in metadata");
                }
                    
                member = object.get_member ("type");
                var type = member.get_string ();
                if (!dict_types.has_key (type)) {
                    throw new DictError.MALFORMED_INPUT (
                        "unknown dictionary type %s",
                        type);
                }

                return DictMetadata () { name = name,
                        description = description,
                        type = type,
                        base_dir = Path.get_dirname (filename) };

            } catch (GLib.Error e) {
                throw new DictError.MALFORMED_INPUT ("can't load rule: %s",
                                                     e.message);
            }
        }
    }

    public interface UnigramDict : Dict {
        public abstract double unigram_cost (DictEntry entry);
        public abstract double unigram_backoff (DictEntry entry);
    }

    public interface BigramDict : UnigramDict {
        public abstract bool has_bigram (DictEntry pentry,
                                         DictEntry entry);
        public abstract double bigram_cost (DictEntry pentry,
                                                DictEntry entry);
        public abstract double bigram_backoff (DictEntry pentry,
                                                   DictEntry entry);

        public double bigram_backoff_cost (DictEntry pentry,
                                           DictEntry entry)
        {
            if (has_bigram (pentry, entry))
                return bigram_cost (pentry, entry);

            var backoff = unigram_backoff (pentry);
            var cost = unigram_cost (entry);
            return backoff + cost;
        }
    }

    public interface TrigramDict : BigramDict {
        public abstract bool has_trigram (DictEntry ppentry,
                                          DictEntry pentry,
                                          DictEntry entry);
        public abstract double trigram_cost (DictEntry ppentry,
                                             DictEntry pentry,
                                             DictEntry entry);

        public double trigram_backoff_cost (DictEntry ppentry,
                                                DictEntry pentry,
                                                DictEntry entry)
        {
            if (has_trigram (ppentry, pentry, entry))
                return trigram_cost (ppentry, pentry, entry);

            var backoff = bigram_backoff (ppentry, pentry);
            var cost = bigram_backoff_cost (pentry, entry);
            return backoff + cost;
        }
    }
}
