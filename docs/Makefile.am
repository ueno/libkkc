distclean_dirs = \
	libkkc \
	gtk-doc \
	$(NULL)

docs = \
	libkkc-doc \
	libkkc-gtk-doc \
	$(NULL)

libkkcdocdir=$(datadir)/devhelp/references/libkkc
libkkcimgdir=$(datadir)/devhelp/references/libkkc/img

libkkcgtkdocdir=$(datadir)/gtk-doc/html/libkkc

common_doc_files = \
	*.css \
	*.png \
	*.js \
	index.htm \
	*.html \
	$(NULL)

libkkcdoc_DATA = \
	libkkc/libkkc/libkkc.devhelp2 \
	$(addprefix libkkc/libkkc/,$(common_doc_files)) \
	$(NULL)

libkkcgtkdoc_DATA = gtk-doc/libkkc/html/*

$(libkkcdoc_DATA) $(libkkcimg_DATA): libkkc-doc.stamp
$(libkkcgtkdoc_DATA): libkkc-gtk-doc.stamp

valadoc_flags = \
	--force \
	--package-version $(PACKAGE_VERSION) \
	$(NULL)

# libkkc documentation
libkkc_doc_files_blacklist = \
	$(top_srcdir)/libkkc/kana-kan.vala \
	$(NULL)
# this expands the list of files, so we can filter out elements
libkkc_doc_files_all = \
	$(wildcard $(top_srcdir)/libkkc/*.vala) \
	$(NULL)
# FIXME: sort the files manually to work around the native doclet portion of
# bgo#662784
libkkc_doc_files = \
	$(sort \
	$(filter-out $(libkkc_doc_files_blacklist),$(libkkc_doc_files_all)))
libkkc_doc_deps = \
	config \
	glib-2.0 \
	gio-2.0 \
	gee-1.0 \
	posix \
	json-glib-1.0 \
	marisa-glib \
	$(NULL)
valadoc_flags_libkkc = \
	$(valadoc_flags) \
	-D VALA_0_16 \
	-X $(top_srcdir)/libkkc/libkkc.h \
	$(addprefix --pkg=,$(libkkc_doc_deps)) \
	--vapidir=$(top_srcdir)/libkkc \
	--vapidir=$(top_builddir)/libkkc \
	--vapidir=$(top_srcdir)/marisa-glib \
	--vapidir=$(top_builddir)/marisa-glib \
	$(libkkc_doc_files) \
	$(NULL)

libkkc-doc.stamp: $(libkkc_doc_files)
	$(AM_V_GEN)$(VALADOC) \
		-o libkkc/ \
		--doclet=devhelp \
		$(valadoc_flags_libkkc) \
		$(NULL)
	@touch $@

libkkc-gtk-doc.stamp: $(libkkc_doc_files)
	$(AM_V_GEN)$(VALADOC) \
		-X -l -X $(top_builddir)/libkkc/.libs/libkkc.so \
		-o gtk-doc/libkkc \
		--doclet=gtkdoc \
		$(valadoc_flags_libkkc) \
		$(NULL)
	@touch $@

stamps = $(addsuffix .stamp, $(docs))

all: $(stamps)

CLEANFILES = $(stamps)

distclean-local: distclean-docs
distclean-docs:
	rm -rf $(distclean_dirs)

GITIGNOREFILES = \
	libkkc/ \
	gtk-doc/ \
	$(NULL)

-include $(top_srcdir)/git.mk
