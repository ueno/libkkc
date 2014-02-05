namespace Kkc.TestUtils {
    public static void remove_dir (string name) throws Error {
        var dir = Dir.open (name);
        string? child_name;
        while ((child_name = dir.read_name ()) != null) {
            var child_filename = Path.build_filename (name, child_name);
            if (FileUtils.test (child_filename, FileTest.IS_DIR))
                remove_dir (child_filename);
            else
                FileUtils.remove (child_filename);
        }
        DirUtils.remove (name);
    }

    public static void check_conversion_result (Kkc.Context context,
                                                Json.Object expected)
    {
        if (expected.has_member ("output")) {
            var expected_output = expected.get_string_member ("output");
            var output = context.poll_output ();
            assert (output == expected_output);
        }

        if (expected.has_member ("input")) {
            var expected_input = expected.get_string_member ("input");
            assert (context.input == expected_input);
        }

        if (expected.has_member ("segments")) {
            var expected_segments = expected.get_string_member ("segments");
            assert (context.segments.get_output () == expected_segments);
        }

        if (expected.has_member ("segments_size")) {
            var expected_segments_size = expected.get_int_member ("segments_size");
            assert (context.segments.size == expected_segments_size);
        }

        if (expected.has_member ("segments_cursor_pos")) {
            var expected_segments_cursor_pos = expected.get_int_member ("segments_cursor_pos");
            assert (context.segments.cursor_pos == expected_segments_cursor_pos);
        }

        if (expected.has_member ("candidates_size")) {
            var expected_candidates_size = expected.get_int_member ("candidates_size");
            assert (context.candidates.size == expected_candidates_size);
        }

        if (expected.has_member ("input_cursor_pos")) {
            var expected_input_cursor_pos = expected.get_int_member ("input_cursor_pos");
            assert (context.input_cursor_pos == expected_input_cursor_pos);
        }
    }

    public void do_conversions (Kkc.Context context, string filename) {
        Json.Parser parser = new Json.Parser ();
        try {
            if (!parser.load_from_file (filename))
                assert_not_reached ();
        } catch (GLib.Error e) {
            assert_not_reached ();
        }
        var root = parser.get_root ();
        assert (root.get_node_type () == Json.NodeType.ARRAY);
        var array = root.get_array ();

        for (var i = 0; i < array.get_length (); i++) {
            var node = array.get_element (i);
            assert (node.get_node_type () == Json.NodeType.OBJECT);
            var object = node.get_object ();
            assert (object.has_member ("keys"));
            var keys = object.get_string_member ("keys");
            try {
                context.process_key_events (keys);
            } catch (Kkc.KeyEventFormatError e) {
                assert_not_reached ();
            }
            check_conversion_result (context, object);
            context.reset ();
            context.clear_output ();
        }
    }
}
