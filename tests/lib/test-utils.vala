namespace Kkc.TestUtils {
    public static void remove_dir (string name) {
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
}