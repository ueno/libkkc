class TemplateTests : Kkc.TestCase {
    public TemplateTests () {
        base ("Template");

        add_test ("properties", this.test_properties);
    }

    void test_properties () {
        Kkc.Template template;
        string source;
        bool okuri;

        template = new Kkc.SimpleTemplate ("source");
        template.get ("source", out source,
                      "okuri", out okuri);
        assert (source == "source");
        assert (!okuri);

        template = new Kkc.OkuriganaTemplate ("かう", 1);
        template.get ("source", out source,
                      "okuri", out okuri);

        assert (source == "かu");
        assert (okuri);

        template = new Kkc.NumericTemplate ("だい11かい");
        template.get ("source", out source,
                      "okuri", out okuri);

        assert (source == "だい#かい");
        assert (!okuri);

        assert (template.expand ("第#0回") == "第11回");
        assert (template.expand ("第#1回") == "第１１回");
        assert (template.expand ("第#2回") == "第一一回");
        assert (template.expand ("第#3回") == "第十一回");

        // Unsupported.
        assert (template.expand ("第#4回") == "第11回");
        assert (template.expand ("第#9回") == "第11回");
    }
}

int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");

    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new TemplateTests ().get_suite ());

    Test.run ();

    return 0;
}
