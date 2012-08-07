# From http://cgit.freedesktop.org/telepathy/telepathy-glib/tree/tools/lcov.am

lcov-reset:
	lcov --directory @top_srcdir@ --zerocounters

lcov-report:
	lcov --directory @top_srcdir@ --capture \
		--output-file @top_builddir@/lcov.info
	$(mkdir_p) @top_builddir@/lcov.html
	git_commit=`GIT_DIR=@top_srcdir@/.git git log -1 --pretty=format:%h 2>/dev/null`;\
	genhtml --title "@PACKAGE_STRING@ $$git_commit" \
		--output-directory @top_builddir@/lcov.html lcov.info
	@echo
	@echo 'lcov report can be found in:'
	@echo 'file://@abs_top_builddir@/lcov.html/index.html'
	@echo

lcov-check:
	$(MAKE) lcov-reset
	$(MAKE) check $(LCOV_CHECK_ARGS)
	$(MAKE) lcov-report

## vim:set ft=automake:
