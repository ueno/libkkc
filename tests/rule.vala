class RuleTests : Kkc.TestCase {
    public RuleTests () {
        base ("Rule");

        add_test ("properties", this.test_properties);
        add_test ("load", this.test_load);
    }

    void test_properties () {
        var rule = new Kkc.Rule (Kkc.Rule.find_rule ("default"));
        Kkc.RuleMetadata metadata;
        rule.get ("metadata", out metadata);
    }

    void test_load () {
        const string good[] = {
            "test-empty"
        };

        const string bad[] = {
            "test-bad1",
            "test-bad2",
            "test-bad3",
            "test-bad4",
            "test-bad5",
            "test-bad6",
            "test-bad7",
            "test-bad8",
            "test-bad9",
            "test-bad10"
        };

        foreach (var name in good) {
            var metadata = Kkc.Rule.find_rule (name);
            try {
                var rule = new Kkc.Rule (metadata);
            } catch (Error e) {
                assert_not_reached ();
            }
        }

        foreach (var name in bad) {
            var metadata = Kkc.Rule.find_rule (name);
            try {
                var rule = new Kkc.Rule (metadata);
                assert_not_reached ();
            } catch (Error e) {
            }
        }

        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);

        try {
            new Kkc.RuleMetadata (
                "bad",
                Path.build_filename (srcdir,
                                     "rule-metadata-bad.json"));
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
  root.add_suite (new RuleTests ().get_suite ());

  Test.run ();

  return 0;
}
