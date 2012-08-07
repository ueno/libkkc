#include "marisa-glib.h"
#include <marisa/key.h>
#include <marisa/keyset.h>
#include <marisa/agent.h>
#include <marisa/trie.h>

struct _MarisaKey
{
  /*< private >*/
  GObject parent;
  marisa::Key *cxx;
};

struct _MarisaKeyClass
{
  /*< private >*/
  GObjectClass parent_class;
};

struct _MarisaKeyset
{
  /*< private >*/
  GObject parent;
  marisa::Keyset *cxx;
};

struct _MarisaKeysetClass
{
  /*< private >*/
  GObjectClass parent_class;
};

struct _MarisaAgent
{
  /*< private >*/
  GObject parent;
  marisa::Agent *cxx;
};

struct _MarisaAgentClass
{
  /*< private >*/
  GObjectClass parent_class;
};

struct _MarisaTrie
{
  /*< private >*/
  GObject parent;
  marisa::Trie *cxx;
};

struct _MarisaTrieClass
{
  /*< private >*/
  GObjectClass parent_class;
};
