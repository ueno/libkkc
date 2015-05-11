rulesdir = $(pkgdatadir)/rules/kana

files =						\
	keymap/default.json			\
	keymap/hankaku-katakana.json		\
	keymap/hiragana.json			\
	keymap/katakana.json			\
	keymap/latin.json			\
	keymap/wide-latin.json			\
	keymap/direct.json			\
	rom-kana/default.json			\
	metadata.json				\
	$(NULL)

nobase_rules_DATA =				\
	$(files)				\
	$(NULL)

EXTRA_DIST =					\
	$(files)				\
	$(NULL)

include $(top_srcdir)/data/rules/rule.mk
-include $(top_srcdir)/git.mk
