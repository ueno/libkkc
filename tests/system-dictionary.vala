class SystemDictionaryTests : Kkc.TestCase {
    public SystemDictionaryTests () {
        base ("SystemDictionary");

        add_test ("load", this.test_load);
    }

    void test_load () {
        try {
            new Kkc.SystemSegmentDictionary (
                "nonexistent-file-dict.dat");
            assert_not_reached ();
        } catch (Error e) {
        }

        try {
            new Kkc.SystemSegmentDictionary (
                "bad-file-dict1.dat");
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
  root.add_suite (new SystemDictionaryTests ().get_suite ());

  Test.run ();

  return 0;
}
