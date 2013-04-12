#ifndef __MARISA_TRIE_H__
#define __MARISA_TRIE_H__

#include <marisa-glib/marisa-keyset.h>

G_BEGIN_DECLS

#define MARISA_TYPE_TRIE (marisa_trie_get_type())
#define MARISA_TRIE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), MARISA_TYPE_TRIE, MarisaTrie))
#define MARISA_TRIE_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), MARISA_TYPE_TRIE, MarisaTrieClass))
#define MARISA_IS_TRIE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), MARISA_TYPE_TRIE))
#define MARISA_IS_TRIE_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), MARISA_TYPE_TRIE))
#define MARISA_TRIE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), MARISA_TYPE_TRIE, MarisaTrieClass))

typedef struct _MarisaTrie MarisaTrie;
typedef struct _MarisaTrieClass MarisaTrieClass;

GType       marisa_trie_get_type             (void) G_GNUC_CONST;
MarisaTrie *marisa_trie_new                  (void);
void        marisa_trie_build                (MarisaTrie   *trie,
                                              MarisaKeyset *keyset);
gboolean    marisa_trie_mmap                 (MarisaTrie   *trie,
                                              const gchar  *filename,
                                              GError      **error);
gboolean    marisa_trie_save                 (MarisaTrie   *trie,
                                              const gchar  *filename,
                                              GError      **error);
gboolean    marisa_trie_lookup               (MarisaTrie   *trie,
                                              MarisaAgent  *agent);
gboolean    marisa_trie_reverse_lookup       (MarisaTrie   *trie,
                                              MarisaAgent  *agent,
                                              GError      **error);
gboolean    marisa_trie_common_prefix_search (MarisaTrie   *trie,
                                              MarisaAgent  *agent);
gboolean    marisa_trie_predictive_search    (MarisaTrie   *trie,
                                              MarisaAgent  *agent);

void        marisa_trie_clear                (MarisaTrie   *trie);

G_END_DECLS

#endif
