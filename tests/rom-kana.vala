class RomKanaTests : Kkc.TestCase {
    public RomKanaTests () {
        base ("RomKana");

        add_test ("properties", this.test_properties);
        add_test ("default", this.test_default);
        add_test ("kana", this.test_kana);
    }

    void test_properties () {
        var metadata = Kkc.RuleMetadata.find ("default");
        assert (metadata != null);
        var rule = new Kkc.Rule (metadata);
        var converter = new Kkc.RomKanaConverter ();

        Kkc.KanaMode mode;
        Kkc.PunctuationStyle style;
        string pending_output;
        string pending_input;
        Kkc.RomKanaCharacterList produced;
        converter.get ("rule", out rule,
                       "kana-mode", out mode,
                       "punctuation-style", out style,
                       "pending-output", out pending_output,
                       "pending-input", out pending_input,
                       "produced", out produced);
        converter.set ("rule", rule,
                       "kana-mode", mode,
                       "punctuation-style", style);

        int size;
        (produced as Object).get ("size", out size);
        assert (size == 0);
    }

    void test_default () {
        var metadata = Kkc.RuleMetadata.find ("default");
        assert (metadata != null);
        var rule = new Kkc.Rule (metadata);
        var converter = new Kkc.RomKanaConverter ();
        converter.rule = rule.rom_kana;

        assert (!converter.is_valid ((unichar) 257));

        converter.append ('a');
        assert (converter.get_produced_output () == "あ");
        assert (converter.pending_output == "");
        converter.produced.clear ();

        converter.kana_mode = Kkc.KanaMode.KATAKANA;
        converter.append ('a');
        assert (converter.get_produced_output () == "ア");
        assert (converter.pending_output == "");
        converter.produced.clear ();

        converter.kana_mode = Kkc.KanaMode.HANKAKU_KATAKANA;
        converter.append ('a');
        assert (converter.get_produced_output () == "ｱ");
        assert (converter.pending_output == "");
        converter.produced.clear ();

        converter.append ('k');
        assert (converter.can_consume ('a'));
        converter.produced.clear ();

        converter.kana_mode = Kkc.KanaMode.HIRAGANA;

        converter.reset ();
        converter.auto_correct = true;
        converter.append_text ("convert");
        assert (converter.get_produced_output () == "おんう゛ぇ");

        converter.reset ();
        converter.auto_correct = false;
        converter.append_text ("convert");
        assert (converter.get_produced_output () == "cおんう゛ぇr");
    }

    void test_kana () {
        var metadata = Kkc.RuleMetadata.find ("kana");
        assert (metadata != null);
        var rule = new Kkc.Rule (metadata);
        var converter = new Kkc.RomKanaConverter ();
        converter.rule = rule.rom_kana;
        converter.append ('a');
        assert (converter.get_produced_output () == "");
        assert (converter.pending_output == "ち");
        converter.append ('@');
        assert (converter.get_produced_output () == "ぢ");
        assert (converter.pending_output == "");
        converter.reset ();
        converter.append ('a');
        converter.append ('>');
        assert (converter.get_produced_output () == "ち。");
        assert (converter.pending_output == "");
        converter.produced.clear ();

        converter.kana_mode = Kkc.KanaMode.KATAKANA;
        converter.append_text ("4@");
        assert (converter.get_produced_output () == "ヴ");
        assert (converter.pending_output == "");
        converter.produced.clear ();
    }
}

int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");

    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new RomKanaTests ().get_suite ());

    Test.run ();

    return 0;
}
