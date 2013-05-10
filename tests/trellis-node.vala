class TrellisNodeTests : Kkc.TestCase {
    public TrellisNodeTests () {
        base ("TrellisNode");

        add_test ("unigram", this.test_unigram);
        add_test ("bigram", this.test_bigram);
    }

    void test_unigram () {
        Kkc.TrellisNode node;

        var entry = Kkc.LanguageModelEntry () {
            input = "foo",
            output = "bar",
            id = 0
        };

        node = new Kkc.UnigramTrellisNode (entry, entry.input.char_count ());
        assert (node.input == "foo");
        assert (node.to_string () == "<foo/bar>");

        var entries = node.entries;
        assert (entries.length == 1);
        assert (entries[0] == entry);
    }

    void test_bigram () {
        var left_entry = Kkc.LanguageModelEntry () {
            input = "left",
            output = "LEFT",
            id = 0
        };
        var left_node = new Kkc.UnigramTrellisNode (
            left_entry,
            left_entry.input.char_count ());

        var right_entry = Kkc.LanguageModelEntry () {
            input = "right",
            output = "RIGHT",
            id = 0
        };
        var right_node = new Kkc.UnigramTrellisNode (
            right_entry,
            left_node.endpos + right_entry.input.char_count ());

        Kkc.TrellisNode node;
        node = new Kkc.BigramTrellisNode (left_node,
                                          right_node,
                                          right_node.endpos);
        assert (node.endpos == right_node.endpos);
        assert (node.input == left_node.input + right_node.input);
        assert (node.output == left_node.output + right_node.output);
        assert (node.to_string () == "<left/LEFT><right/RIGHT>");

        var entries = node.entries;
        assert (entries.length == 2);
        assert (entries[0] == left_entry);
        assert (entries[1] == right_entry);

        node = new Kkc.BigramTrellisNode (left_node,
                                          right_node,
                                          left_node.endpos);
        assert (node.input == left_node.input);
        assert (node.output == left_node.output);
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new TrellisNodeTests ().get_suite ());

  Test.run ();

  return 0;
}
