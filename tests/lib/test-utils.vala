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
}
