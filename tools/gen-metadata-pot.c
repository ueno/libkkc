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

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <json-glib/json-glib.h>
#include <stdlib.h>

static void
print_pair (JsonArray *array,
	    guint index_,
	    JsonNode *element_node,
	    gpointer user_data)
{
  g_printf ("msgid \"%s\"\nmsgstr \"\"\n\n",
	    json_node_get_string (element_node));
}

int
main (int argc, char **argv)
{
  JsonParser *parser;
  JsonNode *root, *result;
  JsonArray *array;
  GError *error;
  gint i;

  if (argc < 3)
    {
      g_printerr ("Usage: gen-metadata-pot FILE EXPR...\n");
      return EXIT_FAILURE;
    }

  parser = json_parser_new ();
  error = NULL;
  if (!json_parser_load_from_file (parser, argv[1], &error))
    {
      g_printerr ("can't load json file %s: %s\n",
		  argv[1], error->message);
      g_error_free (error);
      g_object_unref (parser);
      return EXIT_FAILURE;
    }

  root = json_parser_get_root (parser);
  for (i = 2; i < argc; i++)
    {
      error = NULL;
      result = json_path_query (argv[i], root, &error);
      if (!result)
	{
	  g_printerr ("can't parse json expression \"%s\": %s\n",
		      argv[i], error->message);
	  g_error_free (error);
	  g_object_unref (parser);
	  return EXIT_FAILURE;
	}
      array = json_node_get_array (result);
      json_array_foreach_element (array, print_pair, NULL);
      json_node_free (result);
    }

  g_object_unref (parser);
  return EXIT_SUCCESS;
}
