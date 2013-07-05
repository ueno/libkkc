class DecoderTests : Kkc.TestCase {
    Kkc.Decoder text2_decoder;
    Kkc.Decoder text3_decoder;
    Kkc.Decoder sorted2_decoder;
    Kkc.Decoder sorted3_decoder;

    public DecoderTests () {
        base ("Decoder");

        /* Set up the tests */
        add_test ("conversion", this.test_conversion);
        add_test ("constraints", this.test_constraints);
    }

    void test_conversion () {
        string[] sentences = {
            "けいざいはきゅうこうか",
            "しごとのことをかんがえる",
            "さきにくる",
            "てつだったが",
            "わたしのなまえはなかのです"
        };
        foreach (var sentence in sentences) {
            text2_decoder.decode (sentence, 1, new int[0]);
            text3_decoder.decode (sentence, 1, new int[0]);
            sorted2_decoder.decode (sentence, 1, new int[0]);
            sorted3_decoder.decode (sentence, 1, new int[0]);
        }
    }

    void test_constraints () {
        int[] constraints = { 4, 5 };
        var text2_segments = text2_decoder.decode ("けいざいはきゅうこうか", 1, constraints);
        var text3_segments = text3_decoder.decode ("けいざいはきゅうこうか", 1, constraints);
        var sorted2_segments = sorted2_decoder.decode ("けいざいはきゅうこうか", 1, constraints);
        var sorted3_segments = sorted3_decoder.decode ("けいざいはきゅうこうか", 1, constraints);
    }

    public override void set_up () {
        try {
            Kkc.LanguageModel model = Kkc.LanguageModel.load ("text2");
            text2_decoder = Kkc.Decoder.create (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        try {
            Kkc.LanguageModel model = Kkc.LanguageModel.load ("text3");
            text3_decoder = Kkc.Decoder.create (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        try {
            Kkc.LanguageModel model = Kkc.LanguageModel.load ("sorted2");
            sorted2_decoder = Kkc.Decoder.create (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        try {
            Kkc.LanguageModel model = Kkc.LanguageModel.load ("sorted3");
            sorted3_decoder = Kkc.Decoder.create (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }
    }

    public override void tear_down () {
        text2_decoder = null;
        text3_decoder = null;
        sorted2_decoder = null;
        sorted3_decoder = null;
    }
}

int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");

    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new DecoderTests ().get_suite ());

    Test.run ();

    return 0;
}
