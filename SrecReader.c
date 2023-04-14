// SrecReader.cpp : Ce fichier contient la fonction 'main'. L'exécution du programme commence et se termine à cet endroit.
//


//#define         FILENAME    "SdRamExec.srec"
//char            caInBuffer[4096];
//unsigned char   ucDest[8192];

unsigned char   HexAsciiToNibble(char cAscii)
{
    unsigned char ucNibble = 0;
    ucNibble = cAscii - '0';
    if(ucNibble>9)  ucNibble -=7;

    return ucNibble;
}

unsigned char   HexAsciiToByte(char* caAscii)
{
    unsigned char   ucMsN = caAscii[0];
    unsigned char   ucLsN = caAscii[1];

    ucMsN = HexAsciiToNibble(ucMsN);
    ucLsN = HexAsciiToNibble(ucLsN);

    //printf("%X%X", ucMsN, ucLsN);
    return ((ucMsN<<4) + ucLsN);
}

unsigned char   GetCount(char* caLine)
{
    return HexAsciiToByte(&caLine[2]);
}

unsigned int    GetAddressS3(char* caLine)
{
    unsigned char   ucByte0 =HexAsciiToByte(&caLine[4]);
    unsigned char   ucByte1 =HexAsciiToByte(&caLine[6]);
    unsigned char   ucByte2 =HexAsciiToByte(&caLine[8]);
    unsigned char   ucByte3 =HexAsciiToByte(&caLine[10]);

    unsigned int    uiValue = (ucByte0 << 24) + (ucByte1 << 16) + (ucByte2 << 8) + (ucByte3);
    return uiValue;
}

unsigned int    GetDataS3(char* caLine, unsigned int uiIndex)
{
    unsigned char   ucByte = HexAsciiToByte(&caLine[12+(uiIndex*2)]);
    return ucByte;
}


char* SrecReadLine( char*           ucSrecStart, 
                    unsigned int*   uiStart,
                    unsigned int*   uiIsFinished)
{
    unsigned int     uiOffset       = *uiStart;
    unsigned int     uiCopyOfStart  = *uiStart;

    while (*uiIsFinished == 0)
    {
        char c = ucSrecStart[uiOffset];
        if (c == 0x0A)
        {
            *uiStart = uiOffset+1;
            ucSrecStart[uiOffset] = 0;
            return &ucSrecStart[uiCopyOfStart];
        }

        uiOffset++;
    }

    *uiIsFinished = 1;
    return 0;
}

int SrecReader(char* caInput, unsigned char* ucDest)
{
    unsigned int    uiIsFinished    = 0;
    unsigned int    uiStart         = 0;
    unsigned int    uiEnd           = 0;
    unsigned int    uiLineCount     = 0;
    unsigned int    uiAddress       = 0;
    
    // count prend en compte les adresses et le checksum, il faut donc les enlever (d'ou l'OFFSET négatif)
    #define     DATAOFFSETS3    5

    while (uiIsFinished == 0)
    {
        char *caLine = SrecReadLine(caInput, &uiStart, &uiIsFinished);

        if (caLine[0] != 'S')  break;

        switch (caLine[1])
        {
            case    '0':    //printf("S0 -> %s\n\r", caLine);
                            // header record
                            // 32bit address
                            uiLineCount = GetCount(caLine);
                            //printf("uiLineCount = 0x%.02X (%d)\n", uiLineCount, uiLineCount);
                            for (int    iByteCounter = 0;
                                        iByteCounter < uiLineCount - DATAOFFSETS3;
                                        iByteCounter++)
                            {
                                unsigned char ucByte = GetDataS3(caLine, iByteCounter);
                                //printf("%c", ucByte);

                            }
                            //printf("\n\r");
                            break;

            case    '1':    //printf("S1 -> %s\n\r", caLine);
                            // 16bit address
                            break;

            case    '2':    //printf("S2 -> %s\n\r", caLine);
                            // 24bit address
                            break;

            case    '3':    //printf("S3 -> %s\n\r", caLine);
                            // 32bit address
                            uiLineCount = GetCount(caLine);
                            //printf("uiLineCount = 0x%.02X (%d)\n", uiLineCount, uiLineCount);
                            uiAddress = GetAddressS3(caLine);
                            //printf("uiAddress   = 0x%.08X (%d)\n", uiAddress, uiAddress);
                            //printf("0x%.08X - ", uiAddress);
                            //printf("Data        = ");
                            for (int    iByteCounter = 0;
                                        iByteCounter < uiLineCount - DATAOFFSETS3;
                                        iByteCounter++)
                            {
                                unsigned char ucByte = GetDataS3(caLine, iByteCounter);
                                //printf("%.02X ", ucByte);
                                ucDest[uiAddress + iByteCounter] = ucByte;
                            }
                            //printf("\n\r");
                            break;

            case    '4':    //printf("S4 -> %s\n\r", caLine);
                            // never used
                            break;

            case    '5':    //printf("S5 -> %s\n\r", caLine);
                            // optionnal record count
                            break;

            case    '6':    //rintf("S6 -> %s\n\r", caLine);
                            // never used
                            break;

            case    '7':    //printf("S7 -> %s\n\r", caLine);
                            // termination for S3
                            //uiLineCount = GetCount(caLine);
                            //printf("uiLineCount = 0x%.02X (%d)\n", uiLineCount, uiLineCount);
                            //uiAddress = GetAddressS3(caLine);
                            //printf("Entry Address = 0x%.08X\n", uiAddress);
                            uiIsFinished = 1;
                            break;

            case    '8':    //printf("S8 -> %s\n\r", caLine);
                            // termination for S2
                            uiIsFinished = 1; 
                            break;

            case    '9':    //printf("S9 -> %s\n\r", caLine);
                            // termination for S1
                            uiIsFinished = 1; 
                            break;

            default:        break;
        }

    }

    return 0;
}


// int main()
// {
//     FILE* myFile = NULL;
//
//     int iStatus = fopen_s(&myFile, FILENAME, "rb");
//     memset(caInBuffer, 0, 4096);
//     fseek(myFile, 0, SEEK_END);
//     unsigned int uiFileSize = ftell(myFile);
//     fseek(myFile, 0, SEEK_SET);
//
//     fread(caInBuffer, 1, uiFileSize, myFile);
//     fclose(myFile);
//
//     // ----------------------------------------
//
//     SrecReader(caInBuffer, ucDest);
//
// }
//char 			caLine[1024];
char*   caDestination;

void    ChargementApplicative()
{
	int 	iLineCounter =0;
	char 	cPrevious =0;

    // chargement du fichier SREC en DRAM
    caDestination = (char*) 0x10000;        // put in DRAM

    memset(caDestination,   0, 0x10000);
    memset(0x00000000,      0, 0x10000);

	while(1)
	{
		char c = getc();

		caDestination[iLineCounter] = c;
		
		if(		cPrevious=='S'	
			&&	c=='7'	)		break;
			
		iLineCounter++;
		cPrevious = c;
	}
	
	caDestination[iLineCounter+1] =0;

    // Extraction SREC vers sa destination 0x00000000
    SrecReader(caDestination, 0x00000000);

}
