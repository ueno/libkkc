/* 
 * Copyright (C) 2013 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2013 Red Hat, Inc.
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */
namespace Kkc {
    /**
     * Object representing a writable typing rule.
     */
    public class UserRule : Rule {
        RuleMetadata parent;
        string path;

        /**
         * Create a new UserRule.
         *
         * @param parent metadata of the parent rule
         * @param base_dir base directory where this user rule is saved
         * @param prefix a string prepended to the rule name
         */
        public UserRule (RuleMetadata parent,
                         string base_dir,
                         string prefix) throws RuleParseError, Error
        {
            var path = Path.build_filename (base_dir, parent.name);

            if (!FileUtils.test (path, FileTest.IS_DIR))
                write_files (parent, path, prefix + ":" + parent.name);

            var metadata = Rule.load_metadata (
                Path.build_filename (path, "metadata.json"));
            base (metadata);

            this.path = path;
            this.parent = parent;
        }

        static void write_files (RuleMetadata parent,
                                 string path,
                                 string name) throws GLib.Error
        {
            var generator = new Json.Generator ();
            generator.set_pretty (true);

            // write metadata
            DirUtils.create_with_parents (path, 448);
            var metadata_builder = create_metadata (parent, name);
            generator.set_root (metadata_builder.get_root ());

            var metadata_filename = Path.build_filename (path, "metadata.json");
            generator.to_file (metadata_filename);

            // write keymap
            var keymap_path = Path.build_filename (path, "keymap");
            DirUtils.create_with_parents (keymap_path, 448);
            var enum_class = (EnumClass) typeof (InputMode).class_ref ();
            for (var i = enum_class.minimum; i <= enum_class.maximum; i++) {
                var enum_value = enum_class.get_value (i);
                var keymap_builder = create_keymap (parent,
                                                    enum_value.value_nick,
                                                    null);
                generator.set_root (keymap_builder.get_root ());
                var keymap_filename =
                    Path.build_filename (keymap_path,
                                         "%s.json".printf (
                                             enum_value.value_nick));
                generator.to_file (keymap_filename);
            }

            // write rom-kana rule
            var rom_kana_path = Path.build_filename (path, "rom-kana");
            DirUtils.create_with_parents (rom_kana_path, 448);
            var rom_kana_builder = create_rom_kana (parent, "default");
            generator.set_root (rom_kana_builder.get_root ());
            var rom_kana_filename = Path.build_filename (rom_kana_path,
                                                         "default.json");
            generator.to_file (rom_kana_filename);
        }

        static Json.Builder create_metadata (RuleMetadata parent,
                                          string name)
        {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("name");
            builder.add_string_value (name);
            builder.set_member_name ("description");
            builder.add_string_value (parent.description);
            builder.set_member_name ("filter");
            builder.add_string_value (parent.filter);
            builder.end_object ();
            return builder;
        }

        static Json.Builder create_keymap (RuleMetadata parent,
                                        string name,
                                        Keymap? keymap)
        {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("include");
            builder.begin_array ();
            builder.add_string_value (parent.name + "/" + name);
            builder.end_array ();
            if (keymap != null) {
                builder.set_member_name ("define");
                builder.begin_object ();
                builder.set_member_name ("keymap");
                builder.begin_object ();
                var entries = keymap.local_entries ();
                foreach (var entry in entries) {
                    builder.set_member_name (entry.key.to_string ());
                    if (entry.command == null)
                        builder.add_null_value ();
                    else
                        builder.add_string_value (entry.command);
                }
                builder.end_object ();
                builder.end_object ();
            }
            builder.end_object ();
            return builder;
        }

        static Json.Builder create_rom_kana (RuleMetadata parent,
                                             string name)
        {
            var builder = new Json.Builder ();
            builder.begin_object ();
            builder.set_member_name ("include");
            builder.begin_array ();
            builder.add_string_value (parent.name + "/" + name);
            builder.end_array ();
            builder.end_object ();
            return builder;
        }

        /**
         * Save keymap for given input mode.
         *
         * @param input_mode input mode
         */
        public void write (InputMode input_mode) throws Error {
            var enum_class = (EnumClass) typeof (InputMode).class_ref ();
            var keymap_name = enum_class.get_value (input_mode).value_nick;
            var keymap_path = Path.build_filename (path, "keymap");
            DirUtils.create_with_parents (keymap_path, 448);

            var generator = new Json.Generator ();
            generator.set_pretty (true);

            var builder = create_keymap (parent,
                                         keymap_name,
                                         get_keymap (input_mode));
            generator.set_root (builder.get_root ());

            var filename = Path.build_filename (keymap_path,
                                                "%s.json".printf (keymap_name));
            generator.to_file (filename);
        }
    }
}
