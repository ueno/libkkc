rulesdir = $(pkgdatadir)/rules/tcode

files =						\
	keymap/hankaku-katakana.json		\
	keymap/hiragana.json			\
	keymap/katakana.json			\
	keymap/latin.json			\
	keymap/wide-latin.json			\
	rom-kana/default.json			\
	$(NULL)
metadata_in =					\
	metadata.json.in			\
	$(NULL)

nobase_rules_DATA =				\
	$(files)				\
	$(metadata_in:.in=)			\
	$(NULL)

EXTRA_DIST =					\
	$(files)				\
	$(metadata_in)				\
	$(NULL)

CLEANFILES =					\
	metadata.json				\
	$(NULL)

-include $(top_srcdir)/data/rules/rule.mk
-include $(top_srcdir)/git.mk
