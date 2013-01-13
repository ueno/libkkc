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

namespace Kkc {
    public errordomain LanguageModelError {
        NOT_READABLE,
        MALFORMED_INPUT
    }

    public struct LanguageModelEntry {
        string input;
        string output;
        uint id;
    }

    public struct LanguageModelMetadata {
        string base_dir;
        string name;
        string description;
        string type;
    }

    public abstract class LanguageModel : Object {
        static string[] model_path;

        public LanguageModelMetadata metadata { get; construct; }

        // Make the value type boxed to avoid unwanted ulong -> uint cast:
        // https://bugzilla.gnome.org/show_bug.cgi?id=660621
        static Map<string,Type?> model_types = 
		new HashMap<string,Type?> ();

        static construct {
            model_path = Utils.build_data_path ("model");
            model_types.set ("text2", typeof (TextBigramLanguageModel));
            model_types.set ("text3", typeof (TextTrigramLanguageModel));
            model_types.set ("sorted2", typeof (SortedBigramLanguageModel));
            model_types.set ("sorted3", typeof (SortedTrigramLanguageModel));
        }

        public abstract LanguageModelEntry bos { get; }
        public abstract LanguageModelEntry eos { get; }
        public abstract Collection<LanguageModelEntry?> entries (string input);
        public abstract new LanguageModelEntry? @get (string input,
													  string output);

        public static LanguageModel? load (string name) throws LanguageModelError
		{
            foreach (var dir in model_path) {
                var metadata_filename = Path.build_filename (
                    dir, name,
                    "metadata.json");
                if (FileUtils.test (metadata_filename, FileTest.EXISTS)) {
                    try {
                        var metadata = load_metadata (metadata_filename);
                        var type = model_types.get (metadata.type);
                        return (LanguageModel) Object.new (type,
														   "metadata", metadata,
														   null);
                    } catch (LanguageModelError e) {
                        warning ("can't load metadata file %s: %s",
                                 metadata_filename,
                                 e.message);
                        continue;
                    }
                }
            }
			throw new LanguageModelError.NOT_READABLE ("can't find suitable model");
        }

        static LanguageModelMetadata load_metadata (string filename) throws LanguageModelError
        {
            Json.Parser parser = new Json.Parser ();
            try {
                if (!parser.load_from_file (filename)) {
                    throw new LanguageModelError.MALFORMED_INPUT ("can't load %s",
																  filename);
                }
                var root = parser.get_root ();
                if (root.get_node_type () != Json.NodeType.OBJECT) {
                    throw new LanguageModelError.MALFORMED_INPUT (
                        "metadata must be a JSON object");
                }

                var object = root.get_object ();
                Json.Node member;

                if (!object.has_member ("name")) {
                    throw new LanguageModelError.MALFORMED_INPUT (
                        "name is not defined in metadata");
                }

                member = object.get_member ("name");
                var name = member.get_string ();

                if (!object.has_member ("description")) {
                    throw new LanguageModelError.MALFORMED_INPUT (
                        "description is not defined in metadata");
                }

                member = object.get_member ("description");
                var description = member.get_string ();

                if (!object.has_member ("type")) {
                    throw new LanguageModelError.MALFORMED_INPUT (
                        "type is not defined in metadata");
                }
                    
                member = object.get_member ("type");
                var type = member.get_string ();
                if (!model_types.has_key (type)) {
                    throw new LanguageModelError.MALFORMED_INPUT (
                        "unknown language model type %s",
                        type);
                }

                return LanguageModelMetadata () { name = name,
                        description = description,
                        type = type,
                        base_dir = Path.get_dirname (filename) };

            } catch (GLib.Error e) {
                throw new LanguageModelError.MALFORMED_INPUT ("can't load rule: %s",
															  e.message);
            }
        }
    }

    public interface UnigramLanguageModel : LanguageModel {
        public abstract double unigram_cost (LanguageModelEntry entry);
        public abstract double unigram_backoff (LanguageModelEntry entry);
    }

    public interface BigramLanguageModel : UnigramLanguageModel {
        public abstract bool has_bigram (LanguageModelEntry pentry,
                                         LanguageModelEntry entry);
        public abstract double bigram_cost (LanguageModelEntry pentry,
											LanguageModelEntry entry);
        public abstract double bigram_backoff (LanguageModelEntry pentry,
											   LanguageModelEntry entry);

        public double bigram_backoff_cost (LanguageModelEntry pentry,
                                           LanguageModelEntry entry)
        {
            if (has_bigram (pentry, entry))
                return bigram_cost (pentry, entry);

            var backoff = unigram_backoff (pentry);
            var cost = unigram_cost (entry);
            return backoff + cost;
        }
    }

    public interface TrigramLanguageModel : BigramLanguageModel {
        public abstract bool has_trigram (LanguageModelEntry ppentry,
                                          LanguageModelEntry pentry,
                                          LanguageModelEntry entry);
        public abstract double trigram_cost (LanguageModelEntry ppentry,
                                             LanguageModelEntry pentry,
                                             LanguageModelEntry entry);

        public double trigram_backoff_cost (LanguageModelEntry ppentry,
											LanguageModelEntry pentry,
											LanguageModelEntry entry)
        {
            if (has_trigram (ppentry, pentry, entry))
                return trigram_cost (ppentry, pentry, entry);

            var backoff = bigram_backoff (ppentry, pentry);
            var cost = bigram_backoff_cost (pentry, entry);
            return backoff + cost;
        }
    }
}
