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
    /**
     * Initialize libkkc.
     *
     * Must be called before using any functions in libkkc.
     */
    public static void init () {
        // needed to use static methods defined in some classes
        typeof (DictionaryUtils).class_ref ();
        typeof (Keymap).class_ref ();
        typeof (KeyEventUtils).class_ref ();
        typeof (LanguageModel).class_ref ();
		typeof (RuleMetadata).class_ref ();
		typeof (Rule).class_ref ();
		typeof (RomKanaUtils).class_ref ();

        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    }

    /**
     * Type to specify input modes.
     */
    public enum InputMode {
        /**
         * Hiragana like "あいう...".
         */
        HIRAGANA = KanaMode.HIRAGANA,

        /**
         * Katakana like "アイウ...".
         */
        KATAKANA = KanaMode.KATAKANA,

        /**
         * Half-width katakana like "ｱｲｳ...".
         */
        HANKAKU_KATAKANA = KanaMode.HANKAKU_KATAKANA,

        /**
         * Half-width latin like "abc...".
         */
        LATIN = KanaMode.LATIN,

        /**
         * Full-width latin like "ａｂｃ...".
         */
        WIDE_LATIN = KanaMode.WIDE_LATIN,

        /**
         * Direct input.
         */
        DIRECT
    }
}
