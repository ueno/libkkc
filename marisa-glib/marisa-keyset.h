#ifndef __MARISA_KEYSET_H__
#define __MARISA_KEYSET_H__ 1

#include <glib-object.h>

G_BEGIN_DECLS

#define MARISA_TYPE_KEYSET (marisa_keyset_get_type())
#define MARISA_KEYSET(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), MARISA_TYPE_KEYSET, MarisaKeyset))
#define MARISA_KEYSET_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), MARISA_TYPE_KEYSET, MarisaKeysetClass))
#define MARISA_IS_KEYSET(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), MARISA_TYPE_KEYSET))
#define MARISA_IS_KEYSET_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), MARISA_TYPE_KEYSET))
#define MARISA_KEYSET_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), MARISA_TYPE_KEYSET, MarisaKeysetClass))

typedef struct _MarisaKeyset MarisaKeyset;
typedef struct _MarisaKeysetClass MarisaKeysetClass;

GType         marisa_keyset_get_type (void) G_GNUC_CONST;
MarisaKeyset *marisa_keyset_new      (void);
void          marisa_keyset_add      (MarisaKeyset    *keyset,
                                      const MarisaKey *key);
/**
 * marisa_keyset_get:
 * @keyset: a #MarisaKeyset
 * @i: index of a key
 *
 * Obtain a key indexed by @i in @keyset.
 * Returns: (transfer full): a #MarisaKey
 */
MarisaKey    *marisa_keyset_get      (MarisaKeyset    *keyset,
                                      goffset          i);
gsize         marisa_keyset_size     (MarisaKeyset    *keyset);
void          marisa_keyset_clear    (MarisaKeyset    *keyset);

G_END_DECLS

#endif
