#include <libkkc/libkkc.h>
#include <stdio.h>

struct _KkcFixture {
  KkcDict *dict;
};
typedef struct _KkcFixture KkcFixture;

static void
dict_setup (KkcFixture *fixture, gconstpointer data)
{
  GError *error = NULL;
  fixture->dict = KKC_DICT (kkc_biclass_dict_new (LIBKKC_BICLASS_DICT, &error));
  g_assert_no_error (error);
}

static void
dict_teardown (KkcFixture *fixture, gconstpointer data)
{
  g_object_unref (fixture->dict);
} 

static void
basic (KkcFixture *fixture, gconstpointer data)
{
  gint i;
  static const gchar *sentences[] =
    {
      "けいざいはきゅうこうか",
      "しごとのことをかんがえる",
      "さきにくる",
      "てつだったが",
      "わたしのなまえはなかのです",
    };

  for (i = 0; i < G_N_ELEMENTS (sentences); i++)
    {
      KkcTrellis *trellis;
      KkcSegment **segments;
      gint n_segments;
      int j;

      trellis = kkc_trellis_new (fixture->dict, sentences[i], NULL, 0);
      segments = kkc_trellis_search (trellis, 10, &n_segments);

      for (j = 0; j < n_segments; j++)
        {
          KkcSegment *segment = segments[j];
          printf ("%d: ", j);
          while (segment)
            {
              printf ("<%s/%s>",
                      kkc_segment_get_input (segment),
                      kkc_segment_get_output (segment));
              segment = segment->next;
            }
          printf ("\n");
        }

      for (j = 0; j < n_segments; j++)
        {
          KkcSegment *segment = segments[j];
          while (segment)
            {
              KkcSegment *next = segment->next;
              segment->next = NULL;
              kkc_segment_unref (segment);
              segment = next;
            }
        }

      g_object_unref (trellis);
    }
}

static void
basic_with_constraint (KkcFixture *fixture, gconstpointer data)
{
  gint constraints[] = { 4, 5 };
  KkcTrellis *trellis;
  KkcSegment **segments;
  gint n_segments;
  gint i;

  trellis = kkc_trellis_new (KKC_DICT (fixture->dict),
                             "けいざいはきゅうこうか",
                             (gint *) &constraints, G_N_ELEMENTS (constraints));
  segments = kkc_trellis_search (trellis, 10, &n_segments);

  for (i = 0; i < n_segments; i++)
    {
      KkcSegment *segment = segments[i];
      printf ("%d: ", i);
      while (segment)
        {
          printf ("<%s/%s>",
                  kkc_segment_get_input (segment),
                  kkc_segment_get_output (segment));
          segment = segment->next;
        }
      printf ("\n");
    }

  for (i = 0; i < n_segments; i++)
    {
      KkcSegment *segment = segments[i];
      while (segment)
        {
          KkcSegment *next = segment->next;
          segment->next = NULL;
          kkc_segment_unref (segment);
          segment = next;
        }
    }

  g_object_unref (trellis);
}

int
main (int argc, char **argv)
{
  g_type_init ();
  kkc_init ();

  g_test_init (&argc, &argv, NULL);

  g_test_add ("/libkkc/basic",
              KkcFixture, NULL,
              dict_setup, basic, dict_teardown);
  g_test_add ("/libkkc/basic_with_constraint",
              KkcFixture, NULL,
              dict_setup, basic_with_constraint, dict_teardown);

  return g_test_run ();
}
