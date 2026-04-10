  INCLUDE core_cm4_constants.s
	INCLUDE stm32l476xx_constants.s
	IMPORT	System_Clock_Init
	IMPORT	UART2_Init
	IMPORT	USART2_Write
	; -- Add IMPORT for any external procedures here --

	AREA    main, CODE, READONLY
	EXPORT	__main
	ENTRY

__main	PROC
	BL System_Clock_Init
	BL UART2_Init

	; -- Peripheral clock enables go here (RCC_AHB2ENR, etc.) --
	; -- GPIO config (MODER, OTYPER, PUPDR) goes here --

	; -- Call each module's init procedure --
	;; BL Module_A_Init
	;; BL Module_B_Init

	; -- Main loop --
main_loop
	;; BL Module_A_Run
	;; BL Module_B_Run
	B  main_loop

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

	END
