class KeymapTests : Kkc.TestCase {
    public KeymapTests () {
        base ("Keymap");

        add_test ("lookup", this.test_lookup);
    }

    void test_lookup () {
        Kkc.RuleMetadata? metadata;

        metadata = Kkc.Rule.find_rule ("nonexistent");
        assert (metadata == null);

        metadata = Kkc.Rule.find_rule ("kana");
        assert (metadata != null);

        var rule = new Kkc.Rule (metadata);
        var keymap = rule.get_keymap (Kkc.InputMode.HIRAGANA);

        string? command;
        command = keymap.lookup_key (new Kkc.KeyEvent.from_string ("(alt r)"));
        assert (command == "register");

        Kkc.KeyEvent? key;
        key = keymap.where_is ("register");
        assert (key.to_string () == "(alt r)");

        var commands = keymap.commands ();
        var entries = keymap.entries ();

        assert (keymap.get_command_label ("register") == "Register Word");
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new KeymapTests ().get_suite ());

  Test.run ();

  return 0;
}
