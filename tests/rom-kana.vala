class RomKanaTests : Kkc.TestCase {
    public RomKanaTests () {
        base ("RomKana");

        add_test ("conversion", this.test_conversion);
    }

    public void test_conversion () {
        var metadata = Kkc.Rule.find_rule ("kana");
        assert (metadata != null);
        var rule = new Kkc.Rule (metadata);
        var converter = new Kkc.RomKanaConverter ();
        converter.rule = rule.rom_kana;
        converter.append ('a');
        assert (converter.output == "");
        assert (converter.preedit == "ち");
        converter.append ('@');
        assert (converter.output == "ぢ");
        assert (converter.preedit == "");
        converter.reset ();
        converter.append ('a');
        converter.append ('>');
        assert (converter.output == "ち。");
        assert (converter.preedit == "");
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new RomKanaTests ().get_suite ());

  Test.run ();

  return 0;
}
