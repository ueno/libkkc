class CandidateListTests : Kkc.TestCase {
    public CandidateListTests () {
        base ("CandidateList");

        add_test ("cursor_move", this.test_cursor_move);
    }

    public void test_cursor_move () {
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
