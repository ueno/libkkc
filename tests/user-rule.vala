class UserRuleTests : Kkc.TestCase {
    public UserRuleTests () {
        base ("UserRule");

        add_test ("creation", this.test_creation);
        add_test ("write", this.test_write);
    }

    public override void set_up () {
        if (FileUtils.test ("test-user-rule", FileTest.EXISTS)) {
            try {
                Kkc.TestUtils.remove_dir ("test-user-rule");
            } catch (Error e) {
                assert_not_reached ();
            }
        }
    }

    void test_creation () {
        var parent = Kkc.RuleMetadata.find ("kana");
        assert (parent != null);

        var rule = new Kkc.UserRule (parent, "test-user-rule", "test");
        assert (rule != null);
    }

    void test_write () {
        var parent = Kkc.RuleMetadata.find ("kana");
        assert (parent != null);

        Kkc.UserRule rule = new Kkc.UserRule (parent, "test-user-rule", "test");
        assert (rule != null);

        var event0 = new Kkc.KeyEvent.from_string ("C-a");
        rule.get_keymap (Kkc.InputMode.HIRAGANA).set (event0, "abort");
        rule.write (Kkc.InputMode.HIRAGANA);

        rule = new Kkc.UserRule (parent, "test-user-rule", "test");
        assert (rule != null);

        var event1 = new Kkc.KeyEvent.from_string ("C-a");
        var command = rule.get_keymap (Kkc.InputMode.HIRAGANA).lookup_key (event1);
        assert (command == "abort");

        bool found = false;
        var rules = Kkc.Rule.list ();
        foreach (var metadata in rules) {
            if (metadata.name == "test:kana") {
                found = true;
                break;
            }
        }
        assert (!found);
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
