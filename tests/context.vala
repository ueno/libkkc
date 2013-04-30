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
            var srcdir = Environment.get_variable ("srcdir");
            assert (srcdir != null);
            var dictionary = new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "file-dict.dat"));
            context.dictionaries.add (dictionary);
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }

        add_test ("initial", this.test_initial);
        add_test ("conversion", this.test_conversion);
    }

    public void test_initial () {
        context.process_key_events ("k y o");
        assert (context.input == "きょ");
        context.process_key_events ("DEL");
        assert (context.input == "");
        context.reset ();
        context.clear_output ();

        context.process_key_events ("k y o");
        assert (context.input == "きょ");
        context.process_key_events ("F10");
        assert (context.input == "kyo");
        context.process_key_events ("F10");
        assert (context.input == "KYO");
        context.process_key_events ("F9");
        assert (context.input == "ｋｙｏ");
        context.process_key_events ("F7");
        assert (context.input == "キョ");
        context.process_key_events ("DEL");
        assert (context.input == "きょ");
        context.process_key_events ("F9");
        assert (context.input == "ｋｙｏ");
        context.process_key_events ("RET");
        assert (context.input == "");
        assert (context.poll_output () == "ｋｙｏ");
        context.reset ();
        context.clear_output ();

        context.process_key_events ("w a t a s h i F10 n o");
        assert (context.input == "の");
        assert (context.poll_output () == "watashi");
        context.reset ();
        context.clear_output ();

        context.process_key_events ("w a t a s h i n o n a m a e h a n a k a n o d e s u SPC Right F10");
        assert (context.segments.get_output () == "私no名前は中のです");
        context.reset ();
        context.clear_output ();

        context.process_key_events ("w a t a s h i n o n a m a e h a n a k a n o d e s u SPC F10 F10");
        assert (context.segments.get_output () == "WATASHIの名前は中のです");
        context.reset ();
        context.clear_output ();
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
          "私の名前は中のです",
          9,
          0,
          "" },
        { "SPC Left",
          "わたしのなまえはなかのです",
          "私の名前は中のです",
          9,
          0,
          "" },
        { "SPC Right",
          "わたしのなまえはなかのです",
          "私の名前は中のです",
          9,
          1,
          "" },
        { "SPC Right C-Right",
          "わたしのなまえはなかのです",
          "私のな前は中のです",
          8,
          1,
          "" },
        { "SPC Right Right Right C-Left",
          "わたしのなまえはなかのです",
          "私の名まえは中のです",
          10,
          3,
          "" },
        { "SPC SPC",
          "わたしのなまえはなかのです",
          "渡しの名前は中のです",
          9,
          0,
          "" },
        { "SPC SPC Right",
          "わたしのなまえはなかのです",
          "渡しの名前は中のです",
          9,
          1,
          "" },
        { "SPC SPC Right SPC",
          "わたしのなまえはなかのです",
          "渡し埜名前は中のです",
          9,
          1,
          "" },
        { "SPC SPC Right SPC SPC",
          "わたしのなまえはなかのです",
          "渡し之名前は中のです",
          9,
          1,
          "" },
        { "SPC Right Right Right C-Left SPC RET",
          "",
          "",
          0,
          -1,
          "私の名間えは中のです" }
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
