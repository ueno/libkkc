#ifndef __MARISA_GLIB_H__
#define __MARISA_GLIB_H__ 1

#include <marisa-glib/marisa-key.h>
#include <marisa-glib/marisa-keyset.h>
#include <marisa-glib/marisa-agent.h>
#include <marisa-glib/marisa-trie.h>
#include <gio/gio.h>

GQuark marisa_error_quark (void);

#define MARISA_ERROR marisa_error_quark ()
typedef enum {
  MARISA_ERROR_INVALID_ARGUMENT,
  MARISA_ERROR_FAILED
} MarisaErrorEnum;

#endif
