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
	EXPORT	__main				; make __main visible to linker
	ENTRY			
				
__main	PROC
		
		BL System_Clock_Init    ; set up system clock first
		BL UART2_Init           ; then init UART2 before any USART2_Write calls
		
		LDR r0, =RCC_BASE			;B Clock
		LDR r1, [r0, #RCC_AHB2ENR]
		BIC r1, r1, #0x00000002
		ORR r1, r1, #0x00000002
		STR r1, [r0, #RCC_AHB2ENR]		
		
		LDR r0, =GPIOB_BASE			;B MODER
		LDR r1, [r0, #GPIO_MODER]
		MOV r2, #0x0000FFFF
		BIC r1, r1, r2
		MOV r2, #0x00005555			;pins 0->7 Output (01)
		ORR r1, r1, r2
		STR r1, [r0, #GPIO_MODER]
		
open_gate
		PUSH {lr}
		MOV r7, #207 ; ~145 degrees
		LDR r0, =openPrompt
		MOV r1, #17
		BL USART2_Write ; diplay opening prompt
		LSL r0, #4
		MOV r1, #7
openLoop1 ; increment position
		CMP r6, r7
		BGE exitOpen ; exit conditions
		MOV r0, #1
		ADD r6, r6, r0 ; increment current position
		LDR r0, =myArray ; array base
		MOV r2, #0 ; index comparator
openLoop2
		CMP r2, r1 ; cmp i and size
		BGT openLoop1
		LDR r3, [r0, r2, LSL #2] ; r3 = array [i]
		PUSH {r0, r1, r2} ;UPDATE ODR
		MOV r0, #20000
		BL delay
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		AND r3, r3, #0xF0 ;mask to eliminate any high bits
		BIC r1, r1, #0xF0 ;mask relevant pins
		ORR r1, r1, r3
		STR r1, [r0, #GPIO_ODR]
		POP {r0, r1, r2} ;CONTINUE
		ADD r2, r2, #1
		B openLoop2
exitOpen
		MOV r0, #0x1000 ; set R8, b12 on (1)
		ORR r8, r8, r0
		BL update_LED_states
		LDR r0, =complete
		MOV r1, #8
		BL USART2_Write
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		BIC r1, r1, #0xF0
		STR r1, [r0, #GPIO_ODR]
		POP {lr}
		BX lr
close_gate
		PUSH {lr}
		MOV r7, #0 ; ~0 degrees
		LDR r0, =closePrompt
		;ADD r0, r0, #4
		MOV r1, #17
		BL USART2_Write ; diplay opening prompt
		MOV r1, #0
closeLoop1 ; increment position
		CMP r6, r7
		BLE exitClose ; exit conditions
		MOV r0, #1
		SUB r6, r6, r0 ; decrement current position
		LDR r0, =myArray ; array base
		MOV r2, #7 ; index comparator
closeLoop2
		CMP r2, r1 ; cmp i and 0
		BLT closeLoop1
		LDR r3, [r0, r2, LSL #2] ; r3 = array [i]
		PUSH {r0, r1, r2} ;UPDATE ODR
		MOV r0, #20000
		BL delay
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		AND r3, r3, #0xF0 ;mask to eliminate any high bits
		BIC r1, r1, #0xF0 ;mask relevant pins
		ORR r1, r1, r3
		STR r1, [r0, #GPIO_ODR]
		POP {r0, r1, r2} ;CONTINUE
		SUB r2, r2, #1
		B closeLoop2
exitClose
		MOV r0, #0x1000 ; reset R8, b12 off (0)
		BIC r8, r8, r0
		BL update_LED_states
		LDR r0, =complete
		MOV r1, #8
		BL USART2_Write
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		BIC r1, r1, #0xF0
		STR r1, [r0, #GPIO_ODR]
		POP {lr}
		BX lr
move_platform
		PUSH {lr, r6}
		MOV r0, #0x800 ; r8, b11 status 0 (moving)
		BIC r8, r8, r0
		BL update_LED_states
		LDR r0, =platformPrompt
		MOV r1, #20
		BL USART2_Write
		CMP r4, r5
		BEQ exitMovePlatform
		BLT moveUp
		BGT moveDown
moveDown
		SUB r0, r4, r5
		CMP r0, #256
		MOVEQ r6, #20 ; store delay step size
		CMP r0, #512
		MOVEQ r6, #10
		MOVNE r6, #5
		MOV r1, #2
		UDIV r2, r0, r1
		SUB r10, r4, r2 ;store midpoint
		MOV r11, #45000 ;store initial delay
		MOV r1, #0
downLoop1
		CMP r4, r5
		BLE exitMovePlatform
		MOV r0, #1
		SUB r4, r4, r0 ; decrement current position
		LDR r0, =myArray ; array base
		MOV r2, #7 ; index comparator
downLoop2
		CMP r2, r1
		BLT downLoop1
		LDR r3, [r0, r2, LSL #2] ; r3 = array[i]
		PUSH {r0, r1, r2} ;UPDATE ODR check acceleration
		CMP r4, r10
		SUBGE r11, r11, r6 ; increment/decrement by 20, at peak, delay ~ 20000
		ADDLT r11, r11, r6
		MOV r0, r11
		BL delay
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		AND r3, r3, #0xF ;mask to eliminate any high bits
		BIC r1, r1, #0xF ;mask relevant pins
		ORR r1, r1, r3
		STR r1, [r0, #GPIO_ODR]
		POP {r0, r1, r2} ;CONTINUE
		SUB r2, r2, #1
		B downLoop2
moveUp
		SUB r0, r5, r4
		CMP r0, #256
		MOVEQ r6, #20 ; store delay step size
		CMP r0, #512
		MOVEQ r6, #10
		MOVNE r6, #5
		MOV r1, #2
		UDIV r2, r0, r1
		ADD r10, r4, r2 ;store midpoint
		MOV r11, #50000 ;store initial delay
		MOV r1, #7
upLoop1
		CMP r4, r5
		BGE exitMovePlatform
		MOV r0, #1
		ADD r4, r4, r0 ; decrement current position
		LDR r0, =myArray ; array base
		MOV r2, #0 ; index comparator
upLoop2
		CMP r2, r1
		BGT upLoop1
		LDR r3, [r0, r2, LSL #2] ; r3 = array[i]
		PUSH {r0, r1, r2} ;UPDATE ODR check acceleration
		CMP r4, r10
		SUBLE r11, r11, r6 ; increment/decrement by 20, at peak, delay ~ 20000
		ADDGT r11, r11, r6
		MOV r0, r11
		BL delay
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		AND r3, r3, #0xF ;mask to eliminate any high bits
		BIC r1, r1, #0xF ;mask relevant pins
		ORR r1, r1, r3
		STR r1, [r0, #GPIO_ODR]
		POP {r0, r1, r2} ;CONTINUE
		ADD r2, r2, #1
		B upLoop2
exitMovePlatform
		MOV r0, #0x800 ; r8, b11 status 1 (stopped)
		ORR r8, r8, r0
		BL update_LED_states
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		BIC r1, r1, #0xF
		STR r1, [r0, #GPIO_ODR]
		LDR r0, =complete
		MOV r1, #8
		BL USART2_Write
		POP {lr, r6}
		BX lr
			
delay 	; param r0 = delay integer (6000)
		CMP r0, #0
		BXEQ lr
		SUB r0, r0, #1
		B delay		
exit
		
		
		
	ENDP		
		
	
	ALIGN			

	AREA myData, DATA, READWRITE
	ALIGN
openPrompt DCB 0x0D, 0x0A,"Opening gate..." ,0
closePrompt DCB 0x0D, 0x0A,"Closing gate...",0
platformPrompt DCB 0x0D, 0x0A,"Moving platform...",0
complete DCB "COMPLETE",0
myArray DCD 0x88, 0xAA, 0x22, 0x66, 0x44, 0x55, 0x11, 0x99
	END
