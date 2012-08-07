#include "marisa-glib-private.h"

G_DEFINE_TYPE (MarisaKeyset, marisa_keyset, G_TYPE_OBJECT)

static void
marisa_keyset_finalize (GObject *object)
{
  MarisaKeyset *keyset = MARISA_KEYSET (object);
  delete keyset->cxx;
  G_OBJECT_CLASS (marisa_keyset_parent_class)->finalize (object);
}

static void
marisa_keyset_class_init (MarisaKeysetClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  gobject_class->finalize = marisa_keyset_finalize;
}

static void
marisa_keyset_init (MarisaKeyset *keyset)
{
  keyset->cxx = new marisa::Keyset ();
}

MarisaKeyset *
marisa_keyset_new (void)
{
  return MARISA_KEYSET (g_object_new (MARISA_TYPE_KEYSET, NULL));
}

void
marisa_keyset_add (MarisaKeyset    *keyset,
                   const MarisaKey *key)
{
  keyset->cxx->push_back (*key->cxx);
}

MarisaKey *
marisa_keyset_get (MarisaKeyset *keyset,
		   goffset       i)
{
  MarisaKey *key = marisa_key_new ();
  marisa::Key *cxxkey = &(*keyset->cxx)[i];
  key->cxx->set_str (cxxkey->ptr (), cxxkey->length ());
  key->cxx->set_id (cxxkey->id ());
  return key;
}

gsize
marisa_keyset_size (MarisaKeyset *keyset)
{
  return keyset->cxx->size ();
}

void
marisa_keyset_clear (MarisaKeyset *keyset)
{
  keyset->cxx->clear ();
}
