#ifndef __MARISA_KEY_H__
#define __MARISA_KEY_H__

#include <glib-object.h>

G_BEGIN_DECLS

#define MARISA_TYPE_KEY (marisa_key_get_type())
#define MARISA_KEY(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), MARISA_TYPE_KEY, MarisaKey))
#define MARISA_KEY_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), MARISA_TYPE_KEY, MarisaKeyClass))
#define MARISA_IS_KEY(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), MARISA_TYPE_KEY))
#define MARISA_IS_KEY_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), MARISA_TYPE_KEY))
#define MARISA_KEY_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), MARISA_TYPE_KEY, MarisaKeyClass))

typedef struct _MarisaKey MarisaKey;
typedef struct _MarisaKeyClass MarisaKeyClass;

GType      marisa_key_get_type   (void) G_GNUC_CONST;
MarisaKey *marisa_key_new        (void);
void       marisa_key_set_string (MarisaKey   *key,
                                  const gchar *str,
                                  gsize        length);
gchar     *marisa_key_get_string (MarisaKey   *key,
                                  gsize       *length);
gsize      marisa_key_get_id     (MarisaKey   *key);
gfloat     marisa_key_get_weight (MarisaKey   *key);
void       marisa_key_clear      (MarisaKey   *key);

G_END_DECLS

#endif
