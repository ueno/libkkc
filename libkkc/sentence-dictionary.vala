using Gee;

namespace Kkc {
    struct PrefixEntry {
        public int offset;
        public string text;
        public PrefixEntry (int offset, string text) {
            this.offset = offset;
            this.text = text;
        }
    }

    class SentenceUtils : Object {
        static int compare_prefix (PrefixEntry a, PrefixEntry b) {
            var result = b.text.char_count () - a.text.char_count ();
            if (result == 0)
                result = a.offset - b.offset;
            return result;
        }

        public static Gee.List<PrefixEntry?> enumerate_prefixes (
            string[] sequence)
        {
            var result = new ArrayList<PrefixEntry?> ();
            int[] offsets = new int[sequence.length];
            for (var i = 1; i < sequence.length; i++) {
                offsets[i] = sequence[i - 1].char_count ();
            }
            offsets[0] = 0;
            for (var i = 0; i < sequence.length; i++) {
                for (var j = i; j < sequence.length; j++) {
                    string[] _sequence = sequence[i:j+1];
                    _sequence += null;
                    var text = string.joinv ("", _sequence);
                    result.add (PrefixEntry (i, text));
                }
            }
            result.sort ((GLib.CompareFunc) compare_prefix);
            return result;
        }
    }

    /**
     * Base interface of sentence dictionaries.
     */
    public interface SentenceDictionary : Object, Dictionary {
        /**
         * Lookup constraints.
         *
         * @param input input string to lookup
         *
         * @return an array of positions
         */
        public abstract int[] lookup_constraints (string input);

        /**
         * Lookup sequence.
         *
         * @param sequence input sequence to lookup
         *
         * @return an array of strings
         */
        public abstract string[] lookup_sequence (string[] sequence);

        public virtual bool select_segments (Segment[] input) {
            // FIXME: throw an error when the dictionary is read only
            return false;
        }
    }

    class UserSentenceDictionary : Object, Dictionary, SentenceDictionary {
        File file;
        string etag;

        Map<string,Gee.List<int>> constraints =
            new HashMap<string,Gee.List<int>> ();
        Map<string,Gee.List<Gee.List<string>>> entries =
            new HashMap<string,Gee.List<Gee.List<string>>> ();

        void load () throws DictionaryError, GLib.IOError {
        }

        public void save () throws GLib.Error {
        }

        public void reload () throws GLib.Error {
#if VALA_0_16
            string attributes = FileAttribute.ETAG_VALUE;
#else
            string attributes = FILE_ATTRIBUTE_ETAG_VALUE;
#endif
            FileInfo info = file.query_info (attributes,
                                             FileQueryInfoFlags.NONE);
            if (info.get_etag () != etag) {
                this.constraints.clear ();
                this.entries.clear ();
                try {
                    load ();
                } catch (DictionaryError e) {
                    warning ("error parsing user dictionary %s: %s",
                             file.get_path (), e.message);
                } catch (GLib.IOError e) {
                    warning ("error reading user dictionary %s: %s",
                             file.get_path (), e.message);
                }
            }
        }

        public int[] lookup_constraints (string input) {
            return new int[0];
        }

        public string[] lookup_sequence (string[] sequence) {
            return new string[0];
        }
 
        /**
         * {@inheritDoc}
         */
        public bool read_only {
            get {
                return false;
            }
        }
   }
}