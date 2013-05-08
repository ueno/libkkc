class EncodingConverterTests : Kkc.TestCase {
    public EncodingConverterTests () {
        base ("EncodingConverter");

        add_test ("creation", this.test_creation);
        add_test ("properties", this.test_properties);
    }

    void test_creation () {
        try {
            var converter = new Kkc.EncodingConverter ("UTF-8");
        } catch (Error e) {
            assert_not_reached ();
        }
        try {
            var converter = new Kkc.EncodingConverter ("INVALID");
            assert_not_reached ();
        } catch (Error e) {
        }
    }

    void test_properties () {
        Kkc.EncodingConverter converter;
        try {
            converter = new Kkc.EncodingConverter ("UTF-8");
        } catch (Error e) {
            assert_not_reached ();
        }

        string encoding;
        converter.get ("encoding", out encoding);
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new EncodingConverterTests ().get_suite ());

  Test.run ();

  return 0;
}
