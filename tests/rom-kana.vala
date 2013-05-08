class RomKanaTests : Kkc.TestCase {
    public RomKanaTests () {
        base ("RomKana");

        add_test ("conversion", this.test_conversion);
    }

    void test_conversion () {
        var metadata = Kkc.Rule.find_rule ("kana");
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
