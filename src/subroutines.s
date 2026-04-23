	INCLUDE core_cm4_constants.s
	INCLUDE stm32l476xx_constants.s
	IMPORT	System_Clock_Init
	IMPORT	UART2_Init
	IMPORT	USART2_Write
	IMPORT  keypad_scan
	IMPORT  move_platform
	IMPORT  increment_open_spots
	IMPORT  open_gate
	IMPORT  close_gate
	IMPORT  decrement_open_spots
	IMPORT  begin
		
	
	AREA    main, CODE, READONLY
	EXPORT exit_sequence
	EXPORT manual_sequence
	EXPORT automatic_sequence
	EXPORT priority_sequence
	
exit_sequence PROC

scan_1
; Prompt the user to input 1, 2, 3, or 4 (reserved level) from the keypad to move the platform to that level
	LDR r0, =userKeypadPrompt
	MOV r1, #47
	BL USART2_Write

; Scan for input 1, 2, 3, or 4 on the keypad, and store the selection in a register R0-R3 
	MOV r11, #0
	BL keypad_scan
	MOV r0, r11
	CMP r0, #049
	MOVEQ r1, #1
	MOVEQ r3, #512
	PUSHEQ {r3}
	BEQ first_exit_check
	CMP r0, #050
	MOVEQ r1, #2
	MOVEQ r3, #1024
	PUSHEQ {r3}
	BEQ second_exit_check
	CMP r0, #051
	MOVEQ r1, #3
	MOVEQ r3, #1536
	PUSHEQ {r3, r1}
	BEQ third_exit_check
	CMP r0, #052
	MOVEQ r1, #4
	MOVEQ r3, #2048
	PUSHEQ {r3}
	BEQ fourth_exit_check
	BNE scan_1
	

; Check whether the selected parking level is empty by referring to the parking spots tracking in R8 
	; First Level
first_exit_check
	MOV r2, r8
	AND r2, r2, #0x03000000
	CMP r2, #0x00000000
	LDREQ r0, =levelIsEmpty
	MOVEQ r1, #16
	BLEQ USART2_Write
	MOV r2, r8
	AND r2, r2, #0x03000000
	CMP r2, #0x00000000
	BEQ begin
	BNE continue_exit
	
	; Second Level
second_exit_check
	MOV r2, r8
	AND r2, r2, #0x0C000000
	CMP r2, #0x00000000
	LDREQ r0, =levelIsEmpty
	MOVEQ r1, #16
	BLEQ USART2_Write
	MOV r2, r8
	AND r2, r2, #0x0C000000
	CMP r2, #0x00000000
	BEQ begin
	BNE continue_exit
	
	; Third Level
third_exit_check
	MOV r2, r8
	AND r2, r2, #0x30000000
	CMP r2, #0x00000000
	LDREQ r0, =levelIsEmpty
	MOVEQ r1, #16
	BLEQ USART2_Write
	MOV r2, r8
	AND r2, r2, #0x30000000
	CMP r2, #0x00000000
	BEQ begin
	BNE continue_exit
	
	; Fourth (reserved) Level
fourth_exit_check
	MOV r2, r8
	AND r2, r2, #0xC0000000
	CMP r2, #0x00000000
	LDREQ r0, =levelIsEmpty
	MOVEQ r1, #16
	BLEQ USART2_Write
	MOV r2, r8
	AND r2, r2, #0xC0000000
	CMP r2, #0x00000000
	BEQ begin
	BNE continue_exit

; If the level is empty, display “level is empty” and branch back to the “begin” procedure in main.s

; Otherwise, continue 

continue_exit
	; Update R5 with the motor position of the selected level (4096, 8192, 12288, or 16384, in steps) by referring to register R0-R3 
	POP {r3}
	MOV r5, r3
	
	; Branch with link to move_platform 
	BL move_platform
	
	; Prompt the user to input “#” when the car has entered the platform, and keep checking whether they enter a “#” until the key has been pressed
	PUSH{r1}
	LDR r0, =carEntered
	MOV r1, #35
	BL USART2_Write
	POP{r1}
	
scan_2
	PUSH {r1}
	MOV r11, #0
	BL keypad_scan
	CMP r11, #035
	POP {r1}
	
	; Update R8 to indicate that a car is on the platform 
	MOVEQ r2, #0x1
	ORREQ r8, r8, r2
	BNE scan_2
	
	; Update R8 with the new number of cars at the selected level
	CMP r1, #1
	BEQ first_level_exit
	CMP r1, #2
	BEQ second_level_exit
	CMP r1, #3
	BEQ third_level_exit
	CMP r1, #4
	BEQ fourth_level_exit
	
first_level_exit
	MOV r2, r8
	AND r2, r2, #0x03000000
	
	CMP r2, #0x01000000
	BICEQ r8, r8, #0x01000000
	BEQ continue_exit_two
	CMP r2, #0x02000000
	BICEQ r8, r8, #0x03000000
	ORREQ r8, r8, #0x01000000
	BEQ continue_exit_two
	
second_level_exit
	MOV r2, r8
	AND r2, r2, #0x0C000000
	
	CMP r2, #0x04000000
	BICEQ r8, r8, #0x0C000000
	BEQ continue_exit_two
	CMP r2, #0x08000000
	BICEQ r8, r8, #0x0C000000
	ORREQ r8, r8, #0x04000000
	BEQ continue_exit_two
	
third_level_exit
	MOV r2, r8
	AND r2, r2, #0x30000000
	
	CMP r2, #0x10000000
	BICEQ r8, r8, #0x10000000
	BEQ continue_exit_two
	CMP r2, #0x20000000
	BICEQ r8, r8, #0x30000000
	ORREQ r8, r8, #0x10000000
	BEQ continue_exit_two
	
fourth_level_exit
	MOV r2, r8
	AND r2, r2, #0xC0000000
	
	CMP r2, #0x40000000
	BICEQ r8, r8, #0x40000000
	BEQ continue_exit_two
	CMP r2, #0x80000000
	BICEQ r8, r8, #0xC0000000
	ORREQ r8, r8, #0x40000000
	BEQ continue_exit_two
	
continue_exit_two	
	; Branch with link to increment_open_spots 
	BL increment_open_spots

	; Update R5 with the motor position of the ground level (0, in units of steps) 
	MOV r5, #0
	
	; Branch with link to move_platform 
	BL move_platform
	
	; Branch with link to open_gate
	BL open_gate

	; Prompt the user to input “#” when they have exited the platform, and keep checking whether they enter a “#” until the key has been pressed 
	PUSH{r1}
	LDR r0, =carExit
	MOV r1, #40
	BL USART2_Write
	POP{r1}
	
scan_3
	MOV r11, #0
	BL keypad_scan
	CMP r11, #035
	
	; Update R8 to indicate that a car is off the platform 
	MOVEQ r2, #0x1
	BICEQ r8, r8, r2
	BNE scan_3

	; Branch with link to close_gate 
	BL close_gate

	; Branch back to the “begin” procedure in main.s 
	B begin

	ENDP
	LTORG ; Ran into weird bug, was told to put this here :)
		
;;;;;;; MANUAL SEQUENCE ;;;;;;;

manual_sequence PROC
	; Prompt the user to input 1, 2, or 3 from the keypad to select the platform destination level 
	LDR r0, =userKeypadPrompt
	MOV r1, #47
	BL USART2_Write
	
	; Scan for input 1, 2, or 3 on the keypad, and store the selection in a register R0-R3

scan_4
	MOV r11, #0
	BL keypad_scan
	MOV r0, r11
	CMP r0, #049
	MOVEQ r1, #1
	MOVEQ r3, #512
	PUSHEQ {r1, r3}
	BEQ first_manual_check
	CMP r0, #050
	MOVEQ r1, #2
	MOVEQ r3, #1024
	PUSHEQ {r1, r3}
	BEQ second_manual_check
	CMP r0, #051
	MOVEQ r1, #3
	MOVEQ r3, #1536
	PUSHEQ {r1, r3}
	BEQ third_manual_check
	CMP r0, #052
	MOVEQ r1, #4
	MOVEQ r3, #2048
	PUSHEQ {r1, r3}
	BEQ fourth_manual_check
	BNE scan_4

	; Check whether the selected parking level is full by referring to the parking spots tracking in R8 
	; First Level
first_manual_check
	MOV r2, r8
	AND r2, r2, #0x03000000
	CMP r2, #0x02000000
	LDREQ r0, =levelIsFull
	MOVEQ r1, #15
	BLEQ USART2_Write
	MOV r2, r8
	AND r2, r2, #0x03000000
	CMP r2, #0x02000000
	BEQ begin
	BNE continue_manual
	
	; Second Level
second_manual_check
	MOV r2, r8
	AND r2, r2, #0x0C000000
	CMP r2, #0x08000000
	LDREQ r0, =levelIsFull
	MOVEQ r1, #15
	BLEQ USART2_Write
	MOV r2, r8
	AND r2, r2, #0x0C000000
	CMP r2, #0x08000000
	BEQ begin
	BNE continue_manual
	
	; Third Level
third_manual_check
	MOV r2, r8
	AND r2, r2, #0x30000000
	CMP r2, #0x20000000
	LDREQ r0, =levelIsFull
	MOVEQ r1, #15
	BLEQ USART2_Write
	MOV r2, r8
	AND r2, r2, #0x30000000
	CMP r2, #0x20000000
	BEQ begin
	BNE continue_manual
	
	; Fourth (reserved) Level
fourth_manual_check
	MOV r2, r8
	AND r2, r2, #0xC0000000
	CMP r2, #0x80000000
	LDREQ r0, =levelIsFull
	MOVEQ r1, #15
	BLEQ USART2_Write
	MOV r2, r8
	AND r2, r2, #0xC0000000
	CMP r2, #0x80000000
	BEQ begin
	BNE continue_manual

	; If the level is full, display “level is full” and branch back to the “begin” label in __main 

	; Otherwise, continue 
	
continue_manual
	; Update R5 with motor position of the ground level (0, in units of steps) 
	MOV r5, #0

	; Branch with link to move_platform 
	BL move_platform

	; Branch with link to open_gate
	BL open_gate

	; Prompt the user to input “#” when the car has entered the platform, and keep checking whether they enter a “#” until the key has been pressed
	LDR r0, =carEntered
	MOV r1, #35
	BL USART2_Write
	
scan_5
	MOV r11, #0
	BL keypad_scan
	CMP r11, #035
	
	; Update R8 to indicate that a car is on the platform 
	BNE scan_5

	; Branch with link to close_gate 
	BL close_gate
	; Update R5 with the motor position of the selected level [0, 512, 1024, 1536, or 2048] by referring to register R0-R3
	POP {r1,r3}
	push {r1}
	MOV r5, r3

	; Branch with link to move_platform 
	BL move_platform
	
	MOV r2, #0x1
	ORR r8, r8, r2

	; Prompt the user to input “#” when they have exited the platform, and keep checking whether they enter a “#” until the key has been pressed
	LDR r0, =carExit
	MOV r1, #41
	BL USART2_Write
	

scan_6
	MOV r11, #0
	BL keypad_scan
	CMP r11, #035

	; Update R8 to indicate that a car is off the platform 
	MOVEQ r2, #0x1
	BICEQ r8, r8, r2
	BNE scan_6

	; Update R8 with the new number of cars at the selected level
	POP {r1}
	CMP r1, #1
	BEQ first_level_manual
	CMP r1, #2
	BEQ second_level_manual
	CMP r1, #3
	BEQ third_level_manual
	CMP r1, #4
	BEQ fourth_level_manual
	
first_level_manual
	MOV r2, r8
	AND r2, r2, #0x03000000
	
	CMP r2, #0x00000000
	ORREQ r8, r8, #0x01000000
	BEQ continue_manual_two
	CMP r2, #0x01000000
	BICEQ r8, r8, #0x03000000
	ORREQ r8, r8, #0x02000000
	BEQ continue_manual_two
	
second_level_manual
	MOV r2, r8
	AND r2, r2, #0x0C000000
	
	CMP r2, #0x00000000
	ORREQ r8, r8, #0x04000000
	BEQ continue_manual_two
	CMP r2, #0x04000000
	BICEQ r8, r8, #0x0C000000
	ORREQ r8, r8, #0x08000000
	BEQ continue_manual_two
	
third_level_manual
	MOV r2, r8
	AND r2, r2, #0x30000000
	
	CMP r2, #0x00000000
	ORREQ r8, r8, #0x10000000
	BEQ continue_manual_two
	CMP r2, #0x10000000
	BICEQ r8, r8, #0x30000000
	ORREQ r8, r8, #0x20000000
	BEQ continue_manual_two
	
fourth_level_manual
	MOV r2, r8
	AND r2, r2, #0xC0000000
	
	CMP r2, #0x00000000
	ORREQ r8, r8, #0x40000000
	BEQ continue_manual_two
	CMP r2, #0x40000000
	BICEQ r8, r8, #0xC0000000
	ORREQ r8, r8, #0x80000000
	BEQ continue_manual_two
	
continue_manual_two
	; Branch with link to decrement_open_spots 
	BL decrement_open_spots

	; Branch back to the “begin” label in __main 
	B begin

	ENDP
		
automatic_sequence PROC

	; If R8 shows that the garage is full (levels 1-3 are full, reserved level may be open), display message to Tera Term that “the unreserved garage is full” and branch back to the “begin” label in __main 
	MOV r2, r8
	AND r2, r2, #0x3F000000
	
	CMP r2, #0x2A000000
	LDREQ r0, =unreservedIsFull
	MOVEQ r1, #27
	BLEQ USART2_Write
	BEQ begin

	; Otherwise, if the garage is not full: 

	; Check R8 to see whether level 1 is full à if level 1 is full, check whether level 2 is full à if level 2 is full, then level 3 must be open
	; First Level
	MOV r2, r8
	AND r2, r2, #0x03000000
	CMP r2, #0x02000000
	MOVNE r1, #1
	MOVNE r3, #512
	BNE gavin
	
	; Second Level
	MOV r2, r8
	AND r2, r2, #0x0C000000
	CMP r2, #0x08000000
	MOVNE r1, #2
	MOVNE r3, #1024
	BNE gavin
	
	; Third Level
	MOV r2, r8
	AND r2, r2, #0x30000000
	CMP r2, #0x20000000
	MOVNE r1, #3
	MOVNE r3, #1536
	BNE gavin
	BEQ begin

gavin
	PUSH {r1, r3}
	; Update R5 with motor position of the ground level (0, in units of steps)
	MOV r5, #0

	; Branch with link to move_platform 
	BL move_platform

	; Branch with link to open_gate 
	BL open_gate
	
	; Prompt the user to input “#” when the car has entered the platform, and keep checking whether they enter a “#” until the key has been pressed
	LDR r0, =carEntered
	MOV r1, #35
	BL USART2_Write
	
scan_7
	MOV r11, #0
	BL keypad_scan
	CMP r11, #035
	
	; Update R8 to indicate that a car is on the platform 
	MOVEQ r2, #0x1
	ORREQ r8, r8, r2
	BNE scan_7
	

	; Branch with link to close_gate 
	BL close_gate
	
	POP {r1, r3}
	PUSH {r1}
	; Update R5 with the motor position of the selected level (4096, 8192, 12288, or 16384, in steps) by referring to register R0-R3
	MOV r5, r3

	; Branch with link to move_platform 
	BL move_platform

	; Prompt the user to input “#” when they have exited the platform, and keep checking whether they enter a “#” until the key has been pressed 
	LDR r0, =carExit
	MOV r1, #41
	BL USART2_Write
	
scan_8
	MOV r11, #0
	BL keypad_scan
	CMP r11, #035
	
	; Update R8 to indicate that a car is off the platform 
	MOVEQ r2, #0x1
	BICEQ r8, r8, r2
	BNE scan_8
	
	POP {r1}
	CMP r1, #1
	BEQ first_level_automatic
	CMP r1, #2
	BEQ second_level_automatic
	CMP r1, #3
	BEQ third_level_automatic
	
first_level_automatic
	MOV r2, r8
	AND r2, r2, #0x03000000
	
	CMP r2, #0x00000000
	ORREQ r8, r8, #0x01000000
	BEQ continue_automatic
	CMP r2, #0x01000000
	BICEQ r8, r8, #0x03000000
	ORREQ r8, r8, #0x02000000
	BEQ continue_automatic
	
second_level_automatic
	MOV r2, r8
	AND r2, r2, #0x0C000000
	
	CMP r2, #0x00000000
	ORREQ r8, r8, #0x04000000
	BEQ continue_automatic
	CMP r2, #0x04000000
	BICEQ r8, r8, #0x0C000000
	ORREQ r8, r8, #0x08000000
	BEQ continue_automatic
	
third_level_automatic
	MOV r2, r8
	AND r2, r2, #0x30000000
	
	CMP r2, #0x00000000
	ORREQ r8, r8, #0x10000000
	BEQ continue_automatic
	CMP r2, #0x10000000
	BICEQ r8, r8, #0x30000000
	ORREQ r8, r8, #0x20000000
	BEQ continue_automatic
	
continue_automatic
	; Branch with link to decrement_open_spots 
	BL decrement_open_spots
	
	; Branch back to the “begin” label in __main 
	B begin
	
	ENDP

priority_sequence PROC
	; Prompt the user to input a code to access the reserved level (the code will be “6767”)
	LDR r0, =reservedCode
	MOV r1, #53
	BL USART2_Write
	
	MOV r2, #1
	; Scan for a “6” and a “7” in sequence twice
	MOV r11, #0
	PUSH {r2}
	BL keypad_scan
	POP {r2}
	CMP r11, #054
	MOVNE r2, #0
	MOV r11, #0
	PUSH {r2}
	BL keypad_scan
	POP {r2}
	CMP r11, #055
	MOVNE r2, #0
	MOV r11, #0
	PUSH {r2}
	BL keypad_scan
	POP {r2}
	CMP r11, #054
	MOVNE r2, #0
	MOV r11, #0
	PUSH {r2}
	BL keypad_scan
	POP {r2}
	CMP r11, #055
	MOVNE r2, #0

	; Use a register R0-R3 to store 1 or 0 depending on whether the user hasn’t/has input a wrong number
	; Reject a wrong input and display rejection to Tera Term, then branch back to the “begin” label in __main 
	CMP r2, #1
	BEQ correct
	BNE wrong
	
wrong
	LDR r0, =wrongCode
	MOV r1, #16
	BL USART2_Write
	B begin
	LTORG
	
correct
	LDR r0, =rightCode
	MOV r1, #15
	BL USART2_Write
	
	; Check whether R8 shows if the reserved level is full 
	MOV r2, r8
	AND r2, r2, #0xC0000000
	CMP r2, #0x80000000
	LDREQ r0, =reservedFull
	MOVEQ r1, #19
	BLEQ USART2_Write
	BEQ begin
	BNE continue_reserved

	; If the reserved level is full (has 2/2 spots filled), display “reserved level is full” message to Tera Term and branch back to the “begin” label in __main 

	; Otherwise, continue 
	
continue_reserved
	; Update R5 with the motor position of the ground level (0, in units of steps) 
	MOV r5, #0

	; Branch with link to move_platform 
	BL move_platform

	; Branch with link to open_gate 
	BL open_gate
	
	LDR r0, =carEntered
	MOV r1, #35
	BL USART2_Write

	; Prompt the user to input “#” when they have entered the platform, and keep checking whether they enter a “#” until the key has been pressed 
scan_9
	
	MOV r11, #0
	BL keypad_scan
	CMP r11, #035
	
	; Update R8 to indicate that a car is on the platform 
	MOVEQ r2, #0x1
	ORREQ r8, r8, r2
	BNE scan_9

	; Branch with link to close_gate 
	BL close_gate

	; Update R5 with the motor position of the reserved (4th) level (16384, in steps)
	MOV r5, #2048

	; Branch with link to move_platform 
	BL move_platform
	
	LDR r0, =carExit
	MOV r1, #41
	BL USART2_Write

	; Prompt the user to input “#” when they have exited the platform, and keep checking whether they enter a “#” until the key has been pressed
scan_10
	MOV r11, #0
	BL keypad_scan
	CMP r11, #035
	
	; Update R8 to indicate that a car is off the platform 
	MOVEQ r2, #0x1
	BICEQ r8, r8, r2
	BNE scan_10
	
	; Update R8 with the new number of cars at the reserved level
	MOV r2, r8
	AND r2, r2, #0xC0000000
	
	CMP r2, #0x00000000
	ORREQ r8, r8, #0x40000000
	CMP r2, #0x40000000
	BICEQ r8, r8, #0xC0000000
	ORREQ r8, r8, #0x80000000

	; Branch with link to decrement_open_spots 
	BL decrement_open_spots

	; Branch back to the “begin” label in __main 
	B begin

	ENDP
	LTORG
		
	ALIGN
	AREA myData, DATA, READWRITE
	ALIGN
carExit DCB "\r\nPlease press # when car is off platform", 0 ; 41
carEntered DCB "\r\nPlease press # when car is ready...", 0 ; 38
userKeypadPrompt DCB "\r\nPlease select either levels 1, 2, 3, or 4...", 0 ; 47
levelIsEmpty DCB "\r\nLevel is Empty", 0 ; 16
levelIsFull DCB "\r\nLevel is Full", 0 ; 15
unreservedIsFull DCB "\r\nUnreserved garage is Full", 0 ; 25
reservedCode DCB "\r\nPlease enter the code to use the reserved level...", 0 ; 53
wrongCode DCB "\r\nCode Incorrect", 0 ; 16
rightCode DCB "\r\nCode Accepted", 0 ; 15
reservedFull DCB "\r\nReserved is Full", 0 ; 19

	END
		