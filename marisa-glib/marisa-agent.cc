#include "marisa-glib-private.h"

G_DEFINE_TYPE (MarisaAgent, marisa_agent, G_TYPE_OBJECT)

static void
marisa_agent_finalize (GObject *object)
{
  MarisaAgent *agent = MARISA_AGENT (object);
  delete agent->cxx;
  G_OBJECT_CLASS (marisa_agent_parent_class)->finalize (object);
}

static void
marisa_agent_class_init (MarisaAgentClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  gobject_class->finalize = marisa_agent_finalize;
}

static void
marisa_agent_init (MarisaAgent *agent)
{
  agent->cxx = new marisa::Agent ();
}

MarisaAgent *
marisa_agent_new (void)
{
  return MARISA_AGENT (g_object_new (MARISA_TYPE_AGENT, NULL));
}

void
marisa_agent_set_query (MarisaAgent *agent,
                        const gchar *str,
                        gsize        length)
{
  agent->cxx->set_query (str, length);
}

void
marisa_agent_set_reverse_query (MarisaAgent *agent,
                                gsize        key_id)
{
  agent->cxx->set_query (key_id);
}

MarisaKey *
marisa_agent_get_key (MarisaAgent *agent)
{
  const marisa::Key *cxxkey = &agent->cxx->key ();
  MarisaKey *key = marisa_key_new ();
  key->cxx->set_str (cxxkey->ptr (), cxxkey->length ());
  key->cxx->set_id (cxxkey->id ());
  return key;
}

void
marisa_agent_clear (MarisaAgent *agent)
{
  agent->cxx->clear ();
}

