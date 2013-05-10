class LanguageModelTests : Kkc.TestCase {
    public LanguageModelTests () {
        base ("LanguageModel");

        add_test ("load", this.test_load);
    }

    void test_load () {
        try {
            Kkc.LanguageModel.load ("nonexistent");
            assert_not_reached ();
        } catch (Kkc.LanguageModelError e) {
        }
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new LanguageModelTests ().get_suite ());

  Test.run ();

  return 0;
}
