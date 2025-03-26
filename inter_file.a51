;--------------------------------------------------
; INT0  P3.2 -- 0003H - USED TO RESET THE PASSWORD 

ORG 00H  
    SJMP MAIN  ; Jump to main program

; ==============================
; DATA STORAGE (INTERNAL RAM)
; ==============================
ORG 30H  
PASSWORD:  DB  04H, 03H, 02H, 01H  ; Stored encrypted password (4 bytes)
ROUND_KEY: DB  00H, 00H, 00H, 00H  ; Storage for round key

; ==============================
; MAIN PROGRAM
; ==============================
MAIN:
    MOV A, #12H     ; Example input byte 1
    MOV B, #34H     ; Example input byte 2
    MOV R0, #56H    ; Example input byte 3
    MOV R1, #78H    ; Example input byte 4
    
    ; CALL ENCRYPTION FUNCTION
    LCALL GENERATE_ROUND_KEY  ; Generate round key
    LCALL SPECK_ENCRYPT       ; Encrypt input

    ; CALL PASSWORD CHECK FUNCTION
    LCALL CHECK_PASSWORD      ; Compare with stored password

    SJMP $  ; Stay here forever

; ==============================
; SUBROUTINES
; ==============================

; **Generate Round Key**
GENERATE_ROUND_KEY:
    MOV DPTR, #ROUND_KEY
    MOV A, #0A3H
    MOVX @DPTR, A
    INC DPTR
    MOV A, #0B2H
    MOVX @DPTR, A
    RET

; **Speck Encryption (Basic XOR Dummy)**
SPECK_ENCRYPT:
    MOV A, 12H     ; Load input byte 1
    MOV B, 34H     ; Load input byte 2
    XRL A, B       ; Simple XOR encryption
    MOV R0, A      ; Store encrypted value
    RET

; **Check if Encrypted Input Matches Stored Password**
CHECK_PASSWORD:
    MOV DPTR, #PASSWORD
    MOVX A, @DPTR 
	MOV B, R0
    CJNE A, B, NOT_MATCH
    INC DPTR
    MOVX A, @DPTR
	MOV B,R1
    CJNE A, B, NOT_MATCH

    MOV A, #01H    ; MATCH FOUND
    RET
	

NOT_MATCH:
    MOV A, #00H    ; NO MATCH
    RET
END