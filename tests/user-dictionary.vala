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
            new Kkc.Candidate ("あ お", false, "青 "));
        dictionary.select_candidate (
            new Kkc.Candidate ("あ/お", false, "青/"));
        dictionary.select_candidate (
            new Kkc.Candidate ("あu", true, "会u"));
        dictionary.select_candidate (
            new Kkc.Candidate ("あe", true, "会e"));

        var candidate = new Kkc.Candidate ("あw", true, "会w");
        dictionary.select_candidate (candidate);
        dictionary.purge_candidate (candidate);

        dictionary.save ();

        try {
            dictionary = new Kkc.UserSegmentDictionary (
                "test-user-segment-dictionary");
        } catch (Error e) {
            assert_not_reached ();
        }

        Kkc.Candidate[] candidates;
        dictionary.lookup_candidates ("あ お", false, out candidates);
        assert (candidates.length == 1 && candidates[0].output == "青 ");
        dictionary.lookup_candidates ("あ/お", false, out candidates);
        assert (candidates.length == 1 && candidates[0].output == "青/");
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

    void test_conversion () {
        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);
        Kkc.TestUtils.do_conversions (context,
                                      Path.build_filename (
                                          srcdir,
                                          "conversions-user-dictionary.json"));
        context.dictionaries.save ();

        try {
            new Kkc.UserDictionary ("test-user-dictionary");
        } catch (Error e) {
            assert_not_reached ();
        }

        user_dictionary.reload ();
    }

    void test_phrase_conversion () {
        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);
        Kkc.TestUtils.do_conversions (context,
                                      Path.build_filename (
                                          srcdir,
                                          "conversions-user-dictionary-phrase.json"));
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
    Intl.setlocale (LocaleCategory.ALL, "");

    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new UserSegmentDictionaryTests ().get_suite ());
    root.add_suite (new UserSentenceDictionaryTests ().get_suite ());
    root.add_suite (new UserDictionaryWithContextTests ().get_suite ());

    Test.run ();

    return 0;
}
