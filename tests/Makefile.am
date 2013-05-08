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
	LIBKKC_DATA_PATH=$(builddir)/data:${srcdir}/data:$(top_srcdir)/data \
	$(LIBTOOL) --mode=execute $(VALGRIND) $(VALGRIND_OPTS)
TESTS =						\
	basic					\
	context					\
	candidate				\
	candidate-list				\
	segment					\
	segment-list				\
	encoding				\
	system-dictionary			\
	user-dictionary				\
	key-event				\
	keymap					\
	user-rule				\
	rom-kana				\
	expression				\
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

basic_SOURCES = basic.vala

context_SOURCES = context.vala

candidate_SOURCES = candidate.vala

candidate_list_SOURCES = candidate-list.vala

segment_SOURCES = segment.vala

segment_list_SOURCES = segment-list.vala

encoding_SOURCES = encoding.vala

system_dictionary_SOURCES = system-dictionary.vala

user_dictionary_SOURCES = user-dictionary.vala

key_event_SOURCES = key-event.vala

keymap_SOURCES = keymap.vala

user_rule_SOURCES = user-rule.vala

rom_kana_SOURCES = rom-kana.vala

expression_SOURCES = expression.vala

EXTRA_DIST =					\
	file-dict.dat				\
	data/models/sorted3/metadata.json	\
	data/models/text3/metadata.json		\
	data/models/text3/data.arpa		\
	$(NULL)

CLEANFILES =					\
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
	for i in default kana; do \
	  $(mkdir_p) data/rules/$$i; \
	  cp $(top_builddir)/data/rules/$$i/metadata.json data/rules/$$i; \
	  for j in keymap rom-kana; do \
	    $(mkdir_p) data/rules/$$i/$$j; \
	    cp $(top_srcdir)/data/rules/$$i/$$j/*.json data/rules/$$i/$$j; \
	  done; \
	done
	touch $@

models.stamp:
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
	-rm -rf data/rules
	-if test -d data/models/text3; then \
	   rm -rf data/models/sorted3; \
	 else \
	   rm -rf data/models; \
	 fi
	-rm -rf test-user-rule
	-rm -rf test-user-dictionary

-include $(top_srcdir)/git.mk
