class SegmentListTests : Kkc.TestCase {
    public SegmentListTests () {
        base ("SegmentList");

        add_test ("properties", this.test_properties);
    }

    void test_properties () {
        var segments = new Kkc.SegmentList () as Object;
        int cursor_pos;
        int size;
        segments.get ("cursor-pos", out cursor_pos,
                      "size", out size);
        segments.set ("cursor-pos", cursor_pos);
    }
}

int main (string[] args) {
    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new SegmentListTests ().get_suite ());

    Test.run ();

    return 0;
}
