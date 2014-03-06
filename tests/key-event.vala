class KeyEventTests : Kkc.TestCase {
    public KeyEventTests () {
        base ("KeyEvent");

        add_test ("properties", this.test_properties);
        add_test ("parse", this.test_parse);
        add_test ("keyname", this.test_keyname);
        add_test ("simple-filter", this.test_simple_filter);
        add_test ("kana-filter", this.test_kana_filter);
        add_test ("nicola-filter", this.test_nicola_filter);
    }

    void test_properties () {
        var key = new Kkc.KeyEvent.from_string ("(control a)");
        string name;
        uint unicode;
        uint keyval;
        uint keycode;
        Kkc.ModifierType modifiers;
        key.get ("name", out name,
                 "unicode", out unicode,
                 "keyval", out keyval,
                 "keycode", out keycode,
                 "modifiers", out modifiers);
        assert (name == "a");
    }

    void test_parse () {
        try {
            var from_str = "(shift control meta hyper super alt lshift rshift release a)";
            var to_str = "(control meta hyper super alt lshift rshift release a)";
            var key = new Kkc.KeyEvent.from_string (from_str);
            assert (key.to_string () == to_str);
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }

        try {
            new Kkc.KeyEvent.from_string ("(nonexistent a)");
            assert_not_reached ();
        } catch (Kkc.KeyEventFormatError e) {
        }

        try {
            new Kkc.KeyEvent.from_string ("(control foo)");
            assert_not_reached ();
        } catch (Kkc.KeyEventFormatError e) {
        }

        try {
            new Kkc.KeyEvent.from_string ("S-C-M-G-a");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
    }

    void test_keyname () {
        var name = Kkc.KeyEventUtils.keyval_name (Kkc.Keysyms.VoidSymbol);
        assert (name == "VoidSymbol");

        var keyval = Kkc.KeyEventUtils.keyval_from_name ("VoidSymbol");
        assert (keyval == Kkc.Keysyms.VoidSymbol);
    }

    void test_simple_filter () {
        new Kkc.SimpleKeyEventFilter ();
    }

    void test_kana_filter () {
        var filter = new Kkc.KanaKeyEventFilter ();
        var from_key = new Kkc.KeyEvent.from_x_event (Kkc.Keysyms.backslash,
                                                      124,
                                                      0);
        var to_key = filter.filter_key_event (from_key);
        assert (to_key.keyval == Kkc.Keysyms.yen);
    }

    void test_nicola_filter () {
        var filter = new Kkc.NicolaKeyEventFilter ();

        var from_key = new Kkc.KeyEvent.from_x_event (Kkc.Keysyms.a,
                                                      0,
                                                      0);
        var to_key = filter.filter_key_event (from_key);
    }
}

int main (string[] args) {
    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new KeyEventTests ().get_suite ());

    Test.run ();

    return 0;
}
