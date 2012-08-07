#include "marisa-glib-private.h"

G_DEFINE_TYPE (MarisaTrie, marisa_trie, G_TYPE_OBJECT)

GQuark
marisa_error_quark (void)
{
  return g_quark_from_static_string ("marisa-error-quark");
}

static void
marisa_trie_finalize (GObject *object)
{
  MarisaTrie *trie = MARISA_TRIE (object);
  delete trie->cxx;
  G_OBJECT_CLASS (marisa_trie_parent_class)->finalize (object);
}

static void
marisa_trie_class_init (MarisaTrieClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  gobject_class->finalize = marisa_trie_finalize;
}

static void
marisa_trie_init (MarisaTrie *trie)
{
  trie->cxx = new marisa::Trie ();
}

MarisaTrie *
marisa_trie_new (void)
{
  return MARISA_TRIE (g_object_new (MARISA_TYPE_TRIE, NULL));
}

void
marisa_trie_build (MarisaTrie   *trie,
		   MarisaKeyset *keyset)
{
  trie->cxx->build (*keyset->cxx);
}

gboolean
marisa_trie_mmap (MarisaTrie  *trie,
                  const gchar *filename,
                  GError     **error)
{
  try
    {
      trie->cxx->mmap (filename);
    }
  catch (const marisa::Exception &ex)
    {
      g_set_error (error,
		   G_IO_ERROR,
		   G_IO_ERROR_FAILED,
		   "%s: failed to mmap a dictionary file: %s",
		   ex.what(), filename);
      return FALSE;
    }
  return TRUE;
}

gboolean
marisa_trie_save (MarisaTrie  *trie,
                  const gchar *filename,
                  GError     **error)
{
  try
    {
      trie->cxx->save (filename);
    }
  catch (const marisa::Exception &ex)
    {
      g_set_error (error,
		   G_IO_ERROR,
		   G_IO_ERROR_FAILED,
		   "%s: failed to save a dictionary file: %s",
		   ex.what(), filename);
      return FALSE;
    }
  return TRUE;
}

gboolean
marisa_trie_lookup (MarisaTrie  *trie,
                    MarisaAgent *agent)
{
  return trie->cxx->lookup (*agent->cxx);
}

gboolean
marisa_trie_reverse_lookup (MarisaTrie  *trie,
                            MarisaAgent *agent,
                            GError     **error)
{
  try
    {
      trie->cxx->reverse_lookup (*agent->cxx);
    }
  catch (const marisa::Exception &ex)
    {
      g_set_error (error,
		   MARISA_ERROR,
		   MARISA_ERROR_INVALID_ARGUMENT,
		   "%s: reverse_lookup failed",
		   ex.what());
      return FALSE;
    }
  return TRUE;
}

gboolean
marisa_trie_common_prefix_search (MarisaTrie  *trie,
                                  MarisaAgent *agent)
{
  return trie->cxx->common_prefix_search (*agent->cxx);
}

gboolean
marisa_trie_predictive_search (MarisaTrie  *trie,
                               MarisaAgent *agent)
{
  return trie->cxx->predictive_search (*agent->cxx);
}

void
marisa_trie_clear (MarisaTrie   *trie)
{
  trie->cxx->clear ();
}
