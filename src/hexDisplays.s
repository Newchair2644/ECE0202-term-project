;******************** (C) Yifeng ZHU *******************************************
; @file    main.s
; @author  Yifeng Zhu
; @date    May-17-2015
; @note
;           This code is for the book "Embedded Systems with ARM Cortex-M 
;           Microcontrollers in Assembly Language and C, Yifeng Zhu, 
;           ISBN-13: 978-0982692639, ISBN-10: 0982692633
; @attension
;           This code is provided for education purpose. The author shall not be 
;           held liable for any direct, indirect or consequential damages, for any 
;           reason whatever. More information can be found from book website: 
;           http:;www.eece.maine.edu/~zhu/book
;*******************************************************************************


	INCLUDE core_cm4_constants.s		; Load Constant Definitions
	INCLUDE stm32l476xx_constants.s      

	IMPORT 	System_Clock_Init
	IMPORT 	UART2_Init
	IMPORT	USART2_Write
	
	AREA    main, CODE, READONLY
	EXPORT	hexDisplay_init				; make __main visible to linker
	EXPORT  display_level
				
hexDisplay_init PROC
		LDR r0, =RCC_BASE			;C Clock
		LDR r1, [r0, #RCC_AHB2ENR]
		BIC r1, r1, #0x00000004
		ORR r1, r1, #0x00000004
		STR r1, [r0, #RCC_AHB2ENR]
		
		LDR r0, =GPIOC_BASE			;C MODER
		LDR r1, [r0, #GPIO_MODER]
		LDR r2, =0x003FFFC0
		BIC r1, r1, r2
		LDR r2, =0x00155540			;pins 3->10 Output (01)
		ORR r1, r1, r2
		STR r1, [r0, #GPIO_MODER]
		BX lr
	ENDP
		

display_level PROC; expects r4 = ADC value
		PUSH {r0, r1, r2} 
		LDR r0, =GPIOC_BASE 
		LDR r1, [r0, #GPIO_ODR]; bits PC3-PC6 0x0:0:0:0:0:0:0111:1000
		CMP r4, #0
		BICEQ r1, r1, #0x78 ;clear ;0
		CMP r4, #512
		BICEQ r1, r1, #0x78
		ORREQ r1, r1, #0x08 ;1
		CMP r4, #1024
		BICEQ r1, r1, #0x78
		ORREQ r1, r1, #0x10 ;2
		CMP r4, #1536
		BICEQ r1, r1, #0x78
		ORREQ r1, r1, #0x18 ;3
		CMP r4, #2048
		BICEQ r1, r1, #0x78
		ORREQ r1, r1, #0x20 ;4
		STR r1, [r0, #GPIO_ODR];
		POP {r0, r1, r2}
		BX lr

	ENDP

stop 	B 		stop     		; dead loop & program hangs here


	AREA myData, DATA, READWRITE
	ALIGN

	END