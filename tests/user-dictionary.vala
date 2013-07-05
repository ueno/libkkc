class UserSegmentDictionaryTests : Kkc.TestCase {
    public UserSegmentDictionaryTests () {
        base ("UserSegmentDictionary");

        add_test ("load", this.test_load);
        add_test ("write", this.test_write);
    }

    void test_load () {
        try {
            new Kkc.UserSegmentDictionary (
                "test-user-segment-dictionary");
        } catch (Error e) {
            assert_not_reached ();
        }

        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);

        try {
            new Kkc.UserSegmentDictionary (
                Path.build_filename (srcdir, "user-segment-dictionary-good"));
        } catch (Error e) {
            assert_not_reached ();
        }

        try {
            new Kkc.UserSegmentDictionary (
                Path.build_filename (srcdir, "user-segment-dictionary-bad1"));
            assert_not_reached ();
        } catch (Error e) {
        }

        try {
            new Kkc.UserSegmentDictionary (
                Path.build_filename (srcdir, "user-segment-dictionary-bad2"));
            assert_not_reached ();
        } catch (Error e) {
        }
    }

    void test_write () {
        Kkc.SegmentDictionary? dictionary = null;
        try {
            dictionary = new Kkc.UserSegmentDictionary (
                "test-user-segment-dictionary");
        } catch (Error e) {
            assert_not_reached ();
        }

        dictionary.select_candidate (
            new Kkc.Candidate ("あい", false, "愛"));
        dictionary.select_candidate (
            new Kkc.Candidate ("あお", false, "青"));
        dictionary.select_candidate (
            new Kkc.Candidate ("あ お", false, "青"));
        dictionary.select_candidate (
            new Kkc.Candidate ("あu", true, "会u"));
        dictionary.select_candidate (
            new Kkc.Candidate ("あe", true, "会e"));

        var candidate = new Kkc.Candidate ("あw", true, "会w");
        dictionary.select_candidate (candidate);
        dictionary.purge_candidate (candidate);

        dictionary.save ();
    }

    public override void set_up () {
        FileUtils.remove ("test-user-segment-dictionary");
    }
}

class UserSentenceDictionaryTests : Kkc.TestCase {
    public UserSentenceDictionaryTests () {
        base ("UserSentenceDictionary");

        add_test ("load", this.test_load);
        add_test ("write", this.test_write);
    }

    void test_load () {
        try {
            new Kkc.UserSentenceDictionary (
                "user-sentence-dictionary");
        } catch (Error e) {
            assert_not_reached ();
        }

        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);

        try {
            new Kkc.UserSentenceDictionary (
                Path.build_filename (srcdir, "user-sentence-dictionary-good"));
        } catch (Error e) {
            assert_not_reached ();
        }

        try {
            new Kkc.UserSentenceDictionary (
                Path.build_filename (srcdir, "user-sentence-dictionary-bad1"));
            assert_not_reached ();
        } catch (Error e) {
        }

        try {
            new Kkc.UserSentenceDictionary (
                Path.build_filename (srcdir, "user-sentence-dictionary-bad2"));
            assert_not_reached ();
        } catch (Error e) {
        }
    }

    void test_write () {
        Kkc.SentenceDictionary? dictionary = null;
        try {
            dictionary = new Kkc.UserSentenceDictionary (
                "test-user-sentence-dictionary");
        } catch (Error e) {
            assert_not_reached ();
        }

        Kkc.Segment[] segments = {};

        segments += new Kkc.Segment ("left", "LEFT");
        segments += new Kkc.Segment ("right", "RIGHT");
        segments += new Kkc.Segment ("\n", "\\");

        dictionary.select_segments (segments);
        dictionary.save ();
    }

    public override void set_up () {
        FileUtils.remove ("test-user-sentence-dictionary");
    }
}

class UserDictionaryWithContextTests : Kkc.TestCase {
    Kkc.Context context;
    Kkc.UserDictionary user_dictionary;

    public UserDictionaryWithContextTests () {
        base ("UserDictionaryWithContext");

        try {
            Kkc.LanguageModel model = Kkc.LanguageModel.load ("sorted3");
            context = new Kkc.Context (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        add_test ("conversion", this.test_conversion);
        add_test ("phrase-conversion", this.test_phrase_conversion);
        add_test ("register", this.test_register);
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

    static const ConversionData PHRASE_CONVERSION_DATA[] = {
        { "s u m a i h a n a k a n o d e s u SPC",
          "すまいはなかのです",
          "すまいは中野です",
          6,
          0,
          "" },
        { "w a t a s h i n o n a m a e h a n a k a n o d e s u SPC Right Right Right Right C-Left RET",
          "",
          "",
          0,
          -1,
          "私の名前は中のです" },
        { "s u m a i h a n a k a n o d e s u SPC",
          "すまいはなかのです",
          "すまいは中のです",
          7,
          0,
          "" }
    };

    void test_phrase_conversion () {
        do_conversions (PHRASE_CONVERSION_DATA);
        context.dictionaries.save ();
    }

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
        if (FileUtils.test ("test-user-dictionary", FileTest.EXISTS)) {
            try {
                Kkc.TestUtils.remove_dir ("test-user-dictionary");
            } catch (Error e) {
                assert_not_reached ();
            }
        }

        try {
            user_dictionary = new Kkc.UserDictionary (
                "test-user-dictionary");
            context.dictionaries.add (user_dictionary);
        } catch (Error e) {
            assert_not_reached ();
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
    }

    public override void tear_down () {
        context.dictionaries.clear ();
    }
}

int main (string[] args) {
    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new UserSegmentDictionaryTests ().get_suite ());
    root.add_suite (new UserSentenceDictionaryTests ().get_suite ());
    root.add_suite (new UserDictionaryWithContextTests ().get_suite ());

    Test.run ();

    return 0;
}
