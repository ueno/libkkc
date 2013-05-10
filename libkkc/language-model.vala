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
        NOT_FOUND
    }

    public struct LanguageModelEntry {
        string input;
        string output;
        uint id;
    }

    public class LanguageModelMetadata : MetadataFile {
        public Type model_type { get; construct set; }

        // Make the value type boxed to avoid unwanted ulong -> uint cast:
        // https://bugzilla.gnome.org/show_bug.cgi?id=660621
        static Map<string,Type?> model_types = new HashMap<string,Type?> ();

        static construct {
            model_types.set ("text2", typeof (TextBigramLanguageModel));
            model_types.set ("text3", typeof (TextTrigramLanguageModel));
            model_types.set ("sorted2", typeof (SortedBigramLanguageModel));
            model_types.set ("sorted3", typeof (SortedTrigramLanguageModel));
        }

        public LanguageModelMetadata (string name, string filename) throws Error {
            base (name, filename);
        }

        public override bool parse (Json.Object object) throws Error {
            if (!object.has_member ("type"))
                throw new MetadataFormatError.MISSING_FIELD (
                    "type is not defined in metadata");
                    
            var member = object.get_member ("type");
            var type = member.get_string ();
            if (!model_types.has_key (type))
                throw new MetadataFormatError.INVALID_FIELD (
                    "unknown language model type %s",
                    type);
            this.model_type = model_types.get (type);

            return true;
        }
    }

    public abstract class LanguageModel : Object, Initable {
        public LanguageModelMetadata metadata { get; construct; }

        public abstract LanguageModelEntry bos { get; }
        public abstract LanguageModelEntry eos { get; }
        public abstract Collection<LanguageModelEntry?> entries (string input);
        public abstract new LanguageModelEntry? @get (string input,
													  string output);

        public bool init (GLib.Cancellable? cancellable = null) throws Error {
            return true;
        }

        public static LanguageModel? load (string name) throws LanguageModelError
		{
            var dirs = Utils.build_data_path ("models");
            foreach (var dir in dirs) {
                var metadata_filename = Path.build_filename (
                    dir, name,
                    "metadata.json");
                if (FileUtils.test (metadata_filename, FileTest.EXISTS)) {
                    try {
                        var metadata = new LanguageModelMetadata (
                            name,
                            metadata_filename);
                        return (LanguageModel) Initable.new (
                            metadata.model_type,
                            null,
                            "metadata", metadata,
                            null);
                    } catch (Error e) {
                        warning ("can't load metadata file %s: %s",
                                 metadata_filename,
                                 e.message);
                        continue;
                    }
                }
            }
			throw new LanguageModelError.NOT_FOUND (
                "can't find suitable model");
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
