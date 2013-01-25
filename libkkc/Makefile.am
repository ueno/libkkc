# Copyright (C) 2012 Daiki Ueno <ueno@gnu.org>
# Copyright (C) 2012 Red Hat, Inc.

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

# force include config.h before gi18n.h.
AM_CPPFLAGS = -include $(CONFIG_HEADER)

lib_LTLIBRARIES = libkkc.la

libkkc_la_VALAFLAGS =						\
	--includedir=libkkc					\
	-H libkkc.h						\
	--vapi kkc-@KKC_API_VERSION@.vapi			\
	-h libkkc-internals.h					\
	--vapidir=.						\
	--vapidir=$(top_srcdir)/marisa-glib			\
	--pkg config						\
	--pkg glib-2.0						\
	--pkg gio-2.0						\
	--pkg gee-1.0						\
	--pkg json-glib-1.0					\
	--pkg posix						\
	--pkg marisa-glib					\
	--internal-vapi kkc-internals-@KKC_API_VERSION@.vapi	\
	--library kkc-@KKC_API_VERSION@				\
	--gir Kkc-@KKC_API_VERSION@.gir				\
	--symbols libkkc.symbols				\
	$(VALAFLAGS)						\
	$(NULL)

libkkc_la_CFLAGS =				\
	$(CODE_COVERAGE_CFLAGS)			\
	$(LIBKKC_CFLAGS)			\
	-DPKGDATADIR=\"$(pkgdatadir)\"		\
	$(NULL)
libkkc_la_LIBADD = $(LIBKKC_LIBS) $(top_builddir)/marisa-glib/libmarisa-glib.la
libkkc_la_LDFLAGS =							\
	$(CODE_COVERAGE_LDFLAGS)					\
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)"	\
	-export-dynamic							\
	-export-symbols $(srcdir)/libkkc.symbols			\
	$(NULL)

libkkcincludedir = $(includedir)/libkkc
libkkcinclude_HEADERS = libkkc.h

libkkc_shell_sources =				\
	candidate-list.vala			\
	candidate.vala				\
	key-event-filter.vala			\
	key-event.vala				\
	keymap.vala				\
	keysyms.vala				\
	map-file.vala				\
	nicola.vala				\
	rom-kana-utils.vala			\
	rom-kana.vala				\
	rule.vala				\
	context.vala				\
	state.vala				\
	dictionary.vala				\
	segment-dictionary.vala			\
	system-segment-dictionary.vala		\
	user-segment-dictionary.vala		\
	sentence-dictionary.vala		\
	user-sentence-dictionary.vala		\
	user-dictionary.vala			\
	encoding.vala				\
	template.vala				\
	numeric-template.vala			\
	expression.vala				\
	$(NULL)

libkkc_la_SOURCES =				\
	trellis-node.vala			\
	language-model.vala			\
	text-bigram-language-model.vala		\
	text-trigram-language-model.vala	\
	sorted-bigram-language-model.vala	\
	sorted-trigram-language-model.vala	\
	language-model-utils.vala		\
	decoder.vala				\
	bigram-decoder.vala			\
	trigram-decoder.vala			\
	segment-list.vala			\
	segment.vala				\
	$(libkkc_shell_sources)			\
	utils.vala				\
	kkc.vala				\
	$(NULL)

if HAVE_INTROSPECTION
girdir = $(datadir)/gir-1.0
gir_DATA = Kkc-@KKC_API_VERSION@.gir

typelibdir = $(libdir)/girepository-1.0
typelib_DATA = Kkc-@KKC_API_VERSION@.typelib

Kkc-@KKC_API_VERSION@.typelib: Kkc-@KKC_API_VERSION@.gir
	@INTROSPECTION_COMPILER@ --shared-library=libkkc -o $@ $^
endif

Kkc-@KKC_API_VERSION@.gir kkc-internals-@KKC_API_VERSION@.vapi kkc-@KKC_API_VERSION@.vapi: libkkc.la

GITIGNOREFILES =				\
	$(libkkc_la_SOURCES:.vala=.c)		\
	libkkc_la_vala.stamp			\
	libkkc.h				\
	libkkc-internals.h			\
	libkkc.symbols				\
	$(NULL)

CLEANFILES =					\
	kkc-@KKC_API_VERSION@.vapi		\
	kkc-internals-@KKC_API_VERSION@.vapi	\
	Kkc-@KKC_API_VERSION@.typelib		\
	Kkc-@KKC_API_VERSION@.gir		\
	libkkc.pc				\
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libkkc.pc

vapi_DATA = kkc-1.0.vapi kkc-1.0.deps
vapidir = $(datadir)/vala/vapi

EXTRA_DIST = config.vapi kkc-1.0.deps libkkc.symbols

-include $(top_srcdir)/git.mk
