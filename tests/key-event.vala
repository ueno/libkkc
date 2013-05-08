class KeyEventTests : Kkc.TestCase {
    public KeyEventTests () {
        base ("KeyEvent");

        add_test ("parse", this.test_parse);
    }

    public void test_parse () {
        try {
            var from_str = "(shift control meta hyper super alt lshift rshift release a)";
            var to_str = "(control meta hyper super alt lshift rshift release a)";
            var key = new Kkc.KeyEvent.from_string (from_str);
            assert (key.to_string () == to_str);
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }

        try {
            new Kkc.KeyEvent.from_string ("(nonexistent a)");
            assert_not_reached ();
        } catch (Kkc.KeyEventFormatError e) {
        }

        try {
            new Kkc.KeyEvent.from_string ("(control foo)");
            assert_not_reached ();
        } catch (Kkc.KeyEventFormatError e) {
        }

        try {
            new Kkc.KeyEvent.from_string ("S-C-M-G-a");
        } catch (Kkc.KeyEventFormatError e) {
            assert_not_reached ();
        }
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new KeyEventTests ().get_suite ());

  Test.run ();

  return 0;
}
