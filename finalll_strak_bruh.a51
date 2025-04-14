DB '.', '.', '-', '.', ' ', '-', '-', '-', '-', ' ', '-', '-', '-', '-', 00H


; ----- Hardware Definitions -----
LCD_DATA_PORT EQU P1
KEYPAD_PORT EQU P2
MISC_PORT EQU P3
RESET_BUTTON EQU P3.2 ; INT0
BUZZER EQU P3.3
SERVO EQU P3.4
RS EQU P3.5
RW EQU P3.6
EN EQU P3.7




; ----- Memory Locations -----
PASSWORD_RAM EQU 30H
TYPED_PASSWORD_RAM EQU 40H
ENCRYPTED_PASSWORD_RAM EQU 50H
TRIES_COUNT EQU 60H
LOCKED_FLAG EQU 61H
KEY_PRESSED_VALUE EQU 62H
SERVO_ANGLE EQU 63H
PASSWORD_LENGTH EQU 04H

; ----- LCD Commands -----
LCD_CLEAR EQU 01H
LCD_HOME EQU 02H
LCD_8BIT_2LINE EQU 38H
LCD_DISPLAY_ON EQU 0CH
LCD_ENTRY_MODE EQU 06H
LCD_FIRST_LINE EQU 81H
LCD_SECOND_LINE EQU 0C1H

; ----- Interrupt Vector -----
ORG 0000H
	ACALL INIT_DEFAULT_PASSWORD
    SJMP START

ORG 0003H ; INT0 (P3.2)
    LJMP RESET_PASSWORD
	
; ----- Code Start -----
START:
	MOV LOCKED_FLAG , #00H
    ACALL INIT_PORTS
    ACALL INIT_LCD
 RESET_RET:
    MOV TRIES_COUNT, #05H
    CLR LOCKED_FLAG
    ACALL SERVO_CLOSE

MAIN_LOOP:
    MOV A, LOCKED_FLAG
    JNZ LOCKED_MODE

    ACALL DISPLAY_PASSWORD_PROMPT
    ACALL GET_PASSWORD
    ACALL ENCRYPT_PASSWORD
    ACALL CHECK_PASSWORD
    JNZ ACCESS_CHECK
    ACALL DISPLAY_ACCESS_GRANTED
	MOV TRIES_COUNT , #05H
    ACALL SERVO_OPEN
    LJMP MAIN_LOOP

ACCESS_CHECK:
    ACALL DISPLAY_ACCESS_DENIED
    ACALL SERVO_CLOSE
    DEC TRIES_COUNT
    MOV A, TRIES_COUNT
    JZ LOCKED_MODE
    ACALL DELAY_ACCESS_DENIED
    LJMP MAIN_LOOP

LOCKED_MODE:
    ACALL DISPLAY_LOCKED_OUT
    ACALL SERVO_CLOSE
    LOCKED_MODE_1:ACALL BUZZER_ON
    LJMP LOCKED_MODE_1

; ----- Initialization -----
INIT_PORTS:

    MOV LCD_DATA_PORT, #00H
    MOV MISC_PORT, #00000100B
    MOV KEYPAD_PORT, #0F0H
    CLR BUZZER
    CLR SERVO
    SETB IT0      ; falling edge trigger INT0
    SETB EX0      ; enable INT0
    SETB EA       ; global interrupt enable
    RET

INIT_LCD:
    MOV A, #LCD_8BIT_2LINE
    ACALL CMD
    MOV A, #LCD_DISPLAY_ON
    ACALL CMD
    MOV A, #LCD_CLEAR
    ACALL CMD
    MOV A,#LCD_HOME
    ACALL CMD
    MOV A, #LCD_ENTRY_MODE
    ACALL CMD
    RET

INIT_DEFAULT_PASSWORD:
    MOV DPTR, #DEFAULT_PASS
    MOV R0, #PASSWORD_RAM
    MOV R2, #PASSWORD_LENGTH
COPY_DEFAULT:
    CLR A
    MOVC A, @A+DPTR
    MOV @R0, A
    INC DPTR
    INC R0
    DJNZ R2, COPY_DEFAULT
    RET

DEFAULT_PASS: DB 0DEH XOR '1', 0DEH XOR '4', 0DEH XOR '6', 0DEH XOR '5'

; ----- LCD Subroutines -----
CMD:
    MOV LCD_DATA_PORT, A
    CLR RS
    CLR RW
    SETB EN
    ACALL DELAY_LCD
    CLR EN
    RET

DATAA:
    MOV LCD_DATA_PORT, A
    SETB RS
    CLR RW
    SETB EN
    ACALL DELAY_LCD
    CLR EN
    RET

LCD_STRING:
    CLR A
    MOVC A, @A+DPTR
    JZ LCD_STRING_END
    ACALL DATAA
    INC DPTR
    SJMP LCD_STRING
LCD_STRING_END:
    RET
 
DISPLAY_PASSWORD_PROMPT:
    MOV A, #LCD_CLEAR
    ACALL CMD
	MOV A, #LCD_FIRST_LINE
    MOV DPTR, #PASSWORD_PROMPT_MSG
    ACALL LCD_STRING
    MOV A, #LCD_SECOND_LINE
    ACALL CMD
    RET

DISPLAY_ACCESS_GRANTED:
    ACALL LCD_CLEARR
    MOV DPTR, #ACCESS_GRANTED_MSG
    ACALL LCD_STRING
    ACALL DELAY_ACCESS_DENIED
    ;ACALL LCD_CLEARR
    RET

DISPLAY_ACCESS_DENIED:
    ACALL LCD_CLEARR
    MOV DPTR, #ACCESS_DENIED_MSG
    ACALL LCD_STRING
    ACALL DELAY_ACCESS_DENIED
    ;ACALL LCD_CLEARR
    RET

DISPLAY_LOCKED_OUT:
    ACALL LCD_CLEARR
    MOV DPTR, #LOCKED_OUT_MSG
    ACALL LCD_STRING
    RET

LCD_CLEARR:
    MOV A, #LCD_CLEAR
    ACALL CMD
	MOV A, #LCD_HOME
	ACALL CMD
    RET

; ----- Keypad -----
GET_PASSWORD:
    MOV R0, #TYPED_PASSWORD_RAM
    MOV R2, #PASSWORD_LENGTH
GET_PASSWORD_LOOP:
    ACALL SCAN_KEYPAD
    MOV A, KEY_PRESSED_VALUE
    MOV @R0, A
    ACALL DATAA
    INC R0
    DJNZ R2, GET_PASSWORD_LOOP
    RET

SCAN_KEYPAD:
    MOV KEYPAD_PORT, #0F0H
    ACALL KEY_UNPRESSED
    ACALL GET_KEY_VALUE
    RET

KEY_UNPRESSED:
    MOV A, KEYPAD_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, KEY_UNPRESSED
    RET

GET_KEY_VALUE:
    MOV A, KEYPAD_PORT
    ANL A, #0F0H
    ACALL DELAY
    CJNE A, #0F0H, KEY_CONFIRM
    SJMP GET_KEY_VALUE

KEY_CONFIRM:
    ACALL DELAY
    MOV A, KEYPAD_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, FIND_COL
    SJMP GET_KEY_VALUE

FIND_COL:
    MOV KEYPAD_PORT, #11111110B
    ACALL DELAY
    MOV A, KEYPAD_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, COL_0

    MOV KEYPAD_PORT, #11111101B
    ACALL DELAY
    MOV A, KEYPAD_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, COL_1

    MOV KEYPAD_PORT, #11111011B
    ACALL DELAY
    MOV A, KEYPAD_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, COL_2

    MOV KEYPAD_PORT, #11110111B
    ACALL DELAY
    MOV A, KEYPAD_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, COL_3
    SJMP GET_KEY_VALUE

COL_0: MOV DPTR, #COL0
       SJMP FIND_ROW
COL_1: MOV DPTR, #COL1
       SJMP FIND_ROW
COL_2: MOV DPTR, #COL2
       SJMP FIND_ROW
COL_3: MOV DPTR, #COL3
       SJMP FIND_ROW

FIND_ROW:
    RLC A
    JNC MATCH
    INC DPTR
    SJMP FIND_ROW

MATCH:
    CLR A
    MOVC A, @A+DPTR
    MOV KEY_PRESSED_VALUE, A
    RET

; ----- Encryption -----
ENCRYPT_PASSWORD:
    MOV R0, #TYPED_PASSWORD_RAM
    MOV R1, #ENCRYPTED_PASSWORD_RAM
    MOV R2, #PASSWORD_LENGTH
ENCRYPT_LOOP:
    MOV A, @R0
    XRL A, #0DEH
    MOV @R1, A
    INC R0
    INC R1
    DJNZ R2, ENCRYPT_LOOP
    RET

; ----- Password Check -----
CHECK_PASSWORD:
    MOV R0, #ENCRYPTED_PASSWORD_RAM
    MOV R1, #PASSWORD_RAM
    MOV R2, #PASSWORD_LENGTH
CHECK_LOOP:
    MOV A, @R0
    MOV B, @R1
    CJNE A, B, CHECK_FAIL
    INC R0
    INC R1
    DJNZ R2, CHECK_LOOP
    CLR A
    RET
CHECK_FAIL:
    MOV A, #01H
    RET

; ----- Reset via INT0 -----
RESET_PASSWORD:
	; PUSHING THE STATE INTO THE STACK 	 
    PUSH ACC
    PUSH B
    PUSH DPL
    PUSH DPH
    PUSH PSW
    PUSH 00H
    PUSH 01H
    PUSH 02H
    PUSH 03H
    PUSH 04H
    PUSH 05H
    PUSH 06H
    PUSH 07H
	
	
    CLR BUZZER
	ACALL SERVO_CLOSE      
    ACALL INIT_LCD
	MOV A, #LCD_HOME
	ACALL CMD
    MOV DPTR, #RESET_PROMPT_MSG
    ACALL LCD_STRING
    MOV A, #LCD_SECOND_LINE
    ACALL CMD
    MOV R0, #TYPED_PASSWORD_RAM
    MOV R2, #PASSWORD_LENGTH
RESET_GET_PASSWORD_LOOP:
    ACALL SCAN_KEYPAD
    MOV A, KEY_PRESSED_VALUE
    MOV @R0, A
    ACALL DATAA
    INC R0
    DJNZ R2, RESET_GET_PASSWORD_LOOP
    ACALL ENCRYPT_PASSWORD
    MOV R0, #PASSWORD_RAM
    MOV R1, #ENCRYPTED_PASSWORD_RAM
    MOV R2, #PASSWORD_LENGTH
RESET_LOOP:
    MOV A, @R1
    MOV @R0, A
    INC R0
    INC R1
    DJNZ R2, RESET_LOOP
    MOV LOCKED_FLAG, #00H
    MOV TRIES_COUNT, #05H
	
	; POPS THE CURRENT STATE OF THE MACHINE
	POP 07H
    POP 06H
    POP 05H
    POP 04H
    POP 03H
    POP 02H
    POP 01H
    POP 00H
    POP PSW
    POP DPH
    POP DPL
    POP B
    POP ACC

    LJMP START

; ----- Delays -----
DELAY:
    MOV R6, #255
DELAY1:
    MOV R7, #255
DELAY2:
    DJNZ R7, DELAY2
    DJNZ R6, DELAY1
    RET

DELAY_ACCESS_DENIED:
    MOV R6, #255
    MOV R7, #255
DELAY_LOOP:
    DJNZ R7, DELAY_LOOP
    DJNZ R6, DELAY_LOOP
    RET
	
DELAY_LCD:
    MOV R7, #255
LCD_DELAY_LOOP:
    DJNZ R7, LCD_DELAY_LOOP
    RET

; ----- Buzzer -----
BUZZER_ON:
    SETB BUZZER
    ACALL DELAY_ACCESS_DENIED
    CLR BUZZER
    ACALL DELAY_ACCESS_DENIED
    RET

; ----- Servo -----

TIMER_DELAY:             ; 
    MOV TMOD, #01H       ; Timer0 in mode 1 (16-bit)
    SETB TR0             ; Start Timer0
WAIT:
    JNB TF0, WAIT        ; Wait until timer overflows
    CLR TR0              ; Stop Timer
    CLR TF0              ; Clear overflow flag
    RET

SERVO_OPEN:              ; 2 ms HIGH, 18 ms LOW
    SETB SERVO            ; Send HIGH pulse
    MOV TH0, #0F8H       ; Load 2 ms delay (high byte)
    MOV TL0, #30H        ; Load 2 ms delay (low byte)
    ACALL TIMER_DELAY

    CLR SERVO             ; Now LOW for 18 ms
    MOV TH0, #0B6H       ; Load 18 ms delay
    MOV TL0, #00H
    ACALL TIMER_DELAY
    RET

SERVO_CLOSE:             ; 1 ms HIGH, 19 ms LOW
    SETB SERVO            ; Send HIGH pulse
    MOV TH0, #0FCH       ; Load 1 ms delay
    MOV TL0, #18H
    ACALL TIMER_DELAY

    CLR SERVO             ; Now LOW for 19 ms
    MOV TH0, #0BEH       ; Load 19 ms delay
    MOV TL0, #00H
    ACALL TIMER_DELAY
    RET
	
	
	
; ----- Keypad Tables -----
COL0: DB 'A','B','C','D'
COL1: DB '3','6','9','#'
COL2: DB '2','5','8','0'
COL3: DB '1','4','7','*'

; ----- LCD Messages -----
PASSWORD_PROMPT_MSG: DB "Password:", 0
ACCESS_GRANTED_MSG: DB "Access Granted!", 0
ACCESS_DENIED_MSG:  DB "Access Denied!", 0
LOCKED_OUT_MSG:     DB "Locked Out!", 0
RESET_PROMPT_MSG:   DB "Reset Password:", 0
ORG 0F00H  ; arbitrary unused memory section

EasterEgg:
    DB "R3JlZyB3YXMgaGVyZQ==", 00H
END
