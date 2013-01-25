class ContextTests : Kkc.TestCase {
    Kkc.Context context;

    public ContextTests () {
        base ("Context");

        try {
            Kkc.LanguageModel model = Kkc.LanguageModel.load ("sorted3");
            context = new Kkc.Context (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        try {
            var dict = new Kkc.SystemSegmentDictionary ("file-dict.dat");
            context.add_dictionary (dict);
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }

        try {
            var dict = new Kkc.UserDictionary ("user-dict");
            context.add_dictionary (dict);
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }

        add_test ("conversion", this.test_conversion);
    }

    struct Conversion {
        string keys;
        string input;
        string segments;
        int segments_size;
        int segments_cursor_pos;
        string output;
    }

    static const string PREFIX_KEYS =
      "w a t a s h i n o n a m a e h a n a k a n o d e s u ";

    static const Conversion[] conversions = {
        { "",
          "わたしのなまえはなかのです",
          "",
          0,
          -1,
          "" },
        { "SPC",
          "わたしのなまえはなかのです",
          "わたしの名前は中のです",
          8,
          0,
          "" },
        { "SPC Left",
          "わたしのなまえはなかのです",
          "わたしの名前は中のです",
          8,
          0,
          "" },
        { "SPC Right",
          "わたしのなまえはなかのです",
          "わたしの名前は中のです",
          8,
          1,
          "" },
        { "SPC Right C-Right",
          "わたしのなまえはなかのです",
          "私のな前は中のです",
          8,
          1,
          "" },
        { "SPC Right Right C-Left",
          "わたしのなまえはなかのです",
          "わたしの生絵は中のです",
          9,
          2,
          "" },
        { "SPC SPC",
          "わたしのなまえはなかのです",
          "私の名前は中のです",
          8,
          0,
          "" },
        { "SPC SPC Right",
          "わたしのなまえはなかのです",
          "私の名前は中のです",
          8,
          1,
          "" },
        { "SPC SPC Right SPC",
          "わたしのなまえはなかのです",
          "私埜名前は中のです",
          8,
          1,
          "" },
        { "SPC SPC Right SPC SPC",
          "わたしのなまえはなかのです",
          "私之名前は中のです",
          8,
          1,
          "" },
        { "SPC Right Right C-Left SPC RET",
          "",
          "",
          0,
          -1,
          "わたしの生絵は中のです" }
    };

    public void test_conversion () {
        foreach (var conversion in conversions) {
            context.process_key_events (PREFIX_KEYS + conversion.keys);
            var output = context.poll_output ();
            assert (output == conversion.output);
            assert (context.input == conversion.input);
            assert (context.segments.get_output () == conversion.segments);
            assert (context.segments.size == conversion.segments_size);
            assert (context.segments.cursor_pos == conversion.segments_cursor_pos);
            context.reset ();
            context.clear_output ();
            context.save_dictionaries ();
        }
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new ContextTests ().get_suite ());

  Test.run ();

  return 0;
}
