[CCode (cprefix = "xkb_", lower_case_cprefix = "xkb_", cheader_filename = "xkbcommon/xkbcommon.h")]
namespace Xkb
{
	namespace Keysym {
		[CCode (cname = "XKB_KEY_NoSymbol")]
		public const uint32 NoSymbol;
	}

	public enum KeysymFlags {
		[CCode (cname = "XKB_KEYSYM_NO_FLAGS")]
		NO_FLAGS = 0,
		CASE_INSENSITIVE = (1 << 0)
	}

	public int keysym_get_name(uint32 keysym, [CCode (array_length_cname = "size", array_length_pos = 2.1, array_length_type = "size_t")] uint8[] buffer);
    public uint32 keysym_from_name(string name, KeysymFlags flags);
	public int keysym_to_utf8(uint32 keysym, [CCode (array_length_cname = "size", array_length_pos = 2.1, array_length_type = "size_t")] uint8[] buffer);
}
