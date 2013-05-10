class ContextTests : Kkc.TestCase {
    Kkc.Context context;

    public ContextTests () {
        base ("Context");

        add_test ("properties", this.test_properties);
        add_test ("initial", this.test_initial);
        add_test ("nicola", this.test_nicola);
        add_test ("sentence_conversion", this.test_sentence_conversion);
        add_test ("segment_conversion", this.test_segment_conversion);
    }

    void test_properties () {

        var input_mode = context.input_mode;
        context.input_mode = input_mode;

        var dictionaries = context.dictionaries;
        context.dictionaries = dictionaries;

        var style = context.punctuation_style;
        assert (style == Kkc.PunctuationStyle.JA_JA);
        context.punctuation_style = Kkc.PunctuationStyle.EN_EN;
        try {
            context.process_key_events (". RET");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        assert (context.poll_output () == "．");
        assert (context.punctuation_style == Kkc.PunctuationStyle.EN_EN);
        context.punctuation_style = style;
        context.reset ();
        context.clear_output ();

        var rule = context.typing_rule;
        assert (rule != null);
        assert (rule.metadata.name == "default");

        var metadata = Kkc.Rule.find_rule ("kana");
        context.typing_rule = new Kkc.Rule (metadata);
        context.process_key_event (new Kkc.KeyEvent.from_x_event (132, 0x5c, 0));
        context.typing_rule = rule;

        Kkc.CandidateList candidates;
        Kkc.SegmentList segments;
        string input;
        Kkc.KeyEventFilter filter;

        context.get ("dictionaries", out dictionaries,
                     "candidates", out candidates,
                     "segments", out segments,
                     "input", out input,
                     "input-mode", out input_mode,
                     "punctuation-style", out style,
                     "typing-rule", out rule,
                     "key-event-filter", out filter);
        context.set ("dictionaries", dictionaries,
                     "input-mode", input_mode,
                     "punctuation-style", style,
                     "typing-rule", rule);
    }

    struct ConversionData {
        string keys;
        string input;
        string segments;
        int segments_size;
        int segments_cursor_pos;
        string output;
        int candidates_size;
        int input_cursor_pos;
    }

    void do_conversions (ConversionData[] conversions) {
        foreach (var conversion in conversions) {
            try {
                context.process_key_events (conversion.keys);
            } catch (Kkc.KeyEventFormatError e) {
                assert_not_reached ();
            }
            var output = context.poll_output ();
            assert (output == conversion.output);
            assert (context.input == conversion.input);
            assert (context.segments.get_output () == conversion.segments);
            assert (context.segments.size == conversion.segments_size);
            assert (context.segments.cursor_pos == conversion.segments_cursor_pos);
            assert (context.candidates.size == conversion.candidates_size);
            assert (context.input_cursor_pos == conversion.input_cursor_pos);
            context.reset ();
            context.clear_output ();
        }
    }

    static const ConversionData INITIAL_DATA[] = {
        { "a TAB", "あい", "", 0, -1, "", 0, -1 },
        { "a p u TAB", "あぷ", "", 0, -1, "", 0, -1 },
        { "(shift a) TAB", "あい", "", 0, -1, "", 0, -1 },
        { "a TAB RET", "", "", 0, -1, "あい", 0, -1 },
        { "a TAB C-g", "", "", 0, -1, "", 0, -1 },
        { "C-q a", "a", "", 0, -1, "", 0, -1 },
        { "C-q (shift yen)", "¥", "", 0, -1, "", 0, -1 },
        { "C-g", "", "", 0, -1, "", 0, -1 },
        { "BackSpace", "", "", 0, -1, "", 0, -1 },
        { "Delete", "", "", 0, -1, "", 0, -1 },
        { "TAB", "", "", 0, -1, "", 0, -1 },
        { "SPC", "", "", 0, -1, "", 0, -1 },
        { "Left", "", "", 0, -1, "", 0, -1 },
        { "Right", "", "", 0, -1, "", 0, -1 },
        { "^", "＾", "", 0, -1, "", 0, -1 },
        { "k y BackSpace", "k", "", 0, -1, "", 0, -1 },
        { "F7", "", "", 0, -1, "", 0, -1 },
        { "k y o", "きょ", "", 0, -1, "", 0, -1 },
        { "k y o DEL", "", "", 0, -1, "", 0, -1 },
        { "k y o F7", "キョ", "", 0, -1, "", 0, -1 },
        { "k y o F10", "kyo", "", 0, -1, "", 0, -1 },
        { "k y o F10 F10", "KYO", "", 0, -1, "", 0, -1 },
        { "A-@ k y o A-@", "", "", 0, -1, "", 0, -1 },
        { "A-l k y o F10 A-k", "", "", 0, -1, "kyo", 0, -1 },
        { "k y o F9", "ｋｙｏ", "", 0, -1, "", 0, -1 },
        { "k y o F10 F9", "ｋｙｏ", "", 0, -1, "", 0, -1 },
        { "k y o F9 RET", "", "", 0, -1, "ｋｙｏ", 0, -1 },
        { "w a t a s h i F10 n o", "の", "", 0, -1, "watashi", 0, -1 },
        { "a C-c", "", "", 0, -1, "", 0, -1 },
        { "a i u e o Left Left Right Right BackSpace", "あいうお", "", 0, -1, "", 0, 3 },
        { "a i u e o Left Left Delete", "あいうお", "", 0, -1, "", 0, 3 },
        { "k a k i k u k e k Left Left BackSpace", "かくけ", "", 0, -1, "", 0, 1 },
        { "a i u e o Left Right BackSpace i", "あいういお", "", 0, -1, "", 0, 4 },
        { "a i u e o Left Right BackSpace k", "あいうkお", "", 0, -1, "", 0, 3 },
        { "a i Left Left Left Left BackSpace k", "kあい", "", 0, -1, "", 0, 0 }
    };

    void test_initial () {
        do_conversions (INITIAL_DATA);

        var input_mode = context.input_mode;
        try {
            context.process_key_events ("A-l");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        assert (context.input_mode == Kkc.InputMode.LATIN);
        context.reset ();
        context.clear_output ();
        context.input_mode = input_mode;

        try {
            context.process_key_events ("(alt a)");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events ("(alt");
            assert_not_reached ();
        } catch (Kkc.KeyEventFormatError e) {
        }
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events ("((");
            assert_not_reached ();
        } catch (Kkc.KeyEventFormatError e) {
        }
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events (")");
            assert_not_reached ();
        } catch (Kkc.KeyEventFormatError e) {
        }
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events ("\\(");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events ("foo");
            assert_not_reached ();
        } catch (Kkc.KeyEventFormatError e) {
        }
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events ("a RET");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        assert (context.has_output ());
        assert (context.peek_output () == "あ");
        assert (context.has_output ());
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events ("k C-g");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        context.reset ();
        context.clear_output ();
    }

    void test_nicola () {
        var metadata = Kkc.Rule.find_rule ("nicola");
        context.typing_rule = new Kkc.Rule (metadata);

        // single key - timeout
        context.process_key_events ("a");
        Thread.usleep (200000);
        context.clear_output ();
        context.reset ();

        // single key - release
        context.process_key_events ("a (release a)");
        assert (context.input == "う");
        context.clear_output ();
        context.reset ();

        // single key - overlap
        context.process_key_events ("a");
        Thread.usleep (50000);
        context.process_key_events ("b");
        Thread.usleep (200000);
        context.clear_output ();
        context.reset ();
    }

    static const ConversionData SENTENCE_CONVERSION_DATA[] = {
        { "k y u u k a SPC C-Right C-Right C-Right F10",
          "きゅうか",
          "kyuuka",
          1,
          0,
          "",
          0,
          -1 },
        { "1 a n SPC C-Right C-Right SPC",
          "１あん",
          "一案",
          1,
          0,
          "",
          8,
          -1 },
        { "a i SPC",
          "あい",
          "愛",
          1,
          0,
          "",
          0,
          -1 },
        { "u r u SPC",
          "うる",
          "売る",
          1,
          0,
          "",
          0,
          -1 }
    };

    void test_sentence_conversion () {
        do_conversions (SENTENCE_CONVERSION_DATA);
    }

    static const ConversionData SEGMENT_CONVERSION_DATA[] = {
        { "",
          "わたしのなまえはなかのです",
          "",
          0,
          -1,
          "",
          0,
          -1 },
        { "SPC",
          "わたしのなまえはなかのです",
          "私の名前は中野です",
          6,
          0,
          "",
          0,
          -1 },
        { "SPC Muhenkan",
          "わたしのなまえはなかのです",
          "わたしの名前は中野です",
          6,
          0,
          "",
          0,
          -1 },
        { "SPC RET",
          "",
          "",
          0,
          -1,
          "私の名前は中野です",
          0,
          -1 },
        { "SPC a",
          "あ",
          "",
          0,
          -1,
          "私の名前は中野です",
          0,
          -1 },
        { "SPC (shift a)",
          "あ",
          "",
          0,
          -1,
          "私の名前は中野です",
          0,
          -1 },
        { "SPC (control a)",
          "",
          "",
          0,
          -1,
          "私の名前は中野です",
          0,
          -1 },
        { "SPC TAB",
          "",
          "",
          0,
          -1,
          "私の名前は中野です",
          0,
          -1 },
        { "SPC Left",
          "わたしのなまえはなかのです",
          "私の名前は中野です",
          6,
          0,
          "",
          0,
          -1 },
        { "SPC Right",
          "わたしのなまえはなかのです",
          "私の名前は中野です",
          6,
          1,
          "",
          0,
          -1 },
        { "SPC Right C-Right",
          "わたしのなまえはなかのです",
          "私のな前は中野です",
          6,
          1,
          "",
          0,
          -1 },
        { "SPC Right Right C-Left",
          "わたしのなまえはなかのです",
          "私のなまえは中野です",
          7,
          2,
          "",
          0,
          -1 },
        { "SPC SPC",
          "わたしのなまえはなかのです",
          "渡しの名前は中野です",
          6,
          0,
          "",
          13,
          -1 },
        { "SPC SPC Up",
          "わたしのなまえはなかのです",
          "私の名前は中野です",
          6,
          0,
          "",
          13,
          -1 },
        { "SPC SPC C-g",
          "わたしのなまえはなかのです",
          "",
          0,
          -1,
          "",
          0,
          -1 },
        { "SPC SPC Right",
          "わたしのなまえはなかのです",
          "渡しの名前は中野です",
          6,
          1,
          "",
          13,
          -1 },
        { "SPC SPC Right SPC",
          "わたしのなまえはなかのです",
          "渡し埜名前は中野です",
          6,
          1,
          "",
          8,
          -1 },
        { "SPC SPC Right SPC SPC",
          "わたしのなまえはなかのです",
          "渡し之名前は中野です",
          6,
          1,
          "",
          8,
          -1 },
        { "SPC Right Right C-Left SPC RET",
          "",
          "",
          0,
          -1,
          "私の生えは中野です",
          0,
          -1 },
        { "SPC Right F10",
          "わたしのなまえはなかのです",
          "私no名前は中野です",
          6,
          1,
          "",
          0,
          -1 },
        { "SPC F10 F10",
          "わたしのなまえはなかのです",
          "WATASHIの名前は中野です",
          6,
          0,
          "",
          0,
          -1 }
    };

    void test_segment_conversion () {
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
            var model = Kkc.LanguageModel.load ("sorted3");
            context = new Kkc.Context (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        try {
            var srcdir = Environment.get_variable ("srcdir");
            assert (srcdir != null);
            var dictionary = new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "system-segment-dictionary"));
            context.dictionaries.add (dictionary);
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }

        context.dictionaries.add (new Kkc.EmptySegmentDictionary ());
    }

    public override void tear_down () {
        context = null;
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
