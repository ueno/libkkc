SUFFIXES = .json .json.in

edit = sed -e 's!\(^ *"[^"]*": *\)_(\("[^"]*"\))!\1\2!g'
.json.in.json:
	rm -f $@ $@.tmp
	srcdir=''; \
	  test -f ./$< || srcdir=$(srcdir)/; \
	  $(edit) $${srcdir}$< >$@.tmp
	mv $@.tmp $@
