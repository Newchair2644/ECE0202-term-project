  INCLUDE core_cm4_constants.s
	INCLUDE stm32l476xx_constants.s

	; -- Add IMPORT for any external procedures here --
	IMPORT	System_Clock_Init
	IMPORT	UART2_Init
	IMPORT	USART2_Write
	IMPORT	update_LED_states
	IMPORT	manual_sequence
	IMPORT	automatic_sequence
	IMPORT	priority_sequence
	IMPORT	exit_sequence

	AREA    main, CODE, READONLY
	EXPORT	__main
	EXPORT	keypad_scan
	ENTRY

__main	PROC
	BL System_Clock_Init
	BL UART2_Init

	; -- Peripheral clock enables go here (RCC_AHB2ENR, etc.) --
	;; Enable the clock of GPIO Ports A-D
	LDR r0, =RCC_BASE
	LDR r1, [r0, #RCC_AHB2ENR]
	ORR r1, r1, #0x0000000F
	STR r1, [r0, #RCC_AHB2ENR]

	; -- GPIO config (MODER, OTYPER, PUPDR) goes here --
	;;;;;;; Configure the Keypad Rows ;;;;;;;
	;; Configure B pins as outputs
	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_MODER]
	LDR r2, =0x0000FF00
	BIC r1, r1, r2 ; Clear MODERs 4, 5, 6, 7
	LDR r2, =0x00005500
	ORR r1, r1, r2 ; Set MODERs 4, 5, 6, 7 to output
	STR r1, [r0, #GPIO_MODER]
	;; Select output type
	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_OTYPER]
	BIC r1, r1, #0x00F0 ; Set bits 4, 5, 6, 7 to push-pull
	STR r1, [r0, #GPIO_OTYPER]

	;;;;;;; Configure the Keypad Columns ;;;;;;;
	;; Configure C pins as inputs
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #0x0000003F ; Clear MODERs 0, 1, 2 (sets it to input)
	STR r1, [r0, #GPIO_MODER]
	;; Configure C to no pull-up, no pull-down
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	BIC r1, r1, #0x0000003F
	ORR r1, r1, #0x00000015
	STR r1, [r0, #GPIO_PUPDR]

	; -- Call each module's init procedure (initialize each module's GPIOs) --
	;; BL Module_A_Init
	;; BL Module_B_Init

	; -- Main loop --
begin
	; Write a “1” (on) to the “system idle” bit in R8
	MOV r0, 0x00000100
	ORR r8, r8, r0
	BL update_LED_states

rescan_start
	; Display “Press ‘#’ to Start” message on Tera Term
	LDR r0, =msg_HT_start_prompt   ; First argument
	MOV r1, #11    ; Second argument
	BL USART2_Write

	; Scan for '#' input and rescan if not pressed
	BIC r11, r11, 0xFFFFFFFF
	keypad_scan
	CMP r11, #53
	BNE rescan_start

	; Write a “0” (off) to the “system idle” bit in R8
	MOV r0, 0xFFFFFEFF
	AND r8, r8, r0
	BL update_LED_states

rescan_enter_exit
	; Display “Press ‘0’ to exit a level or '1' to enter the garage.” message on Tera Term
	LDR r0, =msg_enter_exit_prompt   ; First argument
	MOV r1, #11    ; Second argument
	BL USART2_Write

	; Scan for '0' and '1' inputs and rescan if not pressed
	BIC r11, r11, 0xFFFFFFFF
	keypad_scan
	CMP r11, #48 ; Check for '0'
	BEQ exit_sequence
	CMP r11, #49 ; Check for '1'
	BEQ rescan_sequence_select_enter
	BNE rescan_enter_exit

rescan_sequence_select_enter
	; Display "Press '*' for manual operation override, '#' for automatic operation, or '9' for priority parking." message on Tera Term
	LDR r0, =msg_sequence_select   ; First argument
	MOV r1, #11    ; Second argument
	BL USART2_Write

	; Scan for '*', '#', and '9' inputs and rescan if not pressed
	BIC r11, r11, 0xFFFFFFFF
	keypad_scan
	CMP r11, #42
	BEQ manual_sequence
	CMP r11, #35
	BEQ automatic_sequence
	CMP r11, #57
	BEQ priority_sequence
	BNE rescan_sequence_select_enter

	B begin

	ENDP


keypad_scan PROC
	; Create GPIOs for reference
display_key
	LDR r3, =GPIOA_BASE
	LDR r0, [r3, #GPIO_ODR]
	BIC r0, r0, #0x00F0
	ORR r0, r0, #0x00F0
	STR r0, [r3, #GPIO_ODR]

	; Search for the column == 0 while row 0 == 0
scan_row0
	LDR r0, [r3, #GPIO_ODR]
	BIC r0, r0, #0x00F0
	ORR r0, r0, #0x00E0
	STR r0, [r3, #GPIO_ODR]
	BL delay

	LDR r2, =GPIOC_BASE
	LDR r0, [r2, #GPIO_IDR]
	TST r0, #0x0004
	BEQ key3
	TST r0, #0x0002
	BEQ key2
	TST r0, #0x0001
	BEQ key1

	; Search for the column == 0 while row 1 == 0
scan_row1
	LDR r3, =GPIOA_BASE
	LDR r0, [r3, #GPIO_ODR]
	BIC r0, r0, #0x00F0
	ORR r0, r0, #0x00D0
	STR r0, [r3, #GPIO_ODR]
	BL delay

	LDR r2, =GPIOC_BASE
	LDR r0, [r2, #GPIO_IDR]
	TST r0, #0x0004
	BEQ key6
	TST r0, #0x0002
	BEQ key5
	TST r0, #0x0001
	BEQ key4

	; Search for the column == 0 while row 2 == 0
scan_row2
	LDR r3, =GPIOA_BASE
	LDR r0, [r3, #GPIO_ODR]
	BIC r0, r0, #0x00F0
	ORR r0, r0, #0x00B0
	STR r0, [r3, #GPIO_ODR]
	BL delay

	LDR r2, =GPIOC_BASE
	LDR r0, [r2, #GPIO_IDR]
	TST r0, #0x0004
	BEQ key9
	TST r0, #0x0002
	BEQ key8
	TST r0, #0x0001
	BEQ key7

	; Search for the column == 0 while row 3 == 0
scan_row3
	LDR r3, =GPIOA_BASE
	LDR r0, [r3, #GPIO_ODR]
	BIC r0, r0, #0x00F0
	ORR r0, r0, #0x0070
	STR r0, [r3, #GPIO_ODR]
	BL delay

	LDR r2, =GPIOC_BASE
	LDR r0, [r2, #GPIO_IDR]
	TST r0, #0x0080
	BEQ keyHT
	TST r0, #0x0040
	BEQ key0
	TST r0, #0x0020
	BEQ keyAST

	; If no column == 0 is found, loop back to display_key label
	B display_key


	; Map each ASCII value to its corresponding key
key1
	LDR r0, =char1
	B write
key2
	LDR r0, =char2
	B write
key3
	LDR r0, =char3
	B write
key4
	LDR r0, =char4
	B write
key5
	LDR r0, =char5
	B write
key6
	LDR r0, =char6
	B write
key7
	LDR r0, =char7
	B write
key8
	LDR r0, =char8
	B write
key9
	LDR r0, =char9
	B write
keyAST
	LDR r0, =charAST
	B write
key0
	LDR r0, =char0
	B write
keyHT
	LDR r0, =charHT
	B write
	
	
	; Write values to tera term via USART2_write
write
	SUB SP, SP, #8	; Utilize the stack pointer
					; to allocate a byte for the 
					; address of r0, which we store in r2
					; (this solves a problem we had where
					; the keys got mapped to off-by-one
					; values because pushing and popping
					; works with 4 bytes and not 1 byte)
	LDR r2, [r0]
	STRB r2, [SP]
	MOV r0, SP	; Grab address we put into the stack
	LDR r11, [r0]	; r11 stores the latest key press
	
	MOV r1, #1
	BL USART2_Write
	ADD SP, SP, #8	; Take the address back out of the stack

	BL delay

	; Wait for the key to be released before displaying another value
button_release
	LDR r3, =GPIOA_BASE
	LDR r0, [r3, #GPIO_ODR]
	BIC r0, r0, #0x00F0
	STR r0, [r3, #GPIO_ODR]

	BL delay

	LDR r2, =GPIOC_BASE
	LDR r0, [r2, #GPIO_IDR]

	TST r0, #0x0001
	BEQ button_release
	TST r0, #0x0002
	BEQ button_release
	TST r0, #0x0004
	BEQ button_release

	ENDP

;;;;;;;;;;;;;;;;;;;; SHARED HELPER FUNCTIONS ;;;;;;;;;;;;;;;;;;;;
;; delay TODO use timer instead
delay	PROC
	PUSH {r12}
	LDR  r12, =0x9999
delay_loop
	SUBS r12, r12, #1
	BNE  delay_loop
	POP  {r12}
	BX   LR
	ENDP

;;;;;;;;;;;;;;;;;;;; DATA SECTION ;;;;;;;;;;;;;;;;;;;;
	ALIGN
	AREA myData, DATA, READWRITE
	ALIGN
	; -- Shared data/constants go here if needed --

;; ascii values from lab 6
char0   DCD 48
char1   DCD 49
char2   DCD 50
char3   DCD 51
char4   DCD 52
char5   DCD 53
char6   DCD 54
char7   DCD 55
char8   DCD 56
char9   DCD 57
charAST DCD 42
charHT  DCD 35

;; messages for Tera Term
msg_HT_start_prompt	DCB   "\nPress '#' to start.\r\n", 0
msg_enter_exit_prompt DCB	"\nPress ‘0’ to exit a level or '1' to enter the garage.\r\n"
msg_sequence_select DBC	"\nPress '*' for manual operation override, '#' for automatic operation, or '9' for priority parking.\r\n"

	END
