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

INCLUDES = -I$(top_srcdir) $(LIBKKC_CFLAGS)

TESTS_ENVIRONMENT =					\
	G_DEBUG=${G_DEBUG:+"${G_DEBUG},"}gc-friendly	\
	G_SLICE=${G_SLICE},always-malloc		\
	LIBKKC_DATA_PATH=$(top_srcdir)			\
	$(LIBTOOL) --mode=execute $(VALGRIND) $(VALGRIND_OPTS)
TESTS = basic
# noinst_PROGRAMS = $(TESTS)
noinst_HEADERS =

AM_CPPFLAGS =								\
	-DLIBKKC_BICLASS_DICT=\"$(top_srcdir)/data/dict/biclass\"	\
	$(NULL)

basic_SOURCES = basic.c
basic_LDADD = $(top_builddir)/libkkc/libkkc.la $(LIBKKC_LIBS)

CLEANFILES = valgrind.log.*

-include $(top_srcdir)/git.mk
