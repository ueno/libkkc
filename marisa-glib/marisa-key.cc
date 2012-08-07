#include "marisa-glib-private.h"

G_DEFINE_TYPE (MarisaKey, marisa_key, G_TYPE_OBJECT)

static void
marisa_key_finalize (GObject *object)
{
  MarisaKey *key = MARISA_KEY (object);
  delete key->cxx;
  G_OBJECT_CLASS (marisa_key_parent_class)->finalize (object);
}

static void
marisa_key_class_init (MarisaKeyClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  gobject_class->finalize = marisa_key_finalize;
}

static void
marisa_key_init (MarisaKey *key)
{
  key->cxx = new marisa::Key ();
}

MarisaKey *
marisa_key_new (void)
{
  return MARISA_KEY (g_object_new (MARISA_TYPE_KEY, NULL));
}

void
marisa_key_set_string (MarisaKey   *key,
                       const gchar *str,
                       gsize        length)
{
  key->cxx->set_str (str, length);
}

gchar *
marisa_key_get_string (MarisaKey *key,
                       gsize     *length)
{
  if (length != NULL)
    *length = key->cxx->length ();
  return g_strndup (key->cxx->ptr (), key->cxx->length ());
}

gsize
marisa_key_get_id (MarisaKey *key)
{
  return key->cxx->id ();
}

gfloat
marisa_key_get_weight (MarisaKey *key)
{
  return key->cxx->weight ();
}

void
marisa_key_clear (MarisaKey *key)
{
  key->cxx->clear ();
}
