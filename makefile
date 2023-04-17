TARGET = myBoot.o

#CROSS_COMPILE = arm-linux-gnueabihf-
CROSS_COMPILE = "C:/Program Files (x86)/GNU Arm Embedded Toolchain/10 2021.07/bin/arm-none-eabi-"
CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld.bfd 
CP = $(CROSS_COMPILE)objcopy 
OD = $(CROSS_COMPILE)objdump
ARCH = arm

CCOPT = -mthumb -mthumb-interwork -mabi=aapcs-linux  -mno-unaligned-access -ffunction-sections -fdata-sections -fno-common -ffixed-r9  -msoft-float -march=armv7-a
LDSCRIPT := myBoot.lds

OPTIONS = -Os -Wall -Wstrict-prototypes -Wno-format-security -fno-builtin -ffreestanding -mthumb -mthumb-interwork -mabi=aapcs-linux -mword-relocations  -fno-pic  -mno-unaligned-access -mno-unaligned-access -ffunction-sections -fdata-sections -fno-common -ffixed-r9 -msoft-float -march=armv7-a -P -c 


					
start.o:					start.S
							$(CC) -x assembler-with-cpp start.S -o start.o -c
							$(OD) -d start.o >start.lst
				
ClockManager.o:				ClockManager.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst
			
FreezeManager.o:			FreezeManager.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst
			
ScanManager.o:				ScanManager.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

FpgaManager.o:				FpgaManager.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst
			
sdram.o:					sdram.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

sequencer.o:				sequencer.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

hwlibs/src/alt_sdmmc.o:		hwlibs/src/alt_sdmmc.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

hwlibs/src/alt_clock_manager.o:	hwlibs/src/alt_clock_manager.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

hwlibs/src/alt_globaltmr.o:	hwlibs/src/alt_globaltmr.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

hwlibs/src/alt_timers.o:	hwlibs/src/alt_timers.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

hwlibs/src/alt_interrupt.o:	hwlibs/src/alt_interrupt.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

hwlibs/src/alt_watchdog.o:	hwlibs/src/alt_watchdog.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

hwlibs/src/alt_generalpurpose_io.o:	hwlibs/src/alt_generalpurpose_io.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

demos_hwlibs/timers_demo.o:	demos_hwlibs/timers_demo.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

demos_hwlibs/gpio_demo.o:	demos_hwlibs/gpio_demo.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

div64.o:					div64.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst

SrecReader.o:				SrecReader.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst
							
RawFileReader.o:			RawFileReader.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst
							
spl.o:						spl.c
							$(CC) $(OPTIONS) $^ -o $@
							$(OD) -d $@ >$@.lst


myBoot.o:		start.o 						\
				spl.o 							\
				SrecReader.o 					\
				RawFileReader.o 				\
				ClockManager.o					\
				FpgaManager.o 					\
				FreezeManager.o 				\
				ScanManager.o 					\
				sdram.o 						\
				sequencer.o 					\
				hwlibs/src/alt_sdmmc.o 			\
				hwlibs/src/alt_clock_manager.o	\
				hwlibs/src/alt_globaltmr.o 		\
				hwlibs/src/alt_interrupt.o		\
				hwlibs/src/alt_timers.o 		\
				hwlibs/src/alt_watchdog.o 		\
				hwlibs/src/alt_generalpurpose_io.o	\
				demos_hwlibs/timers_demo.o		\
				demos_hwlibs/gpio_demo.o		\
				div64.o
				$(LD) -T myBoot.lds --gc-sections -Bstatic --gc-sections -Ttext 0xFFFF0000 start.o --start-group \
				spl.o 							\
				SrecReader.o 					\
				RawFileReader.o 				\
				ClockManager.o 					\
				FpgaManager.o 					\
				FreezeManager.o 				\
				ScanManager.o 					\
				sdram.o 						\
				sequencer.o 					\
				hwlibs/src/alt_sdmmc.o 			\
				hwlibs/src/alt_clock_manager.o 	\
				hwlibs/src/alt_globaltmr.o 		\
				hwlibs/src/alt_interrupt.o		\
				hwlibs/src/alt_timers.o 		\
				hwlibs/src/alt_watchdog.o 		\
				hwlibs/src/alt_generalpurpose_io.o	\
				demos_hwlibs/timers_demo.o 		\
				demos_hwlibs/gpio_demo.o 		\
				lib.a 							\
				memset.o 						\
				div64.o 						\
				--end-group -o myBoot.o
				$(CP) -O binary myBoot.o myBoot.bin
				$(OD) -d myBoot.o >myBoot.lst
				$(OD) -x myBoot.o >myBoot.map
				./bin2img myBoot.bin myBoot.img
 
  
SdRamStart.o:	SdRamStart.S
				$(CC) -x assembler-with-cpp SdRamStart.S -o SdRamStart.o -c
				$(OD) -d SdRamStart.o >SdRamStart.lst
				
SdRamMain.o:	SdRamMain.c
				$(CC) $(OPTIONS) $^ -o $@
				$(OD) -d $@ >$@.lst

SdRamExec.o:	SdRamStart.o \
				demos_hwlibs/timers_demo.o		\
				hwlibs/src/alt_clock_manager.o 	\
				hwlibs/src/alt_globaltmr.o 		\
				hwlibs/src/alt_interrupt.o		\
				hwlibs/src/alt_timers.o 		\
				hwlibs/src/alt_watchdog.o 		\
				SdRamMain.o
				$(LD) -T SdRamExec.lds SdRamStart.o \
				SdRamMain.o \
				demos_hwlibs/timers_demo.o		\
				hwlibs/src/alt_clock_manager.o 	\
				hwlibs/src/alt_globaltmr.o 		\
				hwlibs/src/alt_interrupt.o		\
				hwlibs/src/alt_timers.o 		\
				hwlibs/src/alt_watchdog.o 		\
				lib.a 							\
				-o SdRamExec.o
				$(CP) -O binary SdRamExec.o SdRamExec.bin
				$(CP) --srec-forceS3 -O srec SdRamExec.o SdRamExec.txt	
				$(CP) -O ihex SdRamExec.o SdRamExec.hex	
				$(OD) -d SdRamExec.o >SdRamExec.lst
				$(OD) -x SdRamExec.o >SdRamExec.map
				./bin2raw SdRamExec.bin SdRamExec.raw


