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
                Path.build_filename (srcdir, "system-segment-dictionary"));
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }

    void test_load () {
        try {
            new Kkc.SystemSegmentDictionary (
                "nonexistent-system-segment-dictionary");
        } catch (Error e) {
        }

        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);

        try {
            new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "system-segment-dictionary"),
                "unknown encoding");
            assert_not_reached ();
        } catch (Error e) {
        }

        try {
            new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "system-segment-dictionary-bad1"));
            assert_not_reached ();
        } catch (Error e) {
        }

        try {
            new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "system-segment-dictionary-bad2"));
            assert_not_reached ();
        } catch (Error e) {
        }

        try {
            new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "system-segment-dictionary-bad3"));
            assert_not_reached ();
        } catch (Error e) {
        }
    }
}

int main (string[] args) {
    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new SystemDictionaryTests ().get_suite ());

    Test.run ();

    return 0;
}
