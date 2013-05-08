class CandidateListTests : Kkc.TestCase {
    public CandidateListTests () {
        base ("CandidateList");

        add_test ("properties", this.test_properties);
        add_test ("cursor_move", this.test_cursor_move);
    }

    void test_properties () {
        var candidates = new Kkc.CandidateList () as Object;

        int cursor_pos;
        int size;
        uint page_start;
        uint page_size;
        bool round;
        bool page_visible;

        candidates.get ("cursor-pos", out cursor_pos,
                        "size", out size,
                        "page-start", out page_start,
                        "page-size", out page_size,
                        "round", out round,
                        "page-visible", out page_visible);

        candidates.set ("cursor-pos", cursor_pos,
                        "page-start", page_start,
                        "page-size", page_size,
                        "round", round);
    }

    void test_cursor_move () {
        var candidates = new Kkc.CandidateList ();

        candidates.page_start = 2;
        candidates.page_size = 3;

        candidates.add (new Kkc.Candidate ("a", false, "1"));
        candidates.add (new Kkc.Candidate ("a", false, "2"));
        candidates.add (new Kkc.Candidate ("a", false, "3"));

        assert (!candidates.page_visible);
        candidates.cursor_down ();
        assert (!candidates.page_visible);
        candidates.cursor_down ();
        assert (candidates.page_visible);

        candidates.add (new Kkc.Candidate ("a", false, "4"));
        candidates.add (new Kkc.Candidate ("a", false, "5"));

        candidates.round = false;
        assert (!candidates.page_down ());
        assert (!candidates.page_up ());

        candidates.round = true;
        assert (candidates.page_down ());
        assert (candidates.cursor_pos == 0);
        assert (candidates.page_up ());
        assert (candidates.cursor_pos == 3);

        assert (candidates.select_at (1));
        assert (candidates.cursor_pos == 4);

        candidates.first ();
        assert (candidates.next ());
        assert (candidates.cursor_pos == 1);
        assert (candidates.previous ());
        assert (candidates.cursor_pos == 0);
        assert (candidates.next ());
        assert (candidates.next ());
        assert (candidates.next ());
        assert (candidates.cursor_pos == 0);
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new CandidateListTests ().get_suite ());

  Test.run ();

  return 0;
}
