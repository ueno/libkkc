class EmptyMetadata : Kkc.MetadataFile {
    public EmptyMetadata (string name, string filename) throws Error {
        base (name, filename);
    }

    public override bool parse (Json.Object object) throws Error {
        return true;
    }
}

class MetadataFileTests : Kkc.TestCase {
    public MetadataFileTests () {
        base ("MetadataFile");

        add_test ("load", this.test_load);
        add_test ("properties", this.test_properties);
    }

    void test_load () {
        const string good[] = {
            "metadata"
        };

        const string bad[] = {
            "metadata-bad1",
            "metadata-bad2",
            "metadata-bad3",
            "metadata-bad4"
        };

        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);

        foreach (var name in good) {
            try {
                new EmptyMetadata (
                    name,
                    Path.build_filename (srcdir,
                                         name + ".json"));
            } catch (Error e) {
                assert_not_reached ();
            }
        }

        foreach (var name in bad) {
            try {
                new EmptyMetadata (
                    name,
                    Path.build_filename (srcdir,
                                         name + ".json"));
                assert_not_reached ();
            } catch (Error e) {
            }
        }
    }

    void test_properties () {
        var srcdir = Environment.get_variable ("srcdir");
        assert (srcdir != null);

        Kkc.MetadataFile metadata;
        try {
            metadata = new EmptyMetadata (
                "metadata",
                Path.build_filename (srcdir, "metadata.json"));
        } catch (Error e) {
            assert_not_reached ();
        }

        string name;
        string label;
        string description;
        string filename;

        metadata.get ("name", out name,
                      "label", out label,
                      "description", out description,
                      "filename", out filename);
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new MetadataFileTests ().get_suite ());

  Test.run ();

  return 0;
}
