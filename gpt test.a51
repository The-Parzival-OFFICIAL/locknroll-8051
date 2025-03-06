ORG 0000H
; -----------------------------------------
; Registers Usage:
; R0, R1 -> Left half (L) of plaintext (user password)
; R2, R3 -> Right half (R) of plaintext (user password)
; R4, R5 -> Round Key (Ki)
; R6     -> Round Counter
; R7     -> Temporary storage
; R8, R9 -> Left half (L) of stored password
; R10, R11 -> Right half (R) of stored password
; R12    -> Attempt Counter
; -----------------------------------------

START:
    MOV R12, #05H            ; Set maximum attempts (5)
    CALL LOAD_STORED_PASSWORD ; Load stored encrypted password from EEPROM

ENTER_PASSWORD:
    CALL CHECK_RESET_SEQUENCE ; Check if user wants to reset password
    CALL READ_PASSWORD        ; Get user input from keypad
    CALL ENCRYPT_PASSWORD     ; Encrypt entered password
    CALL VERIFY_PASSWORD      ; Compare encrypted input with stored password
    JZ ACCESS_GRANTED         ; If match, unlock door

    DJNZ R12, ENTER_PASSWORD  ; If wrong, retry (max 5 times)
    CALL LOCKDOWN             ; Lock system after 5 failed attempts
    SJMP $

ACCESS_GRANTED:
    CALL UNLOCK_DOOR          ; Open the door
    SJMP $

; -----------------------------------------
; Reads 4-digit password from keypad
; -----------------------------------------
READ_PASSWORD:
    ; Placeholder: Read from keypad
    MOV R0, #12H   ; Example input 0x1234
    MOV R1, #34H
    MOV R2, #56H   ; Example input 0x5678
    MOV R3, #78H
    RET

; -----------------------------------------
; Encrypts the entered password using SPECK 32/64
; -----------------------------------------
ENCRYPT_PASSWORD:
    MOV DPTR , #KEY          ; Load encryption key
    CALL KEY_EXPANSION       ; Expand key before encryption
    CALL ENCRYPTION          ; Encrypt user input
    RET

; -----------------------------------------
; Compares encrypted input with stored encrypted password
; -----------------------------------------
VERIFY_PASSWORD:
    MOV A, R0
    CJNE A, R8, NOT_MATCH
    MOV A, R1
    CJNE A, R9, NOT_MATCH
    MOV A, R2
    CJNE A, R10, NOT_MATCH
    MOV A, R3
    CJNE A, R11, NOT_MATCH
    CLR A                     ; Set Zero flag (match found)
    RET

NOT_MATCH:
    SETB A                    ; Clear Zero flag (no match)
    RET

; -----------------------------------------
; Load stored encrypted password from EEPROM
; -----------------------------------------
LOAD_STORED_PASSWORD:
    MOV R8, 50H  ; Load stored encrypted password (Left half)
    MOV R9, 51H
    MOV R10, 52H ; Load stored encrypted password (Right half)
    MOV R11, 53H
    RET

; -----------------------------------------
; Lock the system after 5 failed attempts
; -----------------------------------------
LOCKDOWN:
    ; Display "LOCKED" on LCD
    MOV DPTR, #LOCK_MSG
    CALL DISPLAY_LCD
    SJMP $ ; Halt system

LOCK_MSG:
    DB "LOCKED", 00H

; -----------------------------------------
; Unlock door
; -----------------------------------------
UNLOCK_DOOR:
    ; Display "ACCESS GRANTED" on LCD
    MOV DPTR, #ACCESS_MSG
    CALL DISPLAY_LCD

    ; Open door (Motor Control)
    SETB P1.0  ; Motor ON (example)
    ACALL DELAY
    CLR P1.0   ; Motor OFF
    RET

ACCESS_MSG:
    DB "ACCESS GRANTED", 00H

; -----------------------------------------
; Check for password reset sequence (e.g., holding '*' for 3s)
; -----------------------------------------
CHECK_RESET_SEQUENCE:
    ; Placeholder: Detect special keypad sequence
    JB P3.2, RESET_PASSWORD   ; If '*' key is pressed for reset
    RET

; -----------------------------------------
; Reset password process
; -----------------------------------------
RESET_PASSWORD:
    MOV DPTR, #RESET_MSG
    CALL DISPLAY_LCD
    CALL READ_PASSWORD       ; Get new password from user
    CALL ENCRYPT_PASSWORD    ; Encrypt the new password
    CALL STORE_PASSWORD      ; Save encrypted password to EEPROM
    RET

RESET_MSG:
    DB "RESET PASSWORD", 00H

; -----------------------------------------
; Store encrypted password in EEPROM
; -----------------------------------------
STORE_PASSWORD:
    MOV 50H, R0  ; Store encrypted password (Left half)
    MOV 51H, R1
    MOV 52H, R2  ; Store encrypted password (Right half)
    MOV 53H, R3
    RET

; -----------------------------------------
; Encryption Process (SPECK 32/64)
; -----------------------------------------
ENCRYPTION:
    MOV R6, #22
ENC_LOOP:
    CALL LOAD_ROUND_KEY
    CALL ROUND_FUNCTION 
    DJNZ R6 , ENC_LOOP
    RET
	
ROUND_FUNCTION:
    MOV A, R3 
    SWAP A
    MOV R3,A
    
    MOV A,R2
    XRL A,R0
    MOV R2,A
    
    MOV A, R2
    ADD A, R0
    MOV R0, A
    
    MOV A , R0 
    RLC A
    RLC A
    RLC A 
    MOV R0, A 
    
    MOV A , R1
    RLC A 
    RLC A 
    RLC A
    MOV R1,A 
    RET 

LOAD_ROUND_KEY:
    MOV A,R4 
    XRL A, R2
    MOV R4, A
    
    MOV A,R5 
    XRL A, R3
    MOV R5, A
    RET

KEY_EXPANSION:
    MOV R4, #0DEH
    MOV R5, #0ADH
    RET

KEY:
    DB 0DEH, 0ADH, 0BEH, 0EFH, 0CAH, 0FEH , 0BAH , 0BEH
END
