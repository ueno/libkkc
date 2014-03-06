[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "keysyms.h")]
namespace Keysyms
{
    public const string keysym_names;

    [CCode (cname = "struct name_keysym")]
    public struct KeysymEntry {
        uint32 keysym;
        uint32 offset;
    }

    public const KeysymEntry[] name_to_keysym;

    public const KeysymEntry[] keysym_to_name;
}
