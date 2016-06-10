using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using argparser;

namespace cas2gne
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
                    Log("Usage: cas2gne CASFILE (/out=GNEFILE)");
                    Log("    Default out filename is input filename with extension changed to .gne");
                    return;
                }

                var inputFilename = args[0];
                var outputFilename = Path.ChangeExtension(inputFilename, ".gne");

                ArgParser.CheckArg(args, "out", ref outputFilename);
                Log($"output: '{outputFilename}'");

                var casBytes = File.ReadAllBytes(inputFilename);

                // discard header
                var idx = Array.IndexOf<byte>(casBytes, 0x55, 0);
                idx += 8;

                int blockLen = casBytes[idx];
                if (blockLen == 0) blockLen = 256;

                var totalLength = blockLen;
                var loadAddress = casBytes[idx + 1] + 256 * casBytes[idx + 2];

                // GNE file initialised with dummy values for len & exec, load should be good ;)
                var gneFile = new List<byte>
                {
                    casBytes[idx + 1],  // load
                    casBytes[idx + 2],
                    0,                  // len
                    0,
                    casBytes[idx + 1],  // exec
                    casBytes[idx + 2]
                };

                idx += 3;
                gneFile.AddRange(casBytes.Skip(idx).Take(blockLen));

                idx += blockLen + 1;    // skip checksum

                while (casBytes[idx] != 0x78)
                {
                    blockLen = casBytes[idx + 1] == 0 ? 256 : casBytes[idx + 1];
                    totalLength += blockLen;

                    gneFile.AddRange(casBytes.Skip(idx + 4).Take(blockLen));
                    idx += blockLen + 5;
                }

                gneFile[2] = (byte)(totalLength & 255);
                gneFile[3] = (byte)(totalLength / 256);
                gneFile[4] = casBytes[idx + 1];
                gneFile[5] = casBytes[idx + 2];

                File.WriteAllBytes(outputFilename, gneFile.ToArray());

                Log($"memory range: ${loadAddress:X} .. ${loadAddress + totalLength:X}");

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