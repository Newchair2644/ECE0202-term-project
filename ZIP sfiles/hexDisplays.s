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
	EXPORT  statusLEDS_init
	EXPORT	hexDisplay_init				; make __main visible to linker
	EXPORT  display_level
	EXPORT  update_LED_states
	EXPORT  initialize_open_spots
	EXPORT  increment_open_spots
	EXPORT  decrement_open_spots


statusLEDS_init PROC
		; Enable clocks for Port A, C, D
		LDR     r0, =RCC_BASE
		LDR     r1, [r0, #RCC_AHB2ENR]
		ORR     r1, r1, #0x00000001        ; bit 0 = GPIOA
		ORR     r1, r1, #0x00000004        ; bit 2 = GPIOC
		ORR     r1, r1, #0x00000008        ; bit 3 = GPIOD
		STR     r1, [r0, #RCC_AHB2ENR]

		; Configure PC11 and PC12 as output
		LDR     r0, =GPIOC_BASE
		LDR     r1, [r0, #GPIO_MODER]
		BIC     r1, r1, #0x00C00000
		ORR     r1, r1, #0x00400000        ; PC11 = gate status output
		BIC     r1, r1, #0x03000000
		ORR     r1, r1, #0x01000000        ; PC12 = platform status output
		STR     r1, [r0, #GPIO_MODER]

		; Configure PD2 as output
		LDR     r0, =GPIOD_BASE
		LDR     r1, [r0, #GPIO_MODER]
		BIC     r1, r1, #0x00000030
		ORR     r1, r1, #0x00000010        ; PD2 = emergency reset output
		STR     r1, [r0, #GPIO_MODER]

		; Configure PA8 as output
		LDR     r0, =GPIOA_BASE
		LDR     r1, [r0, #GPIO_MODER]
		BIC     r1, r1, #0x00030000
		ORR     r1, r1, #0x00010000        ; PA8 = system operating output
		STR     r1, [r0, #GPIO_MODER]
		BX lr
	ENDP
	
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
		
update_LED_states PROC
		; PD2 - Emergency Reset (R8 bit 2)
		LDR     r0, =GPIOD_BASE
		LDR     r1, [r0, #GPIO_ODR]
		BIC     r1, r1, #0x00000004
		TST     r8, #0x00000004
		ORRNE   r1, r1, #0x00000004
		STR     r1, [r0, #GPIO_ODR]

		; PA8 - System Idle (R8 bit 8)
		LDR     r0, =GPIOA_BASE
		LDR     r1, [r0, #GPIO_ODR]
		BIC     r1, r1, #0x00000100
		TST     r8, #0x00000100
		ORRNE   r1, r1, #0x00000100
		STR     r1, [r0, #GPIO_ODR]

		; PC11 + PC12 - Platform Status + Gate Status (R8 bits 11, 12)
		LDR     r0, =GPIOC_BASE
		LDR     r1, [r0, #GPIO_ODR]
		BIC     r1, r1, #0x00001800
		TST     r8, #0x00000800
		ORRNE   r1, r1, #0x00000800         ; PC11
		TST     r8, #0x00001000
		ORRNE   r1, r1, #0x00001000         ; PC12
		STR     r1, [r0, #GPIO_ODR]

		BX      lr
	ENDP


; r0 = pass +1 to increment, -1 to decrement
update_open_spots PROC
		PUSH    {r0, r1, r2, r3, lr}

		; Count occupied cars from R8 bits 31-24
		LSR     r1, r8, #24
		AND     r1, r1, #0xFF
		MOV     r2, #0

		LSR     r3, r1, #6
		AND     r3, r3, #0x03
		ADD     r2, r2, r3

		LSR     r3, r1, #4
		AND     r3, r3, #0x03
		ADD     r2, r2, r3

		LSR     r3, r1, #2
		AND     r3, r3, #0x03
		ADD     r2, r2, r3

		AND     r3, r1, #0x03
		ADD     r2, r2, r3

		; open = 8 - occupied, then apply either add or sub
		MOV     r1, #8
		SUB     r1, r1, r2                  ; r1 = open spots
		ADD     r1, r1, r0                  ; add 1 or -1

		; Update R9 bits 3-0
		BIC     r9, r9, #0x0000000F
		ORR     r9, r9, r1

		; TODO write to UART with the string parking spots available: x
		; Write to UART
		SUB     sp, sp, #8
		ADD     r0, r1, #48                 ; ASCII digit
		STRB    r0, [sp]
		MOV     r0, sp
		MOV     r1, #1
		BL      USART2_Write
		ADD     sp, sp, #8

		; Map R9 bits 3-0 to BCD pins (lsb -> msb 7-10)
		AND     r1, r9, #0x0000000F

		LDR     r0, =GPIOC_BASE
		LDR     r2, [r0, #GPIO_ODR]
		BIC     r2, r2, #0x00000780         ; clear PC7-PC10
		TST     r1, #0x01
		ORRNE   r2, r2, #0x00000080         ; PC7 = bit 0
		TST     r1, #0x02
		ORRNE   r2, r2, #0x00000100         ; PC8 = bit 1
		TST     r1, #0x04
		ORRNE   r2, r2, #0x00000200         ; PC9 = bit 2
		TST     r1, #0x08
		ORRNE   r2, r2, #0x00000400         ; PC10 = bit 3
		STR     r2, [r0, #GPIO_ODR]
		
		POP     {r0, r1, r2, r3, lr}
		BX      lr
	ENDP

initialize_open_spots PROC
		PUSH    {r0, lr}
		MOV     r0, #0
		BL      update_open_spots
		POP     {r0, lr}
		BX      lr
	ENDP
		
increment_open_spots PROC
		PUSH    {r0, lr}
		MOV     r0, #1
		BL      update_open_spots
		POP     {r0, lr}
		BX      lr
	ENDP

decrement_open_spots PROC
		PUSH    {r0, lr}
		MOV     r0, #-1
		BL      update_open_spots
		POP     {r0, lr}
		BX      lr
	ENDP

stop 	B 		stop     		; dead loop & program hangs here


	AREA myData, DATA, READWRITE
	ALIGN

	END