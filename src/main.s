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
	IMPORT  motorControl_init
	IMPORT 	hexDisplay_init
	IMPORT  open_gate
	IMPORT  close_gate
	IMPORT  move_platform
	
	AREA    main, CODE, READONLY
	EXPORT	__main				; make __main visible to linker
	ENTRY			
				
__main	PROC
		
		BL System_Clock_Init    ; set up system clock first
		BL UART2_Init           ; then init UART2 before any USART2_Write calls
		BL hexDisplay_init
		BL motorControl_init
		
		MOV r6, #0		;Current Position
		MOV r4, #0
		MOV r5, #1024
		BL open_gate
		BL close_gate
		BL move_platform
		
		BL open_gate
		BL close_gate
		MOV r5, #0
		BL move_platform
		
		BL open_gate
		BL close_gate
		MOV r5, #512
		BL move_platform
		
		BL open_gate
		BL close_gate
		MOV r5, #0
		BL move_platform
		
		BL open_gate
		BL close_gate
		MOV r5, #1536
		BL move_platform
		
		BL open_gate
		BL close_gate
		MOV r5, #0
		BL move_platform
	
stop    B stop 
		
	ENDP		
	
	
	ALIGN			

	AREA myData, DATA, READWRITE
	ALIGN

	END