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

        add_test ("initial", this.test_initial);
        add_test ("sentence_conversion", this.test_sentence_conversion);
        add_test ("segment_conversion", this.test_segment_conversion);
    }

    struct ConversionData {
        string keys;
        string input;
        string segments;
        int segments_size;
        int segments_cursor_pos;
        string output;
    }

    void do_conversions (ConversionData[] conversions) {
        foreach (var conversion in conversions) {
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

    static const ConversionData INITIAL_DATA[] = {
        { "a TAB", "あい", "", 0, -1, "" },
        { "k y o", "きょ", "", 0, -1, "" },
        { "k y o DEL", "", "", 0, -1, "" },
        { "k y o F7", "キョ", "", 0, -1, "" },
        { "k y o F10", "kyo", "", 0, -1, "" },
        { "k y o F10 F10", "KYO", "", 0, -1, "" },
        { "k y o F9", "ｋｙｏ", "", 0, -1, "" },
        { "k y o F10 F9", "ｋｙｏ", "", 0, -1, "" },
        { "k y o F9 RET", "", "", 0, -1, "ｋｙｏ" },
        { "w a t a s h i F10 n o", "の", "", 0, -1, "watashi" },
        { "a C-c", "", "", 0, -1, "" }
    };

    public void test_initial () {
        do_conversions (INITIAL_DATA);
    }

    static const ConversionData SENTENCE_CONVERSION_DATA[] = {
        { "k y u u k a SPC C-Right F10",
          "きゅうか",
          "kyuuka",
          1,
          0,
          "" },
        { "1 a n SPC C-Right C-Right SPC",
          "１あん",
          "一案",
          1,
          0,
          "" },
        { "a i SPC",
          "あい",
          "愛",
          1,
          0,
          "" }
    };

    public void test_sentence_conversion () {
        do_conversions (SENTENCE_CONVERSION_DATA);
    }

    static const ConversionData SEGMENT_CONVERSION_DATA[] = {
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

    public void test_segment_conversion () {
        const string PREFIX_KEYS =
            "w a t a s h i n o n a m a e h a n a k a n o d e s u ";

        ConversionData[] conversions =
            new ConversionData[SEGMENT_CONVERSION_DATA.length];

        for (var i = 0; i < SEGMENT_CONVERSION_DATA.length; i++) {
            conversions[i] = SEGMENT_CONVERSION_DATA[i];
            conversions[i].keys = PREFIX_KEYS + SEGMENT_CONVERSION_DATA[i].keys;
        }

        do_conversions (conversions);
    }

    public override void set_up () {
        try {
            new Kkc.SystemSegmentDictionary (
                "test-system-dictionary-nonexistent");
            assert_not_reached ();
        } catch (Error e) {
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

        context.dictionaries.add (new Kkc.EmptySegmentDictionary ());
    }

    public override void tear_down () {
        context.dictionaries.clear ();
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
