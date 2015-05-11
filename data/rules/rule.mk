SUFFIXES = .json .pot

.json.pot:
	$(AM_V_GEN) rm -f $@ $@.tmp; \
	srcdir=''; \
	  test -f ./$< || srcdir=$(srcdir)/; \
	  $(top_builddir)/tools/gen-metadata-pot $${srcdir}$< \
            '$$.name' '$$.description' >$@.tmp && mv $@.tmp $@

# 'make check' in po/ requires metadata.pot
check-local: metadata.pot

metadata.pot: metadata.json $(top_srcdir)/tools/gen-metadata-pot.c

EXTRA_DIST += metadata.pot
