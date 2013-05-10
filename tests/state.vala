class StateTests : Kkc.TestCase {
    public StateTests () {
        base ("State");

        add_test ("properties", this.test_properties);
    }

    void test_properties () {
        Kkc.Decoder? decoder = null;
        try {
            Kkc.LanguageModel model = Kkc.LanguageModel.load ("text3");
            decoder = Kkc.Decoder.create (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        var state = new Kkc.State (decoder, new Kkc.DictionaryList ());
        Kkc.InputMode mode;
        Kkc.PunctuationStyle style;
        Kkc.Rule rule;
        state.get ("input-mode", out mode,
                   "punctuation-style", out style,
                   "typing-rule", out rule);
        state.set ("input-mode", mode,
                   "punctuation-style", style,
                   "typing-rule", rule);
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new StateTests ().get_suite ());

  Test.run ();

  return 0;
}
