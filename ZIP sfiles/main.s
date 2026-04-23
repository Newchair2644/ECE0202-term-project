;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MUST FIX USART FOR THIS MAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INCLUDE core_cm4_constants.s
	INCLUDE stm32l476xx_constants.s

	; -- Add IMPORT for any external procedures here --
	IMPORT	System_Clock_Init
	IMPORT	UART2_Init
	IMPORT	USART2_Write
	IMPORT  statusLEDS_init
	IMPORT  hexDisplay_init
	IMPORT 	display_level
	IMPORT	update_LED_states
	IMPORT  increment_open_spots
	IMPORT  decrement_open_spots
	IMPORT  motorControl_init
	IMPORT  open_gate
	IMPORT	close_gate
	IMPORT	move_platform
	IMPORT  keypadScan_init
	IMPORT	keypad_scan
	IMPORT  initialize_open_spots
	;IMPORT	manual_sequence
	;IMPORT	automatic_sequence
	;IMPORT	priority_sequence
	;IMPORT	exit_sequence

	AREA    main, CODE, READONLY
	EXPORT	__main
	ENTRY

__main	PROC
	BL System_Clock_Init
	BL UART2_Init
	BL statusLEDS_init
	BL hexDisplay_init
	BL motorControl_init
	BL keypadScan_init
	
	
begin
	; Write a “1” (on) to the “system idle” bit in R8
	MOV r0, #0x00001100
	ORR r8, r8, r0
	BL update_LED_states
	MOV r6, #0
	MOV r7, #0
	MOV r4, #0
	MOV r5, #0
	BL initialize_open_spots
	BL open_gate
	BL close_gate
	MOV r5, #2048
	BL move_platform
	
rescan_start
	; Display “Press ‘#’ to Start” message on Tera Term
	LDR r0, =msg_HT_start_prompt   ; First argument
	MOV r1, #21    ; Second argument
	BL USART2_Write
	;LSL r0, #4

	; Scan for '#' input and rescan if not pressed
	AND r11, r11, #0x0
	BL keypad_scan
	CMP r11, #35
	BNE rescan_start

	; Write a “0” (off) to the “system idle” bit in R8
	MOV r0, #0xFFFFFEFF
	AND r8, r8, r0
	BL update_LED_states

rescan_enter_exit
	; Display “Press ‘0’ to exit a level or '1' to enter the garage.” message on Tera Term
	LDR r0, =msg_enter_exit_prompt   ; First argument
	MOV r1, #53    ; Second argument
	BL USART2_Write

	; Scan for '0' and '1' inputs and rescan if not pressed
	AND r11, r11, #0x0
	BL keypad_scan
	CMP r11, #48 ; Check for '0'
	BEQ exit_sequence
	CMP r11, #49 ; Check for '1'
	BEQ rescan_sequence_select_enter
	BNE rescan_enter_exit

rescan_sequence_select_enter
	; Display "Press '*' for manual operation override, '#' for automatic operation, or '9' for priority parking." message on Tera Term
	LDR r0, =msg_sequence_select   ; First argument
	MOV r1, #98    ; Second argument
	BL USART2_Write

	; Scan for '*', '#', and '9' inputs and rescan if not pressed
	AND r11, r11, #0x0
	BL keypad_scan
	CMP r11, #42
	BEQ manual_sequence
	CMP r11, #35
	BEQ automatic_sequence
	CMP r11, #57
	BEQ priority_sequence
	BNE rescan_sequence_select_enter

priority_sequence
automatic_sequence
manual_sequence
exit_sequence

	B begin


	ENDP
	
	AREA myData, DATA, READWRITE
	ALIGN
;; messages for Tera Term
msg_HT_start_prompt	DCB   "\r\nPress # to start...", 0
msg_enter_exit_prompt DCB	"\r\nPress 0 to exit a level or 1 to enter the garage...", 0
msg_sequence_select DCB	"\r\nPress * for manual operation override, # for automatic operation, or 9 for \r\npriority parking...", 0
	END

