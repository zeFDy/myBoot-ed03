/*
 * armboot - Startup Code for OMAP3530/ARM Cortex CPU-core
 *
 * Copyright (c) 2004	Texas Instruments <r-woodruff2@ti.com>
 *
 * Copyright (c) 2001	Marius Gröger <mag@sysgo.de>
 * Copyright (c) 2002	Alex Züpke <azu@sysgo.de>
 * Copyright (c) 2002	Gary Jennejohn <garyj@denx.de>
 * Copyright (c) 2003	Richard Woodruff <r-woodruff2@ti.com>
 * Copyright (c) 2003	Kshitij <kshitij@ti.com>
 * Copyright (c) 2006-2008 Syed Mohammed Khasim <x0khasim@ti.com>
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */


/*************************************************************************
 *
 * Startup Code (reset vector)
 *
 * Do important init only if we don't start from memory!
 * Setup memory and board specific bits prior to relocation.
 * Relocate armboot to ram. Setup stack.
 *
 *************************************************************************/

	.globl	_start
	.globl	reset
	.globl 	cpu_init_cp15
	.globl 	_main	
	.globl	alt_int_handler_irq

/*
 *************************************************************************
 *
 * Vectors have their own section so linker script can map them easily
 *
 *************************************************************************
 */

	.section ".vectors", "ax"

/*
 *************************************************************************
 *
 * Exception vectors as described in ARM reference manuals
 *
 * Uses indirect branch to allow reaching handlers anywhere in memory.
 *
 *************************************************************************
 */

	.globl	_undefined_instruction
	.globl	_software_interrupt
	.globl	_prefetch_abort
	.globl	_data_abort
	.globl	_not_used
	.globl	alt_int_handler_irq
	.globl	_fiq
	
_start:

	b	reset
	ldr	pc, _undefined_instruction
	ldr	pc, _software_interrupt
	ldr	pc, _prefetch_abort
	ldr	pc, _data_abort
	ldr	pc, _not_used
	ldr	pc, _irq
	ldr	pc, _fiq


/*
 *************************************************************************
 *
 * Indirect vectors table
 *
 * Symbols referenced here must be defined somewhere else
 *
 *************************************************************************
 */


_undefined_instruction:	.word undefined_instruction
_software_interrupt:	.word software_interrupt
_prefetch_abort:		.word prefetch_abort
_data_abort:			.word data_abort
_not_used:				.word not_used
_irq:					.word irq
_fiq:					.word fiq
						.word 0xdeadbeef


///*
// *************************************************************************
// *
// * Interrupt handling
// *
// *************************************************************************
// */
//
///* SPL interrupt handling: just hang */
//
//

//	.align	5
undefined_instruction:
software_interrupt:
prefetch_abort:
data_abort:
not_used:
fiq:
1:
	bl	1b			/* hang and never return */


reset:

	/*
	 * disable interrupts (FIQ and IRQ), also set the cpu to SVC32 mode,
	 * except if in HYP mode already
	 */
	mrs	r0, cpsr
	and	r1, r0, #0x1f		@ mask mode bits
	teq	r1, #0x1a		@ test for HYP mode
	bicne	r0, r0, #0x1f		@ clear all mode bits
	orrne	r0, r0, #0x13		@ set SVC mode
	orr	r0, r0, #0xc0		@ disable FIQ and IRQ
	msr	cpsr,r0

	/*
	* Setup vector:
	* (OMAP4 spl TEXT_BASE is not 32 byte aligned.
	* Continue to use ROM code vector only in OMAP4 spl)
	*/

	/* Set V=0 in CP15 SCTLR register - for VBAR to point to vector */
	mrc	p15, 0, r0, c1, c0, 0	@ Read CP15 SCTLR Register
	bic	r0, #0x2000				@ CR_V = 0x2000		@ V = 0
	mcr	p15, 0, r0, c1, c0, 0	@ Write CP15 SCTLR Register

	/* Set vector address in CP15 VBAR register */
	ldr	r0, =_start
	mcr	p15, 0, r0, c12, c0, 0	@Set VBAR

	/* the mask ROM code should have PLL and others stable */
	bl		cpu_init_cp15

	/* FDy : call board_init_f from \arch\arm\mach-socfpga\spl.c instead of main for crt0.lib */ 
	bl		_main

/*------------------------------------------------------------------------------*/

c_runtime_cpu_setup:

	/*
	* If I-cache is enabled invalidate it
	*/

	mcr	p15, 0, r0, c7, c5, 0	@ invalidate icache
	mcr     p15, 0, r0, c7, c10, 4	@ DSB
	mcr     p15, 0, r0, c7, c5, 4	@ ISB

	bx	lr


/*************************************************************************
 *
 * cpu_init_cp15
 *
 * Setup CP15 registers (cache, MMU, TLBs). The I-cache is turned on unless
 * CONFIG_SYS_ICACHE_OFF is defined.
 *
 *************************************************************************/
cpu_init_cp15:
	/*
	 * Invalidate L1 I/D
	 */
	mov	r0, #0			@ set up for MCR
	mcr	p15, 0, r0, c8, c7, 0	@ invalidate TLBs
	mcr	p15, 0, r0, c7, c5, 0	@ invalidate icache
	mcr	p15, 0, r0, c7, c5, 6	@ invalidate BP array
	mcr     p15, 0, r0, c7, c10, 4	@ DSB
	mcr     p15, 0, r0, c7, c5, 4	@ ISB

	/*
	 * disable MMU stuff and caches
	 */
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, r0, #0x00002000	@ clear bits 13 (--V-)
	bic	r0, r0, #0x00000007	@ clear bits 2:0 (-CAM)
	orr	r0, r0, #0x00000002	@ set bit 1 (--A-) Align
	orr	r0, r0, #0x00000800	@ set bit 11 (Z---) BTB
	orr	r0, r0, #0x00001000	@ set bit 12 (I) I-cache
	mcr	p15, 0, r0, c1, c0, 0

	mov	r5, lr			@ Store my Caller
	mrc	p15, 0, r1, c0, c0, 0	@ r1 has Read Main ID Register (MIDR)
	mov	r3, r1, lsr #20		@ get variant field
	and	r3, r3, #0xf		@ r3 has CPU variant
	and	r4, r1, #0xf		@ r4 has CPU revision
	mov	r2, r3, lsl #4		@ shift variant field for combined value
	orr	r2, r4, r2		@ r2 has combined CPU variant + revision

	mov	pc, r5			@ back to my caller

_main:
/*
 * Set up initial C runtime environment and call board_init_f(0).
 */
	/* Set vector address in CP15 VBAR register */
	ldr	r0, =_start
	mcr	p15, 0, r0, c12, c0, 0	@Set VBAR

	ldr	r0, =0xFFFFFF40
	ldr	r0, =0xFFFFFF00
	bic	r0, r0, #7	/* 8-byte alignment for ABI compliance */
	mov	sp, r0

	mov	r9, r0
	mov	r0, #0
	bl	board_init

//
// IRQ - set LED & send carac for the moment
//
irq:	push {r0-r7, lr}

		//ldr r0, LedValue	/* 1<<24 */
		//ldr r1, LedData	/* LedData port in memory */
		//str r0, [r1, #0]

		ldr r0, UartValue	/* 'I' */
		ldr r1, UartData	/* UartData port in memory */
		str r0, [r1, #0]
		
		/*
		bx 	lr
		*/
		bl 	alt_int_handler_irq
		
		pop		{R0-R7, LR}
		subs	PC, LR, #4

lirq:
		bl	lirq				/* on boucle ici (pour le moment) */

LedValue:	.word 	0x01000000
LedData:	.word 	0xFF709000

UartValue:	.word 	'I'
UartData:	.word	0xFFC02000

