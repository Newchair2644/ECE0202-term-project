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
	IMPORT  hexDisplay_init
	IMPORT  display_level
	IMPORT  update_LED_states
		
	
	AREA    main, CODE, READONLY
	EXPORT	motorControl_init
	EXPORT	open_gate
	EXPORT  close_gate
	EXPORT	move_platform
				
motorControl_init	PROC
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
		BX lr
	ENDP
		
				
open_gate PROC
		PUSH {lr}
		MOV r7, #207 ; ~145 degrees
		LDR r0, =openPrompt
		MOV r1, #17
		BL USART2_Write ; diplay opening prompt
		;LSL r0, #4
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
		MOV r0, #0x800 ; set R8, b12 on (1)
		ORR r8, r8, r0
		;BL update_LED_states
		LDR r0, =complete
		MOV r1, #8
		BL USART2_Write
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		BIC r1, r1, #0xF0
		STR r1, [r0, #GPIO_ODR]
		BL update_LED_states
		POP {lr}
		BX lr
	ENDP
		
close_gate PROC
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
		MOV r0, #0x800 ; reset R8, b12 off (0)
		BIC r8, r8, r0
		;BL update_LED_states
		LDR r0, =complete
		MOV r1, #8
		BL USART2_Write
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		BIC r1, r1, #0xF0
		STR r1, [r0, #GPIO_ODR]
		BL update_LED_states
		POP {lr}
		BX lr
	ENDP
		
move_platform PROC
		PUSH {lr, r6, r11}
		MOV r0, #0x1000 ; r8, b11 status 0 (moving)
		BIC r8, r8, r0
		BL update_LED_states
		LDR r0, =platformPrompt
		MOV r1, #20
		BL USART2_Write
		CMP r4, r5
		BEQ.W exitMovePlatform
		BLT moveUp
		BGT moveDown
moveDown
		SUB r0, r4, r5
		CMP r0, #512
		MOVLE r6, #50; store delay step size
		BLE downInit
		CMP r0, #1024
		MOVLE r6, #25
		BLE downInit
		CMP r0, #1536
		MOVLE r6, #13
		BLE downInit
		MOVGT r6, #5
downInit
		MOV r1, #2
		UDIV r2, r0, r1
		SUB r10, r4, r2 ;store midpoint
		MOV r11, #60000 ;store initial delay
		MOV r1, #0
		LDR r0, =myArray ; resync coils before starting — drive one full cycle at fixed delay
        MOV r2, #0
downLoop1
		BL display_level
		MOV r0, #1
		SUB r4, r4, r0 ; decrement current position
		CMP r4, r5
		BLT exitMovePlatform
		LDR r0, =myArray ; array base
		MOV r2, #7 ; index comparator
downLoop2
		CMP r2, r1
		BLT downLoop1
		LDR r3, [r0, r2, LSL #2] ; r3 = array[i]
		PUSH {r0, r1, r2} ;UPDATE ODR check acceleration
		CMP r4, r10
		SUBGT r11, r11, r6 ; increment/decrement by 20, at peak, delay ~ 20000
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
		CMP r0, #512
		MOVLE r6, #50; store delay step size
		BLE upInit
		CMP r0, #1024
		MOVLE r6, #10
		BLE upInit
		CMP r0, #1536
		MOVLE r6, #13
		BLE upInit
		MOVGT r6, #5
upInit
		MOV r1, #2
		UDIV r2, r0, r1
		ADD r10, r4, r2 ;store midpoint
		MOV r11, #60000 ;store initial delay
		MOV r1, #7
		LDR r0, =myArray ; resync coils before starting — drive one full cycle at fixed delay
        MOV r2, #0
upLoop1
		BL display_level
		MOV r0, #1
		ADD r4, r4, r0 ; decrement current position
		CMP r4, r5
		BGT exitMovePlatform
		LDR r0, =myArray ; array base
		MOV r2, #0 ; index comparator
upLoop2
		;CMP r4, r5 ; possibly for interupt
		;BGT exitMovePlatform
		CMP r2, r1
		BGT upLoop1
		LDR r3, [r0, r2, LSL #2] ; r3 = array[i]
		PUSH {r0, r1, r2} ;UPDATE ODR check acceleration
		CMP r4, r10
		SUBLT r11, r11, r6 ; increment/decrement by 20, at peak, delay ~ 20000
		ADDGE r11, r11, r6
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
		MOV r0, #0x1000 ; r8, b11 status 1 (stopped)
		ORR r8, r8, r0
		LDR r0, =GPIOB_BASE
		LDR r1, [r0, #GPIO_ODR]
		BIC r1, r1, #0xF
		STR r1, [r0, #GPIO_ODR]
		LDR r0, =complete
		MOV r1, #8
		BL USART2_Write
		BL update_LED_states
		POP {lr, r6, r11}
		BX lr
	ENDP
		
	
delay PROC	; param r0 = delay integer (6000)
		CMP r0, #0
		BXEQ lr
		SUB r0, r0, #1
		B delay		
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