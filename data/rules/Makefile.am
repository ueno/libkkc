# Copyright (C) 2011-2013 Daiki Ueno <ueno@gnu.org>
# Copyright (C) 2011-2013 Red Hat, Inc.

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
	default/keymap/default.json		\
	default/keymap/hankaku-katakana.json	\
	default/keymap/hiragana.json		\
	default/keymap/katakana.json		\
	default/keymap/latin.json		\
	default/keymap/wide-latin.json		\
	default/keymap/direct.json		\
	default/rom-kana/default.json		\
	$(NULL)
default_metadata_in =				\
	default/metadata.json.in		\
	$(NULL)

act_files =					\
	act/keymap/default.json			\
	act/keymap/hankaku-katakana.json	\
	act/keymap/hiragana.json		\
	act/keymap/katakana.json		\
	act/keymap/latin.json			\
	act/keymap/wide-latin.json		\
	act/rom-kana/default.json		\
	$(NULL)
act_metadata_in =				\
	act/metadata.json.in			\
	$(NULL)

azik_files =					\
	azik/keymap/default.json		\
	azik/keymap/hankaku-katakana.json	\
	azik/keymap/hiragana.json		\
	azik/keymap/katakana.json		\
	azik/keymap/latin.json			\
	azik/keymap/wide-latin.json		\
	azik/rom-kana/default.json		\
	$(NULL)
azik_metadata_in =				\
	azik/metadata.json.in			\
	$(NULL)

kzik_files =					\
	kzik/keymap/default.json		\
	kzik/keymap/hankaku-katakana.json	\
	kzik/keymap/hiragana.json		\
	kzik/keymap/katakana.json		\
	kzik/keymap/latin.json			\
	kzik/keymap/wide-latin.json		\
	kzik/rom-kana/default.json		\
	$(NULL)
kzik_metadata_in =				\
	kzik/metadata.json.in			\
	$(NULL)

tutcode_files =					\
	tutcode/keymap/hankaku-katakana.json	\
	tutcode/keymap/hiragana.json		\
	tutcode/keymap/katakana.json		\
	tutcode/keymap/latin.json		\
	tutcode/keymap/wide-latin.json		\
	tutcode/rom-kana/default.json		\
	$(NULL)
tutcode_metadata_in =				\
	tutcode/metadata.json.in		\
	$(NULL)

tutcode_touch16x_files =				\
	tutcode-touch16x/keymap/hankaku-katakana.json	\
	tutcode-touch16x/keymap/hiragana.json		\
	tutcode-touch16x/keymap/katakana.json		\
	tutcode-touch16x/keymap/latin.json		\
	tutcode-touch16x/keymap/wide-latin.json		\
	tutcode-touch16x/rom-kana/default.json		\
	$(NULL)
tutcode_touch16x_metadata_in =			\
	tutcode-touch16x/metadata.json.in	\
	$(NULL)

nicola_files =					\
	nicola/keymap/default.json		\
	nicola/keymap/kana.json			\
	nicola/keymap/latin.json		\
	nicola/keymap/katakana.json		\
	nicola/keymap/hankaku-katakana.json	\
	nicola/keymap/wide-latin.json		\
	nicola/keymap/hiragana.json		\
	nicola/rom-kana/default.json		\
	$(NULL)
nicola_metadata_in =				\
	nicola/metadata.json.in			\
	$(NULL)

tcode_files =					\
	tcode/rom-kana/default.json		\
	tcode/keymap/latin.json			\
	tcode/keymap/katakana.json		\
	tcode/keymap/hankaku-katakana.json	\
	tcode/keymap/wide-latin.json		\
	tcode/keymap/hiragana.json		\
	$(NULL)
tcode_files =					\
	tcode/metadata.json.in			\
	$(NULL)

trycode_files =					\
	trycode/rom-kana/default.json		\
	trycode/keymap/latin.json		\
	trycode/keymap/katakana.json		\
	trycode/keymap/hankaku-katakana.json	\
	trycode/keymap/wide-latin.json		\
	trycode/keymap/hiragana.json		\
	$(NULL)
trycode_metadata_in =				\
	trycode/metadata.json.in		\
	$(NULL)

kana_files =					\
	kana/keymap/default.json		\
	kana/keymap/hankaku-katakana.json	\
	kana/keymap/hiragana.json		\
	kana/keymap/katakana.json		\
	kana/keymap/latin.json			\
	kana/keymap/wide-latin.json		\
	kana/keymap/direct.json			\
	kana/rom-kana/default.json		\
	$(NULL)
kana_metadata_in =				\
	kana/metadata.json.in			\
	$(NULL)

nobase_rules_DATA =				\
	$(default_files)			\
	$(default_metadata_in:.in=)		\
	$(act_files)				\
	$(act_metadata_in:.in=)			\
	$(azik_files)				\
	$(azik_metadata_in:.in=)		\
	$(kzik_files)				\
	$(kzik_metadata_in:.in=)		\
	$(tutcode_files)			\
	$(tutcode_metadata_in:.in=)		\
	$(tutcode_touch16x_files)		\
	$(tutcode_touch16x_metadata_in:.in=)	\
	$(nicola_files)				\
	$(nicola_metadata_in:.in=)		\
	$(tcode_files)				\
	$(tcode_metadata_in:.in=)		\
	$(trycode_files)			\
	$(trycode_metadata_in:.in=)		\
	$(kana_files)				\
	$(kana_metadata_in:.in=)		\
	README.rules				\
	$(NULL)

EXTRA_DIST =					\
	$(default_files)			\
	$(default_metadata_in)			\
	$(act_files)				\
	$(act_metadata_in)			\
	$(azik_files)				\
	$(azik_metadata_in)			\
	$(kzik_files)				\
	$(kzik_metadata_in)			\
	$(tutcode_files)			\
	$(tutcode_metadata_in)			\
	$(tutcode_touch16x_files)		\
	$(tutcode_touch16x_metadata_in)		\
	$(nicola_files)				\
	$(nicola_metadata_in)			\
	$(tcode_files)				\
	$(tcode_metadata_in)			\
	$(trycode_files)			\
	$(trycode_metadata_in)			\
	$(kana_files)				\
	$(kana_metadata_in)			\
	README.rules				\
	$(NULL)

SUFFIXES = .json .json.in

edit = sed -e 's!\(^ *"[^"]*": *\)_(\("[^"]*"\))!\1\2!g'
.json.in.json:
	rm -f $@ $@.tmp
	srcdir=''; \
	  test -f ./$< || srcdir=$(srcdir)/; \
	  $(edit) $${srcdir}$< >$@.tmp
	mv $@.tmp $@

-include $(top_srcdir)/git.mk
