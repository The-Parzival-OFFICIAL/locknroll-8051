ORG 0000H

; Registers Usage:
; R0, R1 -> Left half (L)
; R2, R3 -> Right half (R)
; R4, R5 -> Round Key (Ki)
; R6, R7 -> Temporary values


START: 
	MOV DPTR , #KEY
	MOV R0 , #00H
	MOV R1 , #00H
	MOV R2 , #00H 
	MOV R3 , #00H
;---------------------------------------------------------------------------------------------------
;	shit to be encoded 
;---------------------------------------------------------------------------------------------------
	MOV R0, #12H   ; L = 0x1234 (Left half of plaintext)
	MOV R1, #34H
	MOV R2, #56H   ; R = 0x5678 (Right half of plaintext)
	MOV R3, #78H
	
	CALL KEY_EXPANSION 
	CALL ENCRYPTION 
	SJMP $ 
;----------------------------------------------------------------------------------------------------
;-----------------------------
; SPECK 32/64 ENCRYPTION 
;-----------------------------

ENCRYPTION:
	MOV R6, #32 ; number of rounds for 32/64 is 22 
	ENC_LOOP:
		CALL LOAD_ROUND_KEY
		CALL ROUND_FUNCTION 
		DJNZ R6 , ENC_LOOP
		RET
;------------------------------
; SPECK ROUND FUNCTION
;------------------------------

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
	
	
;--------------------------
; LOAD ROUND KEY
;--------------------------

LOAD_ROUND_KEY:
	MOV A,R4 
	XRL A, R2
	MOV R4, A
	
	MOV A,R5 
	XRL A, R3
	MOV R5, A
	RET
; -------------------------
; Key Expansion
; -------------------------
KEY_EXPANSION:
    MOV R4, #0DEH            ; Example Key Part 1
    MOV R5, #0ADH            ; Example Key Part 2
    RET

; -------------------------
; Data Section
; -------------------------
KEY:
    DB 0DEH, 0ADH, 0BEH, 0EFH, 0CAH, 0FEH , 0BAH , 0BEH ; 64-bit key

END