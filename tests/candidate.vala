class CandidateTests : Kkc.TestCase {
    public CandidateTests () {
        base ("Candidate");

        add_test ("properties", this.test_properties);
    }

    void test_properties () {
        var candidate = new Kkc.Candidate ("foo", false, "FOO", null, null);

        string midasi;
        bool okuri;
        string text;
        string annotation;
        string output;

        candidate.get ("midasi", out midasi,
                       "okuri", out okuri,
                       "text", out text,
                       "annotation", out annotation,
                       "output", out output);

        candidate.set ("text", text,
                       "annotation", annotation,
                       "output", output);
    }
}

int main (string[] args) {
    Test.init (ref args);
    Kkc.init ();

    TestSuite root = TestSuite.get_root ();
    root.add_suite (new CandidateTests ().get_suite ());

    Test.run ();

    return 0;
}
