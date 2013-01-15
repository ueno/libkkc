class ContextTests : Kkc.TestCase {
    Kkc.Context context;

    public ContextTests () {
        base ("Context");

		try {
			Kkc.LanguageModel model = Kkc.LanguageModel.load ("sorted3");
            context = new Kkc.Context (model);
		} catch (Kkc.LanguageModelError e) {
			stderr.printf ("%s\n", e.message);
		}

		add_test ("conversion", this.test_conversion);
    }

    struct Conversion {
        string input;
        string preedit;
        uint preedit_underline_offset;
        uint preedit_underline_nchars;
        string output;
    }

    static const string INPUT_PREFIX =
      "w a t a s h i n o n a m a e h a n a k a n o d e s u ";

    static const Conversion[] conversions = {
        { "",
          "わたしのなまえはなかのです",
          0,
          0,
          "" },
        { "SPC",
          "わたしの名前は中野です",
          0,
          3,
          "" },
        { "SPC Left",
          "わたしの名前は中野です",
          0,
          3,
          "" },
        { "SPC Right",
          "わたしの名前は中野です",
          3,
          1,
          "" },
        { "SPC Right C-Right",
          "わたしのな前は中野です",
          3,
          2,
          "" },
        { "SPC Right Right C-Left",
          "わたしの生絵は中野です",
          4,
          1,
          "" },
    };

    public void test_conversion () {
        foreach (var conversion in conversions) {
            context.process_key_events (INPUT_PREFIX + conversion.input);
            var output = context.poll_output ();
            var preedit = context.preedit;
            uint offset, nchars;
            context.get_preedit_underline (out offset, out nchars);
            assert (output == conversion.output);
            assert (preedit == conversion.preedit);
            assert (offset == conversion.preedit_underline_offset);
            assert (nchars == conversion.preedit_underline_nchars);
            context.reset ();
            context.clear_output ();
        }
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new ContextTests ().get_suite ());

  Test.run ();

  return 0;
}
