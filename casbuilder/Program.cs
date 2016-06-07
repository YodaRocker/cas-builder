using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;

namespace casbuilder
{
    public static class Program
    {
        private static ConsoleColor _oldConsoleColour;

        private static void Log(string s)
        {
            Log(_oldConsoleColour, s);
        }

        private static void Log(ConsoleColor c, string s)
        {
            Console.ForegroundColor = c;
            Console.WriteLine(s);
        }

        public static void Main(string[] args)
        {
            _oldConsoleColour = Console.ForegroundColor;

            try
            {
                if (args.Length == 0)
                {
                    Log(ConsoleColor.Red, "Argument error.");
                    Log("Usage: casbuilder BINFILE (/out=CASFILE) (/pname=XYZ) (/load=HHHH) (/exec=HHHH)");
                    Log("    HHHH is 4 hex digits specifying load or exec address.");
                    Log("    Default load = 7f00, default exec = load.");
                    Log("    Default out filename is input filename with extension changed to .cas");
                    Log("    Default pname is input filename truncated to 6 characters.");
                    Log("    XYZ is string, max 6 characters.");
                    return;
                }

                var inputFilename = args[0];
                var outputFilename = Path.ChangeExtension(inputFilename, ".cas");

                ArgParser.CheckArg(args, "out", ref outputFilename);
                Log($"output: '{outputFilename}'");

                var outputFilenameNoExtension = Path.GetFileNameWithoutExtension(outputFilename) ?? "UNKNWN";

                var progname = outputFilenameNoExtension;
                ArgParser.CheckArg(args, "pname", ref progname);

                var prognameBytes = Encoding.ASCII.GetBytes(progname.ToUpper());
                Array.Resize(ref prognameBytes, 6);

                Log($"program name: '{Encoding.ASCII.GetString(prognameBytes)}'");

                var hexString = string.Empty;

                var loadAddress = 0x7f00;
                if (ArgParser.CheckArg(args, "load", ref hexString))
                    loadAddress = int.Parse(hexString, NumberStyles.HexNumber);

                var executeAddress = loadAddress;
                if (ArgParser.CheckArg(args, "exec", ref hexString))
                    executeAddress = int.Parse(hexString, NumberStyles.HexNumber);

                var prologLen = 32;
                ArgParser.CheckArg(args, "prolog", ref prologLen);

                Log($"Load: ${loadAddress:X}\nExec: ${executeAddress:X}");

                var systemBytes = File.ReadAllBytes(inputFilename);

                var remainingLength = systemBytes.Length;
                var blocks = (remainingLength + 255) / 256;

                Log($"blocks: {blocks}");

                var casFile = new List<byte>();

                casFile.AddRange(Enumerable.Repeat<byte>(0, prologLen));

                casFile.Add(0xa5);
                casFile.Add(0x55);

                casFile.AddRange(prognameBytes);

                for (var i = 0; i < blocks; ++i)
                {
                    var blockSize = Math.Min(remainingLength, 256);
                    remainingLength -= blockSize;

                    casFile.Add(0x3c);
                    casFile.Add((byte) (blockSize == 256 ? 0 : blockSize));

                    var checksummedBlock = new List<byte> {(byte) (loadAddress & 255), (byte) (loadAddress/256)};
                    loadAddress += 256;

                    checksummedBlock.AddRange(systemBytes.Skip(i*256).Take(blockSize));
                    casFile.AddRange(checksummedBlock);

                    var check = checksummedBlock.Aggregate<byte, byte>(0, (current, b) => (byte) ((current + b) & 0xff));
                    casFile.Add(check);
                }

                casFile.Add(0x78);

                casFile.Add((byte) (executeAddress & 255));
                casFile.Add((byte) (executeAddress / 256));

                File.WriteAllBytes(outputFilename, casFile.ToArray());

                Log(ConsoleColor.Green, "All good.");
            }
            catch (Exception ex)
            {
                Log(ConsoleColor.Red, $"There was an exception: {ex.Message}");
            }
            finally
            {
                Console.ForegroundColor = _oldConsoleColour;
            }
        }
    }
}