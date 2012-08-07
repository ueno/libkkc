#ifndef __MARISA_AGENT_H__
#define __MARISA_AGENT_H__ 1

#include <marisa-glib/marisa-key.h>

G_BEGIN_DECLS

#define MARISA_TYPE_AGENT (marisa_agent_get_type())
#define MARISA_AGENT(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), MARISA_TYPE_AGENT, MarisaAgent))
#define MARISA_AGENT_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), MARISA_TYPE_AGENT, MarisaAgentClass))
#define MARISA_IS_AGENT(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), MARISA_TYPE_AGENT))
#define MARISA_IS_AGENT_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), MARISA_TYPE_AGENT))
#define MARISA_AGENT_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), MARISA_TYPE_AGENT, MarisaAgentClass))

typedef struct _MarisaAgent MarisaAgent;
typedef struct _MarisaAgentClass MarisaAgentClass;

GType        marisa_agent_get_type          (void) G_GNUC_CONST;
MarisaAgent *marisa_agent_new               (void);
void         marisa_agent_set_query         (MarisaAgent *agent,
                                             const gchar *str,
                                             gsize        length);
void         marisa_agent_set_reverse_query (MarisaAgent *agent,
                                             gsize        key_id);
/**
 * marisa_agent_get_key:
 * @agent: a #MarisaKey
 *
 * Get key set in @agent.
 * Returns: (transfer full): a #MarisaKey
 */
MarisaKey   *marisa_agent_get_key           (MarisaAgent *agent);
void         marisa_agent_clear             (MarisaAgent *agent);

G_END_DECLS

#endif
