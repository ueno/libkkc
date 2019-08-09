/* testcase.vala
 *
 * Copyright (C) 2009 Julien Peeters
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *  Julien Peeters <contact@julienpeeters.fr>
 *
 * Copied from libgee/tests/testcase.vala.
 */

public abstract class Kkc.TestCase : Object
{
  private GLib.TestSuite _suite;
  private Adaptor[] _adaptors = new Adaptor[0];

  public delegate void TestMethod ();

  protected TestCase (string name)
    {
      this._suite = new GLib.TestSuite (name);
    }

  public void add_test (string name, TestMethod test)
    {
      var adaptor = new Adaptor (name, test, this);
      this._adaptors += adaptor;

      this._suite.add (new GLib.TestCase (
            adaptor.name, adaptor.set_up, adaptor.run, adaptor.tear_down));
    }

  public virtual void set_up ()
    {
    }

  public virtual void tear_down ()
    {
    }

  public GLib.TestSuite get_suite ()
    {
      return this._suite;
    }

    private class Adaptor
    {
      public string name { get; private set; }
      private unowned TestMethod _test;
      private TestCase _test_case;

      public Adaptor (string name, TestMethod test, TestCase test_case)
        {
          this._name = name;
          this._test = test;
          this._test_case = test_case;
        }

      public void set_up (void* fixture)
        {
          GLib.set_printerr_handler (Adaptor._printerr_func_stack_trace);
          Log.set_default_handler (this._log_func_stack_trace);

          this._test_case.set_up ();
        }

      private static void _printerr_func_stack_trace (string? text)
        {
          if (text == null || str_equal (text, ""))
            return;

          stderr.printf (text);

          /* Print a stack trace since we've hit some major issue */
          GLib.on_error_stack_trace ("libtool --mode=execute gdb");
        }

      private void _log_func_stack_trace (string? log_domain,
          LogLevelFlags log_levels,
          string message)
        {
          Log.default_handler (log_domain, log_levels, message);

          /* Print a stack trace for any message at the warning level or above
           */
          if ((log_levels &
              (LogLevelFlags.LEVEL_WARNING | LogLevelFlags.LEVEL_ERROR |
                  LogLevelFlags.LEVEL_CRITICAL))
              != 0)
            {
              GLib.on_error_stack_trace ("libtool --mode=execute gdb");
            }
        }

      public void run (void* fixture)
        {
          this._test ();
        }

      public void tear_down (void* fixture)
        {
          this._test_case.tear_down ();
        }
    }
}
