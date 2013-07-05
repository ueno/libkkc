class SegmentTests : Kkc.TestCase {
    public SegmentTests () {
        base ("Segment");

        add_test ("properties", this.test_properties);
    }

    void test_properties () {
        var segment = new Kkc.Segment ("input", "output");
        string input;
        string output;
        segment.get ("input", out input,
                     "output", out output);
        segment.set ("output", output);
    }
}

int main (string[] args) {
    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new SegmentTests ().get_suite ());

    Test.run ();

    return 0;
}
