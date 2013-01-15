class BasicTests : Kkc.TestCase {
    Kkc.Decoder decoder;

    public BasicTests () {
        base ("Basic");

        try {
            Kkc.LanguageModel model = Kkc.LanguageModel.load ("sorted3");
            decoder = Kkc.Decoder.create (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        /* Set up the tests */
        add_test ("conversion", this.test_conversion);
        add_test ("constraints", this.test_constraints);
    }

    public void test_conversion () {
        string[] sentences = {
            "けいざいはきゅうこうか",
            "しごとのことをかんがえる",
            "さきにくる",
            "てつだったが",
            "わたしのなまえはなかのです"
        };
        foreach (var sentence in sentences) {
            decoder.decode (sentence, 1, new int[0]);
        }
    }

    public void test_constraints () {
        int[] constraints = { 4, 5 };
        var segments = decoder.decode ("けいざいはきゅうこうか", 1, constraints);
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new BasicTests ().get_suite ());

  Test.run ();

  return 0;
}
