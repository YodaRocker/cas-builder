using System;
using System.Runtime.Serialization;

namespace cas2gne
{
    [Serializable]
    internal class UnexpectedEndOfFile : Exception
    {
        public UnexpectedEndOfFile()
        {
        }

        public UnexpectedEndOfFile(string message) : base(message)
        {
        }

        public UnexpectedEndOfFile(string message, Exception innerException) : base(message, innerException)
        {
        }

        protected UnexpectedEndOfFile(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}