AM_CPPFLAGS = -include $(CONFIG_HEADER)

bin_PROGRAMS = kkc

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

-include $(top_srcdir)/git.mk
