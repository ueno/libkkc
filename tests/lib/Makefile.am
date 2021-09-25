noinst_LTLIBRARIES = libkkc-test.la

libkkc_test_la_SOURCES = test-case.vala test-utils.vala

libkkc_test_la_CFLAGS =				\
	$(AM_CFLAGS)				\
	$(LIBKKC_CFLAGS)				\
	$(NULL)

libkkc_test_la_CPPFLAGS =			\
	$(AM_CPPFLAGS)				\
	-I$(top_srcdir)				\
	-I$(top_builddir)			\
	$(NULL)

libkkc_test_la_LIBADD =					\
	$(AM_LIBADD)					\
	$(top_builddir)/libkkc/libkkc-internals.la	\
	$(LIBKKC_LIBS)					\
	$(NULL)

libkkc_test_la_VALAFLAGS =			\
	$(ERROR_VALAFLAGS)			\
	$(VALAFLAGS)				\
	--vapidir=$(top_srcdir)/libkkc		\
	--pkg gobject-2.0			\
	--pkg gio-2.0				\
	--pkg gee-0.8				\
	--pkg json-glib-1.0			\
	--pkg kkc-internals-1.0			\
	--library kkc-test			\
	-H libkkc-test.h			\
	-g					\
	$(NULL)

MAINTAINERCLEANFILES =				\
	$(libkkc_test_la_SOURCES:.vala=.c)	\
	libkkc_test_la_vala.stamp		\
	libkkc-test.h				\
	kkc-test.vapi				\
	$(NULL)

EXTRA_DIST =					\
	$(MAINTAINERCLEANFILES)			\
	$(NULL)

-include $(top_srcdir)/git.mk
