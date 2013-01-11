namespace Kkc {
    namespace LanguageModelUtils {
        internal static double decode_cost (uint16 cost, double min_cost) {
            return cost * min_cost / 65535;
        }

        internal static long bsearch_ngram (void *memory,
                                            long start_offset,
                                            long end_offset,
                                            long record_size,
                                            uint8[] needle)
        {
            var offset = start_offset + (end_offset - start_offset) / 2;
            while (start_offset <= end_offset) {
                uint8 *p = (uint8 *) memory + offset * record_size;
                var r = Memory.cmp (p, needle, needle.length);
                if (r == 0)
                    return offset;
                if (r > 0)
                    end_offset = offset - 1;
                else
                    start_offset = offset + 1;
                offset = start_offset + (end_offset - start_offset) / 2;
            }
            return -1;
        }
	}
}