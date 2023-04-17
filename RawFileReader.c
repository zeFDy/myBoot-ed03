#include "common.h"

uint8_t*   ucDestination;

void 	Read4Bytes(unsigned char *ucBuffer)
{
	for(int iCounter =0; iCounter<4; iCounter++)
	{
		ucBuffer[iCounter] = getc();
	}
}

void    ChargementApplicativeViaFichierRAW()
{
	int 			iLineCounter =0;
	char 			caMagic[4];
	uint32_t 		uiMagic=0;
	unsigned char 	ucOffset[4];
	uint32_t 		uiOffset=0;
	unsigned char 	ucLength[4];
	uint32_t 		uiLength=0;
	
    // chargement du fichier RAW en DRAM
	// normalement recupere l'info d'offset pour la destination
    ucDestination = (uint8_t*) 0x0000;        // put in DRAM

    memset(ucDestination,   0, 0x10000);
    
	Read4Bytes(caMagic);
	uiMagic = *((uint32_t*)caMagic);
	puts("Magic  is ");
	puts(caMagic);
	puts("\r\n");
	
//	if(strcmp(caMagic, "RAW1")!=0)
//	{
//		puts("Error on RAW file header\r\n");
//		for(;;);
//	}
	if(uiMagic!="RAW1")
	{
		puts("Error on RAW file header\r\n");
		for(;;);
	}
	
	Read4Bytes(ucOffset);
	uiOffset = *((uint32_t*)ucOffset);
	puts("Offset is ");
	putHexa32(uiOffset);
	puts("\r\n");
	
	Read4Bytes(ucLength);
	uiLength = *((uint32_t*)ucLength);
	puts("Length is ");
	putHexa32(uiLength);
	puts("\r\n");
	
	while(iLineCounter<uiLength)
	{
		char c = getc();

		ucDestination[iLineCounter] = c;
		iLineCounter++;
	}
	
}
