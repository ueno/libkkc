class UserRuleTests : Kkc.TestCase {
    public UserRuleTests () {
        base ("UserRule");

        add_test ("creation", this.test_creation);
        add_test ("write-overriding-keymap", this.test_write_overriding_keymap);
    }

    public void test_creation () {
        var parent = Kkc.Rule.find_rule ("kana");
        assert (parent != null);

        var srcdir = Environment.get_variable ("srcdir");
        Kkc.UserRule rule;
        try {
            rule = new Kkc.UserRule (parent, "test-user-rule", "test");
        } catch (Error e) {
            assert_not_reached ();
        }
        assert (rule != null);
    }

    public void test_write_overriding_keymap () {
        var parent = Kkc.Rule.find_rule ("kana");
        assert (parent != null);

        var srcdir = Environment.get_variable ("srcdir");
        Kkc.UserRule rule;
        try {
            rule = new Kkc.UserRule (parent, "test-user-rule", "test");
        } catch (Error e) {
            assert_not_reached ();
        }
        assert (rule != null);

        var overriding_keymap = new Kkc.Keymap ();
        var overriding_event = new Kkc.KeyEvent.from_string ("C-a");
        overriding_keymap.set (overriding_event, "abort");
        rule.write_overriding_keymap (Kkc.InputMode.HIRAGANA,
                                      overriding_keymap);

        try {
            rule = new Kkc.UserRule (parent, base_dir, "test");
        } catch (Error e) {
            assert_not_reached ();
        }
        assert (rule != null);

        var keymap = rule.get_keymap (Kkc.InputMode.HIRAGANA);
        var event = new Kkc.KeyEvent.from_string ("C-a");
        var command = keymap.lookup_key (event);
        assert (command == "abort");
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new UserRuleTests ().get_suite ());

  Test.run ();

  return 0;
}
