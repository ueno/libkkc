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

SUBDIRS = marisa-glib libkkc tools data tests po
DISTCHECK_CONFIGURE_FLAGS = --enable-docs
ACLOCAL_AMFLAGS = -I m4

if HAVE_VALADOC
SUBDIRS += docs
endif

GITIGNOREFILES =				\
	INSTALL					\
	aclocal.m4				\
	compile					\
	config.guess				\
	config.h.in				\
	config.sub				\
	depcomp					\
	install-sh				\
	ltmain.sh				\
	missing					\
	mkinstalldirs				\
	`find "m4" -type f -name "*.m4" ! -name "vala.m4" -print` \
	$(top_builddir)/lcov.html/*		\
	$(NULL)

distclean-local:
	if test "x$(srcdir)" = "x."; then :; else \
		rm -f ChangeLog; \
	fi

MAINTAINERCLEANFILES =				\
	$(top_builddir)/lcov.info		\
	$(srcdir)/ChangeLog			\
	$(NULL)

EXTRA_DIST = autogen.sh lcov.mk

maintainer-clean-local: maintainer-clean-local-lcov
maintainer-clean-local-lcov:
	rm -rf $(top_builddir)/lcov.html

.PHONY: maintainer-clean-local-lcov

ChangeLog:
	@echo Creating $@
	@if test -d "$(srcdir)/.git"; then \
	  (GIT_DIR=$(top_srcdir)/.git ./missing --run git log --stat) | fmt --split-only > $@.tmp \
	  && mv -f $@.tmp $@ \
	  || ($(RM) $@.tmp; \
	      echo Failed to generate ChangeLog, your ChangeLog may be outdated >&2; \
	      (test -f $@ || echo git-log is required to generate this file >> $@)); \
	else \
	  test -f $@ || \
	  (echo A git checkout and git-log is required to generate ChangeLog >&2 && \
	  echo A git checkout and git-log is required to generate this file >> $@); \
	fi

.PHONY: ChangeLog

# Code coverage support
include $(top_srcdir)/lcov.mk

-include $(top_srcdir)/git.mk
