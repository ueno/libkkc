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

        try {
            Kkc.LanguageModel.load ("text3");
        } catch (Kkc.LanguageModelError e) {
            assert_not_reached ();
        }

        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);

        try {
            new Kkc.LanguageModelMetadata (
                "bad1",
                Path.build_filename (srcdir,
                                     "language-model-metadata-bad1.json"));
            assert_not_reached ();
        } catch (Error e) {
        }

        try {
            new Kkc.LanguageModelMetadata (
                "bad2",
                Path.build_filename (srcdir,
                                     "language-model-metadata-bad2.json"));
            assert_not_reached ();
        } catch (Error e) {
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
