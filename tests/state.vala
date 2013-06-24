class StateTests : Kkc.TestCase {
    public StateTests () {
        base ("State");

        add_test ("properties", this.test_properties);
    }

    void test_properties () {
        Kkc.LanguageModel model = Kkc.LanguageModel.load ("text3");
        var state = new Kkc.State (model, new Kkc.DictionaryList ());
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
