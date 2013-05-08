class ExpressionTests : Kkc.TestCase {
    public ExpressionTests () {
        base ("Expression");

        /* Set up the tests */
        add_test ("eval", this.test_eval);
    }

    void test_eval () {
        assert (Kkc.Expression.eval ("(\\a)") == "(\\a)");
        assert (Kkc.Expression.eval ("(concat \"DOS\\057V\")") == "DOS/V");
        assert (Kkc.Expression.eval ("(concat \"DOS\\x2fV\")") == "DOS/V");
        assert (Kkc.Expression.eval ("(concat \"DOS\\x2FV\")") == "DOS/V");
        assert (Kkc.Expression.eval ("(pwd)") == Environment.get_current_dir ());
        Kkc.Expression.eval ("(current-time-string)");
        assert (Kkc.Expression.eval ("(unknown)") == "(unknown)");
        assert (Kkc.Expression.eval ("(kkc-version)") ==
                "%s/%s".printf (Config.PACKAGE_NAME,
                                Config.PACKAGE_VERSION));
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new ExpressionTests ().get_suite ());

  Test.run ();

  return 0;
}
