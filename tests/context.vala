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
        add_test ("conversion-simple", this.test_conversion_simple);
        add_test ("conversion", this.test_conversion);
    }

    struct InitialData {
        string keys;
        string input;
        string output;
    }

    static const InitialData[] initial_data = {
        { "k y o", "きょ", "" },
        { "k y o DEL", "", "" },
        { "k y o F7", "キョ", "" },
        { "k y o F10", "kyo", "" },
        { "k y o F10 F10", "KYO", "" },
        { "k y o F9", "ｋｙｏ", "" },
        { "k y o F10 F9", "ｋｙｏ", "" },
        { "k y o F9 RET", "", "ｋｙｏ" },
        { "w a t a s h i F10 n o", "の", "watashi" }
    };

    public void test_initial () {
        foreach (var initial in initial_data) {
            context.process_key_events (initial.keys);
            var output = context.poll_output ();
            assert (output == initial.output);
            assert (context.input == initial.input);
            context.reset ();
            context.clear_output ();
        }
    }

    struct ConversionData {
        string keys;
        string input;
        string segments;
        int segments_size;
        int segments_cursor_pos;
        string output;
    }

    static const ConversionData[] conversion_simple_data = {
        { "k y u u k a SPC C-Right F10",
          "きゅうか",
          "kyuuka",
          1,
          0,
          ""
        }
    };

    public void test_conversion_simple () {
        foreach (var conversion in conversion_simple_data) {
            context.process_key_events (conversion.keys);
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

    static const string CONVERSION_PREFIX_KEYS =
      "w a t a s h i n o n a m a e h a n a k a n o d e s u ";

    static const ConversionData[] conversion_data = {
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
          "私の名間えは中のです" },
        { "SPC Right F10",
          "わたしのなまえはなかのです",
          "私no名前は中のです",
          9,
          1,
          "" },
        { "SPC F10 F10",
          "わたしのなまえはなかのです",
          "WATASHIの名前は中のです",
          9,
          0,
          "" }
    };

    public void test_conversion () {
        foreach (var conversion in conversion_data) {
            context.process_key_events (CONVERSION_PREFIX_KEYS + conversion.keys);
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
