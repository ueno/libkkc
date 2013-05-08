class UserDictionaryTests : Kkc.TestCase {
    Kkc.Context context;
    Kkc.UserDictionary user_dictionary;

    public UserDictionaryTests () {
        base ("UserDictionary");

        try {
            Kkc.LanguageModel model = Kkc.LanguageModel.load ("sorted3");
            context = new Kkc.Context (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        add_test ("properties", this.test_properties);
        add_test ("conversion", this.test_conversion);
        add_test ("register", this.test_register);
    }

    void test_properties () {
        bool read_only;
        user_dictionary.get ("read-only", out read_only);
        assert (!read_only);
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
            context.reset ();
            context.clear_output ();
        }
    }

    static const ConversionData CONVERSION_DATA[] = {
        { "SPC",
          "わたしのなまえはなかのです",
          "私の名前は中野です",
          6,
          0,
          "" },
        { "SPC Right Right C-Left RET",
          "",
          "",
          0,
          -1,
          "私のなまえは中野です" },
        { "SPC",
          "わたしのなまえはなかのです",
          "私のなまえは中野です",
          7,
          0,
          "" },
        { "SPC SPC RET",
          "",
          "",
          0,
          -1,
          "渡しのなまえは中野です" },
        { "SPC",
          "わたしのなまえはなかのです",
          "渡しのなまえは中野です",
          7,
          0,
          "" },
        { "SPC Right SPC Right Right SPC",
          "わたしのなまえはなかのです",
          "渡し埜なま回は中野です",
          7,
          3,
          "" }
    };

    void test_conversion () {
        const string PREFIX_KEYS =
            "w a t a s h i n o n a m a e h a n a k a n o d e s u ";

        ConversionData[] conversions =
            new ConversionData[CONVERSION_DATA.length];

        for (var i = 0; i < CONVERSION_DATA.length; i++) {
            conversions[i] = CONVERSION_DATA[i];
            conversions[i].keys = PREFIX_KEYS + CONVERSION_DATA[i].keys;
        }

        do_conversions (conversions);

        context.dictionaries.save ();

        try {
            new Kkc.UserDictionary ("test-user-dictionary");
        } catch (Error e) {
            assert_not_reached ();
        }

        user_dictionary.reload ();
    }

    static const ConversionData REGISTER_DATA[] = {
        { "a i SPC",
          "わたしのなまえはなかのです",
          "私の名前は中のです",
          9,
          0,
          "" },
        { "SPC Right Right Right C-Left RET",
          "",
          "",
          0,
          -1,
          "私の名まえは中のです" },
        { "SPC",
          "わたしのなまえはなかのです",
          "私の名まえは中のです",
          10,
          0,
          "" },
        { "SPC SPC RET",
          "",
          "",
          0,
          -1,
          "渡しの名まえは中のです" },
        { "SPC",
          "わたしのなまえはなかのです",
          "渡しの名まえは中のです",
          10,
          0,
          "" }
    };

    void test_register () {
        var handler_id = context.request_selection_text.connect (() => {
                context.set_selection_text ("abc");
            });
        try {
            context.process_key_events ("A-r a i SPC RET");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events ("a i SPC");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        assert (context.segments.size == 1);
        assert (context.segments.get_output () == "abc");
        context.reset ();
        context.clear_output ();

        context.dictionaries.save ();

        context.disconnect (handler_id);
        context.request_selection_text.connect (() => {
                context.set_selection_text (null);
            });
        try {
            context.process_key_events ("A-r a i SPC");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        context.reset ();
        context.clear_output ();
        
        try {
            new Kkc.UserDictionary ("test-user-dictionary");
        } catch (Error e) {
            assert_not_reached ();
        }

        try {
            context.process_key_events ("a TAB");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events ("a i SPC C-BackSpace");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        context.reset ();
        context.clear_output ();

        try {
            context.process_key_events ("a i SPC");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        assert (context.segments.size == 1);
        assert (context.segments.get_output () != "abc");
        context.reset ();
        context.clear_output ();
    }

    public override void set_up () {
        if (FileUtils.test ("test-user-dictionary", FileTest.EXISTS))
            Kkc.TestUtils.remove_dir ("test-user-dictionary");

        try {
            var srcdir = Environment.get_variable ("srcdir");
            assert (srcdir != null);
            user_dictionary = new Kkc.UserDictionary (
                Path.build_filename (srcdir, "test-user-dictionary"));
            context.dictionaries.add (user_dictionary);
        } catch (Error e) {
            assert_not_reached ();
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
  root.add_suite (new UserDictionaryTests ().get_suite ());

  Test.run ();

  return 0;
}
