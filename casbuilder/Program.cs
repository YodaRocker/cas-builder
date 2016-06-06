using System;
using System.Collections.Generic;
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

                var systemBytes = File.ReadAllBytes(args[0]);

                var remainingLength = systemBytes.Length;
                var blocks = (remainingLength + 255)/256;

                Log(ConsoleColor.Green, $"blocks: {blocks}");

                var casFile = new List<byte>();

                // !! fixme
                var loadAddress = 0x7f00;
                var executeAddress = 0x7f00;

                casFile.AddRange(Enumerable.Repeat<byte>(0, 256));
                casFile.Add(0xa5);
                casFile.Add(0x55);

                var fileNameWithoutExtension = Path.GetFileNameWithoutExtension(args[0]);
                if (fileNameWithoutExtension != null)
                {
                    var filename =
                        fileNameWithoutExtension.Substring(0, Math.Min(6, fileNameWithoutExtension.Length))
                            .PadRight(6)
                            .ToUpperInvariant();
                    casFile.AddRange(Encoding.ASCII.GetBytes(filename));
                }
                else
                {
                    casFile.AddRange(Encoding.ASCII.GetBytes("UNKNWN"));
                }

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

                File.WriteAllBytes(Path.ChangeExtension(args[0], ".cas"), casFile.ToArray());

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