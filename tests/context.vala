class ContextTests : Kkc.TestCase {
    Kkc.Context context;

    public ContextTests () {
        base ("Context");

        add_test ("properties", this.test_properties);
        add_test ("initial", this.test_initial);
        add_test ("kana", this.test_kana);
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

        var metadata = Kkc.RuleMetadata.find ("kana");
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

    void do_conversions_json (string filename) {
        Json.Parser parser = new Json.Parser ();
        try {
            if (!parser.load_from_file (filename))
                assert_not_reached ();
        } catch (GLib.Error e) {
            assert_not_reached ();
        }
        var root = parser.get_root ();
        assert (root.get_node_type () == Json.NodeType.ARRAY);
        var array = root.get_array ();

        for (var i = 0; i < array.get_length (); i++) {
            var node = array.get_element (i);
            assert (node.get_node_type () == Json.NodeType.OBJECT);
            var object = node.get_object ();
            assert (object.has_member ("keys"));
            var keys = object.get_string_member ("keys");
            try {
                context.process_key_events (keys);
            } catch (Kkc.KeyEventFormatError e) {
                assert_not_reached ();
            }
            Kkc.TestUtils.check_conversion_result (context, object);
            context.reset ();
            context.clear_output ();
        }
    }

    void test_initial () {
        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);
        do_conversions_json (Path.build_filename (srcdir,
                                                  "conversions-initial.json"));

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

        try {
            context.process_key_events ("a a a RET");
            assert (!context.process_key_events ("Left"));
            assert (!context.process_key_events ("Right"));
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
        context.reset ();
        context.clear_output ();
    }

    void test_kana () {
        var metadata = Kkc.RuleMetadata.find ("kana");
        context.typing_rule = new Kkc.Rule (metadata);

        context.process_key_events ("4");
        assert (context.input == "う");
        context.process_key_events ("RET");
        assert (context.poll_output () == "う");
        context.clear_output ();
        context.reset ();

        context.process_key_events ("3");
        assert (context.input == "あ");
        context.process_key_events ("SPC");
        assert (context.segments.get_output () == "阿");
        context.clear_output ();
        context.reset ();

        // Check if rom-kana conversion finishes before moving cursor.
        context.process_key_events ("3 3 3 3 3 Left 4 Right");
        assert (context.input == "ああああうあ");
        context.clear_output ();
        context.reset ();

        context.process_key_events ("a a a !");
        assert (context.input == "ちちち!");
        context.clear_output ();
        context.reset ();

        context.process_key_events ("3 3 3 3 3 Left 4 5");
        assert (context.input == "ああああうえあ");
        assert (context.input_cursor_pos == 6);
        context.clear_output ();
        context.reset ();

        context.process_key_events ("3 3 3 3 3 Left Delete");
        assert (context.input == "ああああ");
        assert (context.input_cursor_pos == -1);
        context.clear_output ();
        context.reset ();
    }

    void test_nicola () {
        var metadata = Kkc.RuleMetadata.find ("nicola");
        context.typing_rule = new Kkc.Rule (metadata);

        // single key - timeout
        context.process_key_events ("a");
        Thread.usleep (200000);
        MainContext.default ().iteration (false);
        assert (context.input == "う");
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
        MainContext.default ().iteration (false);
        context.process_key_events ("b");
        assert (context.input == "う");
        context.clear_output ();
        context.reset ();

        context.process_key_events ("a");
        Thread.usleep (50000);
        MainContext.default ().iteration (false);
        context.process_key_events ("b");
        Thread.usleep (200000);
        MainContext.default ().iteration (false);
        assert (context.input == "うへ");
        context.clear_output ();
        context.reset ();

        // double key - shifted
        context.process_key_events ("a");
        Thread.usleep (10000);
        MainContext.default ().iteration (false);
        context.process_key_events ("Muhenkan");
        Thread.usleep (200000);
        MainContext.default ().iteration (false);
        assert (context.input == "を");
        context.clear_output ();
        context.reset ();

        // double key - shifted reverse
        context.process_key_events ("Muhenkan");
        Thread.usleep (10000);
        MainContext.default ().iteration (false);
        context.process_key_events ("a");
        Thread.usleep (200000);
        MainContext.default ().iteration (false);
        assert (context.input == "を");
        context.clear_output ();
        context.reset ();

        // double key - shifted expired
        context.process_key_events ("a");
        Thread.usleep (60000);
        MainContext.default ().iteration (false);
        context.process_key_events ("Muhenkan");
        assert (context.input == "う");
        context.clear_output ();
        context.reset ();

        // triple key t1 <= t2
        context.process_key_events ("a");
        Thread.usleep (10000);
        MainContext.default ().iteration (false);
        context.process_key_events ("Muhenkan");
        Thread.usleep (20000);
        MainContext.default ().iteration (false);
        context.process_key_events ("b");
        assert (context.input == "を");
        context.clear_output ();
        context.reset ();

        context.process_key_events ("a");
        Thread.usleep (20000);
        MainContext.default ().iteration (false);
        context.process_key_events ("Muhenkan");
        Thread.usleep (10000);
        MainContext.default ().iteration (false);
        context.process_key_events ("b");
        assert (context.input == "うぃ");
        context.clear_output ();
        context.reset ();

        context.process_key_events ("a");
        Thread.usleep (10000);
        MainContext.default ().iteration (false);
        context.process_key_events ("Henkan");
        Thread.usleep (20000);
        MainContext.default ().iteration (false);
        context.process_key_events ("b");
        context.clear_output ();
        context.reset ();

        context.process_key_events ("a");
        Thread.usleep (10000);
        MainContext.default ().iteration (false);
        context.process_key_events ("Henkan");
        Thread.usleep (20000);
        MainContext.default ().iteration (false);
        context.process_key_events ("C-b");
        context.clear_output ();
        context.reset ();

        context.process_key_events ("a");
        Thread.usleep (10000);
        MainContext.default ().iteration (false);
        context.process_key_events ("Henkan");
        Thread.usleep (20000);
        MainContext.default ().iteration (false);
        context.process_key_events ("(control release b)");
        context.clear_output ();
        context.reset ();
    }

    void test_sentence_conversion () {
        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);
        do_conversions_json (Path.build_filename (srcdir,
                                                  "conversions-sentence.json"));
    }

    void test_segment_conversion () {
        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);
        do_conversions_json (Path.build_filename (srcdir,
                                                  "conversions-segment.json"));
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

int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");

    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new ContextTests ().get_suite ());

    Test.run ();

    return 0;
}
