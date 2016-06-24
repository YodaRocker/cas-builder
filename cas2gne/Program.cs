using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
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
                    Log("Usage: cas2gne CASFILE (/out=GNEFILE) (/v)");
                    Log("    Default out filename is input filename with extension changed to .gne");
                    return;
                }

                var inputFilename = args[0];
                var outputFilename = Path.ChangeExtension(inputFilename, ".gne");

                var verbose = ArgParser.SwitchPresent(args, "v");

                ArgParser.CheckArg(args, "out", ref outputFilename);
                Log($"output: '{outputFilename}'");

                var casBytes = File.ReadAllBytes(inputFilename);

                // discard header
                var idx = Array.IndexOf<byte>(casBytes, 0x55, 0) + 1;

                var storedName = new string(Encoding.ASCII.GetChars(casBytes, idx, 6));
                Log($"Stored name: '{storedName}'");

                // skip name, to first 4-byte block header (0x3c, len:1, load:2)
                idx += 6;

                var gneFile = new List<byte>(6);
                
                // peek ahead and get the first load address. we need this to work out if the blocks are contiguous

                var totalLength = 0;
                var loadAddress = casBytes[idx + 2] + 256 * casBytes[idx + 3];

                var nextExpectedLoadAddress = loadAddress;

                while (casBytes[idx] == 0x3c)
                {
                    var blockLen = casBytes[idx + 1] == 0 ? 256 : casBytes[idx + 1];
                    totalLength += blockLen;

                    var thisBlockLoadAddr = casBytes[idx + 2] + 256 * casBytes[idx + 3];
                    if (thisBlockLoadAddr != nextExpectedLoadAddress)
                    {
                        if (!verbose) throw new UnexpectedEndOfFile($"Non-contiguous load address detected: expected ${nextExpectedLoadAddress:X4}, got ${thisBlockLoadAddr:X4}.");
                    }
                    nextExpectedLoadAddress += blockLen;

                    gneFile.AddRange(casBytes.Skip(idx + 4).Take(blockLen));

                    if (verbose)
                    {
                        Log(ConsoleColor.Cyan, $"* Load: ${thisBlockLoadAddr:X4} Length: {blockLen}");
                    }

                    idx += blockLen + 5; // extra byte to skip checksum
                }

                if (casBytes[idx] != 0x78)
                {
                    var reason = $"Expected stream end ($78) but got ${casBytes[idx]:x2}.";
                    if (!verbose) throw new UnexpectedEndOfFile(reason);
                    Log(ConsoleColor.Cyan, reason);
                }

                if (idx != casBytes.Length - 3)
                {
                    var reason = $"End of file marker found at position {idx} but {casBytes.Length - idx} bytes remain unprocessed.";
                    if (!verbose) throw new UnexpectedEndOfFile(reason);
                    Log(ConsoleColor.Cyan, reason);
                }

                var execAddress = casBytes[idx + 1] + 256*casBytes[idx + 2];

                gneFile[0] = (byte) (loadAddress & 255);
                gneFile[1] = (byte) (loadAddress/256);
                gneFile[2] = (byte) (totalLength & 255);
                gneFile[3] = (byte) (totalLength/256);
                gneFile[4] = (byte) (execAddress & 255);
                gneFile[5] = (byte) (execAddress/256);

                File.WriteAllBytes(outputFilename, gneFile.ToArray());

                Log($"memory range: ${loadAddress:X} .. ${loadAddress + totalLength:X}");
                Log($"exec address: ${execAddress:X}");

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