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
        private static void Log(ConsoleColor c, string s)
        {
            Console.ForegroundColor = c;
            Console.WriteLine(s);
        }

        public static void Main(string[] args)
        {
            var oldConsoleColour = Console.ForegroundColor;

            try
            {
                if (args.Length == 0 || !File.Exists(args[0]))
                {
                    Log(ConsoleColor.Red, "Please specify a binary file to convert.");
                    return;
                }

                var inputFilename = args[0];

                var loadAddress = 0x7f00;
                var executeAddress = 0x7f00;

                var nameParts = Path.GetFileNameWithoutExtension(inputFilename).Split('@','!');
                if (nameParts.Length == 3)
                {
                    loadAddress = int.Parse(nameParts[1], NumberStyles.HexNumber);
                    executeAddress = int.Parse(nameParts[2], NumberStyles.HexNumber);

                    Log(oldConsoleColour,
                        $"Load: ${loadAddress:X}\nExec: ${executeAddress:X}");
                }
                else
                {
                    Log(ConsoleColor.DarkYellow,
                        $"Warning: Using default load (${loadAddress:X}) & exec (${executeAddress:X}) addresses ");
                }

                var systemBytes = File.ReadAllBytes(inputFilename);

                var remainingLength = systemBytes.Length;
                var blocks = (remainingLength + 255)/256;

                Log(oldConsoleColour, $"blocks: {blocks}");

                var casFile = new List<byte>();

                casFile.AddRange(Enumerable.Repeat<byte>(0, 64));

                casFile.Add(0xa5);
                casFile.Add(0x55);

                var filename = nameParts[0].Substring(0, Math.Min(6, nameParts[0].Length)).PadRight(6).ToUpperInvariant();
                casFile.AddRange(Encoding.ASCII.GetBytes(filename));

                for (var i = 0; i < blocks; ++i)
                {
                    var blockSize = Math.Min(remainingLength, 256);

                    casFile.Add(0x3c);
                    casFile.Add((byte) (blockSize == 256 ? 0 : blockSize));

                    var subsetOfprogram = new List<byte> {(byte) (loadAddress & 255), (byte) (loadAddress/256)};
                    loadAddress += 256;

                    subsetOfprogram.AddRange(systemBytes.Skip(i*256).Take(blockSize));
                    casFile.AddRange(subsetOfprogram);

                    var check = subsetOfprogram.Aggregate<byte, byte>(0, (current, b) => (byte) ((current + b) & 0xff));
                    casFile.Add(check);
                }

                casFile.Add(0x78);

                casFile.Add((byte) (executeAddress & 255));
                casFile.Add((byte) (executeAddress/256));

                File.WriteAllBytes(Path.ChangeExtension(nameParts[0], ".cas"), casFile.ToArray());

                Log(ConsoleColor.Green, "All good.");
            }
            catch (Exception ex)
            {
                Log(ConsoleColor.Red, $"There was an exception: {ex.Message}");
            }
            finally
            {
                Console.ForegroundColor = oldConsoleColour;
            }
        }
    }
}