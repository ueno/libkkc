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

SUBDIRS = lib .

TESTS_ENVIRONMENT =							    \
	G_DEBUG=${G_DEBUG:+"${G_DEBUG},"}gc-friendly			    \
	G_SLICE=${G_SLICE},always-malloc				    \
	LIBKKC_DATA_PATH=$(builddir)/data:${srcdir}/data:$(top_srcdir)/data
LOG_COMPILER = $(LIBTOOL) --mode=execute $(VALGRIND) $(VALGRIND_OPTS)
TESTS =						\
	decoder					\
	context					\
	state					\
	candidate				\
	candidate-list				\
	segment					\
	segment-list				\
	trellis-node				\
	encoding				\
	metadata-file				\
	language-model				\
	system-dictionary			\
	user-dictionary				\
	dictionary-list				\
	key-event				\
	keymap					\
	user-rule				\
	rom-kana				\
	expression				\
	rule					\
	template				\
	$(NULL)

noinst_PROGRAMS = $(TESTS)
noinst_HEADERS =

AM_CPPFLAGS =					\
	-DDATADIR=\"$(datadir)\"		\
	-DPKGDATADIR=\"$(pkgdatadir)\"		\
	-I$(top_srcdir) $(LIBKKC_CFLAGS)	\
	-I$(top_srcdir)/tests/lib		\
	-I$(top_builddir)/tests/lib		\
	$(NULL)

LDADD = $(top_builddir)/libkkc/libkkc-internals.la	\
	$(LIBKKC_LIBS)					\
	$(builddir)/lib/libkkc-test.la			\
	$(MARISA_GLIB_STATIC_DEPENDENCIES)		\
	$(NULL)

AM_VALAFLAGS =					\
	--disable-warnings			\
	--vapidir=.				\
	--vapidir=$(top_srcdir)/libkkc		\
	--vapidir=$(top_srcdir)/tests/lib	\
	--pkg gobject-2.0			\
	--pkg gio-2.0				\
	--pkg gee-1.0				\
	--pkg config				\
	--pkg json-glib-1.0			\
	--pkg kkc-internals-1.0			\
	--pkg kkc-test				\
	-g					\
	$(NULL)

decoder_SOURCES = decoder.vala

context_SOURCES = context.vala

state_SOURCES = state.vala

candidate_SOURCES = candidate.vala

candidate_list_SOURCES = candidate-list.vala

segment_SOURCES = segment.vala

trellis_node_SOURCES = trellis-node.vala

segment_list_SOURCES = segment-list.vala

encoding_SOURCES = encoding.vala

metadata_file_SOURCES = metadata-file.vala

language_model_SOURCES = language-model.vala

system_dictionary_SOURCES = system-dictionary.vala

user_dictionary_SOURCES = user-dictionary.vala

dictionary_list_SOURCES = dictionary-list.vala

key_event_SOURCES = key-event.vala

keymap_SOURCES = keymap.vala

user_rule_SOURCES = user-rule.vala

rom_kana_SOURCES = rom-kana.vala

expression_SOURCES = expression.vala

rule_SOURCES = rule.vala

template_SOURCES = template.vala

EXTRA_DIST =						\
	system-segment-dictionary			\
	system-segment-dictionary-bad1			\
	system-segment-dictionary-bad2			\
	system-segment-dictionary-bad3			\
	user-segment-dictionary-good			\
	user-segment-dictionary-bad1			\
	user-segment-dictionary-bad2			\
	user-sentence-dictionary-good			\
	user-sentence-dictionary-bad1			\
	user-sentence-dictionary-bad2			\
	metadata.json					\
	metadata-bad1.json				\
	metadata-bad2.json				\
	metadata-bad3.json				\
	metadata-bad4.json				\
	language-model-metadata-bad1.json		\
	language-model-metadata-bad2.json		\
	rule-metadata-bad.json				\
	data/rules/test-empty/metadata.json		\
	data/rules/test-empty/keymap/.gitkeep		\
	data/rules/test-empty/rom-kana/.gitkeep		\
	data/rules/test-bad1/metadata.json		\
	data/rules/test-bad1/keymap/hiragana.json	\
	data/rules/test-bad1/rom-kana/.gitkeep		\
	data/rules/test-bad2/metadata.json		\
	data/rules/test-bad2/keymap/hiragana.json	\
	data/rules/test-bad2/rom-kana/.gitkeep		\
	data/rules/test-bad3/metadata.json		\
	data/rules/test-bad3/keymap/hiragana.json	\
	data/rules/test-bad3/rom-kana/.gitkeep		\
	data/rules/test-bad4/metadata.json		\
	data/rules/test-bad4/keymap/hiragana.json	\
	data/rules/test-bad4/rom-kana/.gitkeep		\
	data/rules/test-bad5/metadata.json		\
	data/rules/test-bad5/keymap/hiragana.json	\
	data/rules/test-bad5/rom-kana/.gitkeep		\
	data/rules/test-bad6/metadata.json		\
	data/rules/test-bad6/keymap/hiragana.json	\
	data/rules/test-bad6/rom-kana/.gitkeep		\
	data/rules/test-bad7/metadata.json		\
	data/rules/test-bad7/keymap/hiragana.json	\
	data/rules/test-bad7/rom-kana/.gitkeep		\
	data/rules/test-bad8/metadata.json		\
	data/rules/test-bad8/keymap/.gitkeep		\
	data/rules/test-bad8/rom-kana/default.json	\
	data/rules/test-bad9/metadata.json		\
	data/rules/test-bad9/keymap/.gitkeep		\
	data/rules/test-bad9/rom-kana/default.json	\
	data/rules/test-bad10/metadata.json		\
	data/rules/test-bad10/keymap/.gitkeep		\
	data/rules/test-bad10/rom-kana/default.json	\
	data/models/sorted2/metadata.json		\
	data/models/sorted3/metadata.json		\
	data/models/text2/metadata.json			\
	data/models/text2/data.arpa			\
	data/models/text3/metadata.json			\
	data/models/text3/data.arpa			\
	conversions-initial.json			\
	conversions-sentence.json			\
	conversions-segment.json			\
	$(NULL)

CLEANFILES =					\
	data/models/sorted2/data.input		\
	data/models/sorted2/data.1gram		\
	data/models/sorted2/data.1gram.index	\
	data/models/sorted2/data.2gram		\
	data/models/sorted2/data.2gram.filter	\
	data/models/sorted3/data.input		\
	data/models/sorted3/data.1gram		\
	data/models/sorted3/data.1gram.index	\
	data/models/sorted3/data.2gram		\
	data/models/sorted3/data.2gram.filter	\
	data/models/sorted3/data.3gram		\
	data/models/sorted3/data.3gram.filter	\
	valgrind.log.*				\
	*.stamp					\
	$(NULL)

$(TESTS): rules.stamp models.stamp
rules.stamp:
	for i in default kana nicola; do \
	  $(MKDIR_P) data/rules/$$i; \
	  cp $(top_builddir)/data/rules/$$i/metadata.json data/rules/$$i; \
	  for j in keymap rom-kana; do \
	    $(MKDIR_P) data/rules/$$i/$$j; \
	    cp $(top_srcdir)/data/rules/$$i/$$j/*.json data/rules/$$i/$$j; \
	  done; \
	done
	touch $@

models.stamp:
	$(MKDIR_P) data/models/sorted2
	test -f data/models/sorted2/metadata.json || \
	  cp -f $(srcdir)/data/models/sorted2/metadata.json data/models/sorted2
	$(PYTHON) -B $(top_srcdir)/data/templates/libkkc-data/tools/sortlm.py \
	  $(srcdir)/data/models/text2/data.arpa data/models/sorted2/data
	$(PYTHON) -B $(top_srcdir)/data/templates/libkkc-data/tools/genfilter.py \
          data/models/sorted2/data.2gram \
          data/models/sorted2/data.2gram.filter \
          12
	$(MKDIR_P) data/models/sorted3
	test -f data/models/sorted3/metadata.json || \
	  cp -f $(srcdir)/data/models/sorted3/metadata.json data/models/sorted3
	$(PYTHON) -B $(top_srcdir)/data/templates/libkkc-data/tools/sortlm.py \
	  $(srcdir)/data/models/text3/data.arpa data/models/sorted3/data
	$(PYTHON) -B $(top_srcdir)/data/templates/libkkc-data/tools/genfilter.py \
          data/models/sorted3/data.2gram \
          data/models/sorted3/data.2gram.filter \
          12
	$(PYTHON) -B $(top_srcdir)/data/templates/libkkc-data/tools/genfilter.py \
          data/models/sorted3/data.3gram \
          data/models/sorted3/data.3gram.filter \
          10
	touch $@

clean-local:
	-test -d data/rules/test-empty || rm -rf data/rules
	-test -d data/models/text2 || rm -rf data/models
	-rm -rf test-user-rule
	-rm -rf test-user-dictionary
	-rm -rf test-user-segment-dictionary
	-rm -rf test-user-sentence-dictionary

-include $(top_srcdir)/git.mk
