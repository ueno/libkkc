class DictionaryListTests : Kkc.TestCase {
    public DictionaryListTests () {
        base ("DictionaryList");

        add_test ("properties", this.test_properties);
        add_test ("collection", this.test_collection);
    }

    void test_properties () {
        var dictionaries = new Kkc.DictionaryList ();
        int size;
        dictionaries.get ("size", out size);

        var enum_class = (EnumClass) typeof (Kkc.DictionaryCallbackReturn).class_ref ();
        for (int i = enum_class.minimum; i <= enum_class.maximum; i++) {
            var enum_value = enum_class.get_value (i);
            assert (enum_value != null);
        }
    }

    void test_collection () {
        var dictionaries = new Kkc.DictionaryList ();

        Kkc.Dictionary? system_segment_dictionary = null;
        try {
            var srcdir = Environment.get_variable ("srcdir");
            assert (srcdir != null);
            system_segment_dictionary = new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "system-segment-dictionary"));
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
        dictionaries.add (system_segment_dictionary);
        assert (dictionaries.size == 1);

        var empty_dictionary = new Kkc.EmptySegmentDictionary ();
        dictionaries.add (empty_dictionary);
        assert (dictionaries.size == 2);

        dictionaries.remove (empty_dictionary);
        assert (dictionaries.size == 1);

        dictionaries.clear ();
        assert (dictionaries.size == 0);
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new DictionaryListTests ().get_suite ());

  Test.run ();

  return 0;
}
