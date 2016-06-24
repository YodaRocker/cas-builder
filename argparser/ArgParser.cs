using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
// ReSharper disable StringIndexOfIsCultureSpecific.1

namespace argparser
{
    public static class ArgParser
    {
        public static bool SwitchPresent(IEnumerable<string> args, string argumentName)
        {
            var item =
                args.FirstOrDefault(
                    arg => arg.StartsWith("/" + argumentName, StringComparison.CurrentCultureIgnoreCase));

            return item != null;
        }

        public static bool CheckArg<T>(IEnumerable<string> args, string argumentName, ref T targetVariable)
        {
            var item = args.FirstOrDefault(arg => arg.StartsWith("/" + argumentName + "=", StringComparison.CurrentCultureIgnoreCase));

            // item = null if no matching string in the argument list or malformed parameter tag
            //
            if (item == null) return false;

            // equalsIndex == item.Length - 1 if an empty parameter tag i.e. '/arg='
            //
            var equalsIndex = item.IndexOf("=");
            if(equalsIndex == item.Length - 1) return false;

            try
            {
                var converter = TypeDescriptor.GetConverter(typeof(T));
                targetVariable = (T)converter.ConvertFrom(item.Substring(equalsIndex + 1));

                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}