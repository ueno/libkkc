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
    public class DictionaryList : Object {
        Gee.List<Dictionary> dictionaries = new ArrayList<Dictionary> ();

        /**
         * Register dictionary.
         *
         * @param dictionary a dictionary
         */
        public void add (Dictionary dictionary) {
            dictionaries.add (dictionary);
        }

        /**
         * Unregister dictionary.
         *
         * @param dictionary a dictionary
         */
        public void remove (Dictionary dictionary) {
            dictionaries.remove (dictionary);
        }

        /**
         * Remove all dictionaries.
         *
         * @param dictionary a dictionary
         */
        public void clear () {
            dictionaries.clear ();
        }

        public delegate bool DictionaryCallback (Dictionary dictionary);

        /**
         * Call function with dictionaries.
         *
         * @param type type of dictionary
         * @param writable `true` to enumerate only writable dictionaries
         * @param callback callback
         */
        public void call (Type? type,
                          bool writable,
                          DictionaryCallback callback)
        {
            foreach (var dictionary in dictionaries) {
                if ((type == null || dictionary.get_type ().is_a (type))
                    && (!writable || !dictionary.read_only))
                    if (!callback (dictionary))
                        return;
            }
        }
 
        /**
         * Save dictionaries on to disk.
         */
        public void save () {
            call (null,
                  true,
                  (dictionary) => {
                      if (dictionary.is_dirty) {
                          try {
                              dictionary.save ();
                          } catch (Error e) {
                              warning ("can't save dictionary: %s",
                                       e.message);
                          }
                      }
                      return true;
                  });
        }
   }
}