# Copyright (C) 2011-2013 Daiki Ueno <ueno@unixuser.org>
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

TESTS_ENVIRONMENT =					\
	G_DEBUG=${G_DEBUG:+"${G_DEBUG},"}gc-friendly	\
	G_SLICE=${G_SLICE},always-malloc		\
	$(LIBTOOL) --mode=execute $(VALGRIND) $(VALGRIND_OPTS)
TESTS = basic
noinst_PROGRAMS = $(TESTS)
noinst_HEADERS =

AM_CPPFLAGS =					\
	-DDATADIR=\"$(datadir)\"		\
	-DPKGDATADIR=\"$(pkgdatadir)\"		\
	-I$(top_srcdir) $(LIBKKC_CFLAGS)	\
	-I$(top_srcdir)/tests/lib		\
	-I$(top_builddir)/tests/lib		\
	$(NULL)

LDADD = $(top_builddir)/libkkc/libkkc.la	\
	$(LIBKKC_LIBS)				\
	$(builddir)/lib/libkkc-test.la		\
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
	--pkg kkc-1.0				\
	--pkg kkc-test				\
	-g					\
	$(NULL)

basic_SOURCES = basic.vala

CLEANFILES = valgrind.log.*

-include $(top_srcdir)/git.mk
