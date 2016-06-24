#include <stdio.h>

typedef unsigned char BYTE;


int blobbyLoadAddress;
BYTE blobFileType;
extern BYTE ioBuffer[512];

BYTE ioBuffer[512];

int GetBlobbyFileType(FILE* userFile, BYTE* blobType)
{
	size_t result;

	while (1)
	{
		result = fread(ioBuffer, 1, 1, userFile);
		if (result != 1) return -1;

		if (ioBuffer[0] != 0)
			break;
	}

	if (ioBuffer[0] == 0xa5)
	{
		result = fread(ioBuffer, 1, 1, userFile);
		if (result != 1) return -1;

		if (ioBuffer[0] == 0x55)
		{
			result = fread(ioBuffer, 1, 6, userFile);
			if (result != 6) return -1;

			*blobType = 1; // SYSTEM
			blobbyLoadAddress = 0x4300; // safe(ish) default load address
			return 1;
		}
		else if (ioBuffer[0] == 0xd3)
		{
			result = fread(ioBuffer, 1, 2, userFile);
			if (result != 2) return -1;

			if (ioBuffer[0] == 0xd3 && ioBuffer[1] == 0xd3)
			{
				*blobType = 2; // BAS
				blobbyLoadAddress = 0x42e9; // default BASIC load address
				return 1;
			}
		}
	}

	*blobType = 255; // UNKNOWN
	return 1;
}


int ReadBlob(FILE* inFile, int* loadAddress, BYTE* blobSize)
{
	size_t result;

	switch (blobFileType)
	{
		case 1:
		{
			result = fread(ioBuffer, 1, 4, inFile);
			if (*ioBuffer == 0x3c)
			{
				blobbyLoadAddress = ioBuffer[2] + 256 * ioBuffer[3];

				int bsize = ioBuffer[1] ? ioBuffer[1] : 256;

				*blobSize = bsize & 255;
				*loadAddress = blobbyLoadAddress;

				ioBuffer[0] = bsize & 255;
				ioBuffer[1] = blobbyLoadAddress & 255;
				ioBuffer[2] = blobbyLoadAddress / 256;
				result = fread(&ioBuffer[3], 1, bsize + 1, inFile);
				return 1;
			}
			else if (ioBuffer[0] == 0x78)
			{
				int execAddr = ioBuffer[1] + 256 * ioBuffer[2];

				ioBuffer[0] = 2;
				ioBuffer[1] = 0xd4;
				ioBuffer[2] = 0x40;
				ioBuffer[3] = execAddr & 255;
				ioBuffer[4] = execAddr / 256;
				*loadAddress = 0x40df;
				*blobSize = 2;

				return 0;
			}
		}
		return -1;

		case 2:
			result = fread(&ioBuffer[3], 1, 256, inFile);
			if (result != 0)
			{
				*loadAddress = blobbyLoadAddress;
				*blobSize = result & 255;
				ioBuffer[0] = result & 255;
				ioBuffer[1] = blobbyLoadAddress & 255;
				ioBuffer[2] = blobbyLoadAddress / 256;
				blobbyLoadAddress += result;
			}
			else
			{
				ioBuffer[0] = 2;
				ioBuffer[1] = 0xd4;
				ioBuffer[2] = 0x40;
				ioBuffer[3] = 0x02;
				ioBuffer[4] = 0x03;
				*loadAddress = 0x40df;
				*blobSize = 2;

				return 0; // no more blobs after this one
			}
			break;

		default:
			break;
	}

	return 1;
}


int main(int argc, char **argv)
{
	FILE* inFile;

	if (fopen_s(&inFile, argv[1], "rb")) return 0;

	if (GetBlobbyFileType(inFile, &blobFileType) == -1) return 0;

	printf("file type: %d\n", blobFileType);

	BYTE blobSize;
	int loadAddress;

	int blobResult;
	while ((blobResult = ReadBlob(inFile, &loadAddress, &blobSize)) > 0)
	{
		printf(" len %02x  la %04x\n", blobSize, loadAddress);
	}
	if (blobResult == 0)
		printf(" len %02x  la %04x\n", blobSize, loadAddress);
	else
		printf("File error, unrecognised blob");

	fclose(inFile);

	return 0;
}
