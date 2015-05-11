# Copyright (C) 2011-2014 Daiki Ueno <ueno@gnu.org>
# Copyright (C) 2011-2014 Red Hat, Inc.

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

AM_CPPFLAGS = -include $(CONFIG_HEADER)

bin_PROGRAMS = kkc
bin_SCRIPTS = kkc-package-data
noinst_PROGRAMS = gen-metadata-pot

kkc_VALAFLAGS =					\
	--vapidir=$(top_srcdir)/libkkc		\
	--vapidir=$(top_srcdir)/tools		\
	--pkg config				\
	--pkg kkc-1.0				\
	$(VALAFLAGS)

kkc_CFLAGS =					\
	-I$(top_srcdir)				\
	$(LIBKKC_CFLAGS)			\
	-DDATADIR=\"$(datadir)\"		\
	-DPKGDATADIR=\"$(pkgdatadir)\"		\
	-DLOCALEDIR=\"$(datadir)/locale\"	\
	$(NULL)
kkc_LDADD = $(top_builddir)/libkkc/libkkc.la $(LIBKKC_LIBS)
kkc_SOURCES = kkc.vala

gen_metadata_pot_VALAFLAGS = --pkg json-glib-1.0 --pkg posix $(VALAFLAGS)
gen_metadata_pot_SOURCES = gen-metadata-pot.vala
gen_metadata_pot_CFLAGS = $(JSON_GLIB_CFLAGS)
gen_metadata_pot_LDADD = $(JSON_GLIB_LIBS)

DISTCLEANFILES = kkc-package-data
EXTRA_DIST = kkc-package-data.in

-include $(top_srcdir)/git.mk
