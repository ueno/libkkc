# Copyright (C) 2012 Daiki Ueno <ueno@unixuser.org>
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

noinst_LTLIBRARIES = libmarisa-glib.la

libmarisa_glib_la_sources = marisa-key.cc marisa-keyset.cc marisa-agent.cc marisa-trie.cc
libmarisa_glib_la_headers = marisa-key.h marisa-keyset.h marisa-agent.h marisa-trie.h
libmarisa_glib_la_SOURCES = $(libmarisa_glib_la_sources)
libmarisa_glib_la_CXXFLAGS = $(GIO_CFLAGS) $(MARISA_CFLAGS) -I$(top_srcdir)
libmarisa_glib_la_CFLAGS = $(GIO_CFLAGS) $(MARISA_CFLAGS) -I$(top_srcdir)
libmarisa_glib_la_LIBADD = $(GIO_LIBS) $(MARISA_LIBS)

noinst_HEADERS = marisa-glib.h marisa-glib-private.h $(libmarisa_glib_la_headers)

-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS =
INTROSPECTION_SCANNER_ARGS = --add-include-path=$(builddir)
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)

CLEANFILES =
EXTRA_DIST =
MAINTAINERCLEANFILES =

if HAVE_INTROSPECTION
Marisa.gir: libmarisa-glib.la
Marisa_gir_SCANNERFLAGS = --pkg-export=marisa-glib --pkg=marisa --namespace=Marisa
Marisa_gir_INCLUDES = GLib-2.0 GObject-2.0 Gio-2.0
Marisa_gir_CFLAGS = $(libmarisa_glib_la_CFLAGS)
Marisa_gir_LIBS = libmarisa-glib.la stdc++
Marisa_gir_FILES = $(libmarisa_glib_la_sources) $(libmarisa_glib_la_headers)

INTROSPECTION_GIRS += Marisa.gir

CLEANFILES += $(gir_DATA) $(typelib_DATA)
endif

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = marisa-glib.vapi marisa-glib.deps

marisa-glib.vapi: Marisa.metadata Marisa-custom.vala | Marisa.gir
	$(VAPIGEN) --pkg=gio-2.0 --library=marisa-glib --metadatadir=$(srcdir) Marisa.gir $(srcdir)/Marisa-custom.vala

BUILT_SOURCES = marisa-glib.vapi
MAINTAINERCLEANFILES += $(BUILT_SOURCES)
EXTRA_DIST +=					\
	Marisa.metadata	\
	Marisa-custom.vala	\
	$(NULL)

-include $(top_srcdir)/git.mk
