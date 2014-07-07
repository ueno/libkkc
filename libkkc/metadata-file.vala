/*
 * Copyright (C) 2011-2014 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2011-2014 Red Hat, Inc.
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

namespace Kkc {
    public errordomain MetadataFormatError {
        MISSING_FIELD,
        INVALID_FIELD
    }

    public abstract class MetadataFile : Object, Initable {
        /**
         * Name of the metadata.
         */
        public string name { get; construct set; }

        /**
         * Label string of the metadata.
         */
        public string label { get; construct set; }

        /**
         * Description of the metadata.
         */
        public string description { get; construct set; }

        /**
         * Location of the metadata file.
         */
        public string filename { get; construct set; }

        public MetadataFile (string name, string filename) throws Error {
            Object (name: name, filename: filename);
            init (null);
        }

        public abstract bool parse (Json.Object object) throws Error;

        public bool init (GLib.Cancellable? cancellable = null) throws Error {
            Json.Parser parser = new Json.Parser ();
            parser.load_from_file (filename);

            var root = parser.get_root ();
            if (root.get_node_type () != Json.NodeType.OBJECT)
                throw new MetadataFormatError.MISSING_FIELD (
                    "metadata must be a JSON object");

            var object = root.get_object ();
            Json.Node member;

            if (!object.has_member ("name"))
                throw new MetadataFormatError.MISSING_FIELD (
                    "name is not defined in metadata");

            member = object.get_member ("name");
            var name = member.get_string ();

            if (!object.has_member ("description"))
                throw new MetadataFormatError.MISSING_FIELD (
                    "description is not defined in metadata");

            member = object.get_member ("description");
            var description = member.get_string ();

            parse (object);

            var label = name;
            if (label != "")
                label = dgettext (Config.GETTEXT_PACKAGE, label);
            if (description != "")
                description = dgettext (Config.GETTEXT_PACKAGE, description);

            this.label = label;
            this.description = description;

            return true;
        }
    }
}
