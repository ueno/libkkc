# Copyright (C) 2011-2012 Daiki Ueno <ueno@unixuser.org>
# Copyright (C) 2011-2012 Red Hat, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

rulesdir = $(pkgdatadir)/rules

default_files =					\
	default/metadata.json			\
	default/keymap/default.json		\
	default/keymap/hankaku-katakana.json	\
	default/keymap/hiragana.json		\
	default/keymap/katakana.json		\
	default/keymap/latin.json		\
	default/keymap/wide-latin.json		\
	default/rom-kana/default.json		\
	$(NULL)

act_files =					\
	act/metadata.json			\
	act/keymap/default.json			\
	act/keymap/hankaku-katakana.json	\
	act/keymap/hiragana.json		\
	act/keymap/katakana.json		\
	act/keymap/latin.json			\
	act/keymap/wide-latin.json		\
	act/rom-kana/default.json		\
	$(NULL)

azik_files =					\
	azik/metadata.json			\
	azik/keymap/default.json		\
	azik/keymap/hankaku-katakana.json	\
	azik/keymap/hiragana.json		\
	azik/keymap/katakana.json		\
	azik/keymap/latin.json			\
	azik/keymap/wide-latin.json		\
	azik/rom-kana/default.json		\
	$(NULL)

kzik_files =					\
	kzik/metadata.json			\
	kzik/keymap/default.json		\
	kzik/keymap/hankaku-katakana.json	\
	kzik/keymap/hiragana.json		\
	kzik/keymap/katakana.json		\
	kzik/keymap/latin.json			\
	kzik/keymap/wide-latin.json		\
	kzik/rom-kana/default.json		\
	$(NULL)

tutcode_files =					\
	tutcode/metadata.json			\
	tutcode/keymap/hankaku-katakana.json	\
	tutcode/keymap/hiragana.json		\
	tutcode/keymap/katakana.json		\
	tutcode/keymap/latin.json		\
	tutcode/keymap/wide-latin.json		\
	tutcode/rom-kana/default.json		\
	$(NULL)

tutcode_touch16x_files =				\
	tutcode-touch16x/metadata.json			\
	tutcode-touch16x/keymap/hankaku-katakana.json	\
	tutcode-touch16x/keymap/hiragana.json		\
	tutcode-touch16x/keymap/katakana.json		\
	tutcode-touch16x/keymap/latin.json		\
	tutcode-touch16x/keymap/wide-latin.json		\
	tutcode-touch16x/rom-kana/default.json		\
	$(NULL)

nicola_files =					\
	nicola/metadata.json			\
	nicola/keymap/default.json		\
	nicola/keymap/kana.json			\
	nicola/keymap/latin.json		\
	nicola/keymap/katakana.json		\
	nicola/keymap/hankaku-katakana.json	\
	nicola/keymap/wide-latin.json		\
	nicola/keymap/hiragana.json		\
	nicola/rom-kana/default.json		\
	$(NULL)

tcode_files =					\
	tcode/rom-kana/default.json		\
	tcode/metadata.json			\
	tcode/keymap/latin.json			\
	tcode/keymap/katakana.json		\
	tcode/keymap/hankaku-katakana.json	\
	tcode/keymap/wide-latin.json		\
	tcode/keymap/hiragana.json		\
	$(NULL)

trycode_files =					\
	trycode/rom-kana/default.json		\
	trycode/metadata.json			\
	trycode/keymap/latin.json		\
	trycode/keymap/katakana.json		\
	trycode/keymap/hankaku-katakana.json	\
	trycode/keymap/wide-latin.json		\
	trycode/keymap/hiragana.json		\
	$(NULL)

nobase_dist_rules_DATA =			\
	$(default_files)			\
	$(act_files)				\
	$(azik_files)				\
	$(kzik_files)				\
	$(tutcode_files)			\
	$(tutcode_touch16x_files)		\
	$(nicola_files)				\
	$(tcode_files)				\
	$(trycode_files)			\
	README.rules				\
	$(NULL)

-include $(top_srcdir)/git.mk
