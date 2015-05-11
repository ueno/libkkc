/*
 * Copyright (C) 2015 Daiki Ueno <ueno@gnu.org>
 * Copyright (C) 2015 Red Hat, Inc.
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

static int main (string[] args) {
    if (args.length < 3) {
        stderr.printf ("Usage: gen-metadata-pot FILE EXPR...\n");
        return Posix.EXIT_FAILURE;
    }

    var parser = new Json.Parser ();
    try {
        parser.load_from_file (args[1]);
    } catch (Error e) {
        stderr.printf ("Can't load json file %s: %s\n",
                       args[1], e.message);
        return Posix.EXIT_FAILURE;
    }

    var root = parser.get_root ();
    for (var i = 2; i < args.length; i++) {
        Json.Node result;
        try {
            result = Json.Path.query (args[i], root);
        } catch (Error e) {
            stderr.printf ("can't parse json expression \"%s\": %s\n",
                           args[i], e.message);
            return Posix.EXIT_FAILURE;
        }
        var array = result.get_array ();
        array.foreach_element ((a, index_, node) => {
                stdout.printf ("msgid \"%s\"\nmsgstr \"\"\n\n",
                               node.get_string ());
            });
    }

    return Posix.EXIT_SUCCESS;
}