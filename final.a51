ORG 0000H  
    LJMP MAIN  ; Jump to main program
	; ====== VARIABLE DEFINITIONS ======
	WRONG_COUNT EQU 30H  ; Store wrong attempt count in RAM
ORG 0003H
	ACALL RESET_PASSWORD
	RETI
ORG 0030H
; ====== FUNCTION: INITIALIZE LCD ======
LCD_INIT:
    MOV P2, #00H  ; Set LCD control port to output
    MOV P0, #38H  ; 8-bit mode, 2 lines, 5x7 font
    ACALL LCD_CMD
    MOV P0, #0EH  ; Display ON, Cursor ON
    ACALL LCD_CMD
    MOV P0, #01H  ; Clear screen
    ACALL LCD_CMD
    RET

LCD_CMD:
    MOV P2, #00H  ; RS = 0, RW = 0 (Command mode)
    SETB P2.2     ; Enable ON
    CLR P2.2      ; Enable OFF
    ACALL DELAY
    RET

LCD_WRITE:
    MOV P2, #01H  ; RS = 1, RW = 0 (Data mode)
    SETB P2.2     ; Enable ON
    CLR P2.2      ; Enable OFF
    ACALL DELAY
    RET

; ====== FUNCTION: READ KEYPAD (4x4) ======
;---------------------------------------------------
; FUNCTION: GET_KEY
; DESC: Scans 4x4 keypad using P1, returns ASCII in A
;---------------------------------------------------
GET_KEY:
    MOV P1, #0F0H   ; Set Rows (P1.4 – P1.7) to 0, Columns (P1.0 – P1.3) as inputs (1)
KEYPAD_WAIT:
    MOV A, P1
    ANL A, #0F0H    ; Mask upper 4 bits (rows)
    CJNE A, #0F0H, FIND_ROW  ; If a row is LOW, a key is pressed
    SJMP KEYPAD_WAIT  ; Keep polling

FIND_ROW:
    ACALL DELAY  ; Debounce
    MOV A, P1
    ANL A, #0F0H
    CJNE A, #0F0H, FIND_ROW_2
    SJMP KEYPAD_WAIT  ; False trigger, wait again

FIND_ROW_2:
    MOV R0, #0  ; R0 stores row number

    MOV P1, #11101111B  ; Ground Row 0 (P1.4 = 0)
    MOV A, P1
    ANL A, #00001111B
    CJNE A, #00001111B, ROW_FOUND
    INC R0

    MOV P1, #11011111B  ; Ground Row 1 (P1.5 = 0)
    MOV A, P1
    ANL A, #00001111B
    CJNE A, #00001111B, ROW_FOUND
    INC R0

    MOV P1, #10111111B  ; Ground Row 2 (P1.6 = 0)
    MOV A, P1
    ANL A, #00001111B
    CJNE A, #00001111B, ROW_FOUND
    INC R0

    MOV P1, #01111111B  ; Ground Row 3 (P1.7 = 0)
    MOV A, P1
    ANL A, #00001111B
    CJNE A, #00001111B, ROW_FOUND
    SJMP KEYPAD_WAIT  ; If no valid key, restart

ROW_FOUND:
    MOV R1, A  ; Store Column Data
    ACALL FIND_COLUMN
    RET

FIND_COLUMN:
    MOV DPTR, #KEYPAD_LOOKUP
    MOV A, R0
    MOVC A, @A+DPTR  ; Get row index
    MOV DPTR, #KEYPAD_LOOKUP + 4
    MOVC A, @A+DPTR  ; Get final key
    RET


; ====== FUNCTION: PASSWORD INPUT ======
ENTER_PASSWORD:
    MOV R2, #04  ; 4-digit password length
INPUT_LOOP:
    ACALL GET_KEY
    MOV A, R1
    ACALL LCD_WRITE
    MOV @R0, A  ; Store entered PIN
    INC R0
    DJNZ R2, INPUT_LOOP
    RET

; ====== FUNCTION: PASSWORD ENCRYPTION (XOR) ======
ENCRYPT_PASSWORD:
    MOV R2, #04
    MOV R0, #30H  ; Location of entered PIN
XOR_LOOP:
    MOV A, @R0
    XRL A, #55H  ; XOR encryption with 0x55
    MOV @R0, A
    INC R0
    DJNZ R2, XOR_LOOP
    RET

; ====== FUNCTION: COMPARE PASSWORD ======
COMPARE_PASSWORD:
    MOV R2, #04
    MOV R0, #30H  ; Location of entered PIN
    MOV R1, #40H  ; Stored encrypted PIN
COMPARE_LOOP:
    MOV A, @R0
	MOV B , @R1
    CJNE A,B,INCORRECT_PASS
    INC R0
    INC R1
    DJNZ R2, COMPARE_LOOP
    SJMP CORRECT_PASS
INCORRECT_PASS:
    INC WRONG_COUNT
    MOV A, WRONG_COUNT
	
    CJNE A, #05, DISPLAY_DENIED
    ACALL LOCKDOWN_MODE
DISPLAY_DENIED:
    MOV P0, #'D'
    ACALL LCD_WRITE
    RET
CORRECT_PASS:
    CALL OPEN_DOOR
    MOV P0, #'G'
    ACALL LCD_WRITE
    RET

; ====== FUNCTION: MOTOR CONTROL ======
OPEN_DOOR:
    SETB P2.3
    CLR P2.4
    ACALL DELAY
    CLR P2.3
    CLR P2.4
    RET

CLOSE_DOOR:
    CLR P2.3
    SETB P2.4
    ACALL DELAY
    CLR P2.3
    CLR P2.4
    RET

; ====== FUNCTION: LOCKDOWN MODE ======
LOCKDOWN_MODE:
    SETB P2.5  ; Buzzer ON
    MOV R4, #10
LOCKDOWN_LOOP:
    ACALL DELAY
    DJNZ R4, LOCKDOWN_LOOP
    CLR P2.5  ; Buzzer OFF
    SJMP MAIN  ; Restart system

; ====== FUNCTION: RESET PASSWORD (INT0) ======
RESET_PASSWORD:
    MOV P0, #'N'
    ACALL LCD_WRITE
    ACALL ENTER_PASSWORD
    ACALL ENCRYPT_PASSWORD
    MOV R2, #04
    MOV R0, #30H
    MOV R1, #40H
RESET_LOOP:
    MOV A, @R0
    MOV @R1, A
    INC R0
    INC R1
    DJNZ R2, RESET_LOOP
	MOV WRONG_COUNT, #00H
    RET

; ====== DELAY FUNCTION ======
DELAY:
    MOV R3, #255
DELAY_LOOP:
    DJNZ R3, DELAY_LOOP
    RET

; ====== MAIN PROGRAM ======
MAIN:
	MOV WRONG_COUNT, #00H
    ACALL LCD_INIT
    ACALL ENTER_PASSWORD
    ACALL ENCRYPT_PASSWORD
    ACALL COMPARE_PASSWORD
    ACALL CLOSE_DOOR
    SJMP MAIN

;---------------------------------------------------
; Keypad Lookup Table (For 4x4 Keypad)
;---------------------------------------------------
ORG 300H
KEYPAD_LOOKUP:
    DB '0', '1', '2', '3'
    DB '4', '5', '6', '7'
    DB '8', '9', 'A', 'B'
    DB 'C', 'D', 'E', 'F'

END