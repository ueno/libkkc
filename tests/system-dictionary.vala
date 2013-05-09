class SystemDictionaryTests : Kkc.TestCase {
    public SystemDictionaryTests () {
        base ("SystemDictionary");

        add_test ("properties", this.test_properties);
        add_test ("load", this.test_load);
    }

    void test_properties () {
        Kkc.SystemSegmentDictionary? system_segment_dictionary = null;
        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);

        try {
            system_segment_dictionary = new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "file-dict.dat"));
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }

        bool read_only;
        system_segment_dictionary.get ("read-only", out read_only);
        assert (read_only);
    }

    void test_load () {
        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);

        try {
            new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "file-dict.dat"),
                "unknown encoding");
            assert_not_reached ();
        } catch (Error e) {
        }

        try {
            new Kkc.SystemSegmentDictionary (
                "nonexistent-file-dict.dat");
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
