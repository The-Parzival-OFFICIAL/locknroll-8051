ORG 0000H 
    
    MOV P2, #0F0H   ; Clear Port 2 (LCD Control)
	MOV P1, #00H
    MOV P3, #0FFH   ; Clear Port 1 (LCD Data)
	SETB P3.2
	SJMP CMMD
	
	

; ------------------------
; Send LCD Commands
; ------------------------
ORG 0030H 

CMMD: 
	ACALL DELAY
    MOV DPTR, #MYCOM  
LOOP1: 
    CLR A  
    MOVC A, @A+DPTR  
    JZ NEXT   ; If null (0), stop 
    ACALL CMD  
    ;ACALL DELAY  
    INC DPTR  
    SJMP LOOP1  

; ------------------------
; Send LCD Data
; ------------------------
NEXT: 
    MOV DPTR, #MYDATA  
LOOP2: 
    CLR A  
    MOVC A, @A+DPTR  
    JZ NEXT2  ; If null (0), stop  
   ACALL DATAA  
    ;ACALL DELAY  
    INC DPTR  
    SJMP LOOP2
	
	NEXT2:
	MOV A, #01H 
	ACALL CMD 
	MOV A, #81H 
	ACALL CMD 

ENDLESS: 
	MOV P2,#0F0H
	ACALL KEY_UNPRESSED
	ACALL DATAA
    SJMP ENDLESS
		
		
KEY_UNPRESSED: 
		MOV A, P2 
		ANL A, #0F0H 
		CJNE A,#0F0H,KEY_UNPRESSED
		SJMP KEY_PRESSED
	MOV A , 'P'
	ACALL DATAA
	KEY_PRESSED:
		MOV A, P2
		ANL A, #0F0H
		ACALL DELAY
		CJNE A, #0F0H,KEY_CONFIRM
		SJMP KEY_PRESSED
	KEY_CONFIRM:
		ACALL DELAY
		MOV A, P2 
		ANL A, #0F0H 
		CJNE A, #0F0H,FIND_COL
		SJMP KEY_UNPRESSED
	FIND_COL:
		MOV P2, #11111110B 
		ACALL DELAY 
		MOV A, P2 
		ANL A ,#0F0H 
		CJNE A, #0F0H,COL_0
		
		MOV P2, #11111101B 
		ACALL DELAY 
		MOV A, P2 
		ANL A, #0F0H 
		CJNE A, #0F0H , COL_1
		
		MOV P2, #11111011B 
		ACALL DELAY 
		MOV A, P2 
		ANL A , #0F0H 
		CJNE A, #0F0H , COL_2
		
		MOV P2, #11110111B 
		ACALL DELAY 
		MOV A, P2 
		ANL A, #0F0H 
		CJNE A, #0F0H , COL_3 
		SJMP KEY_UNPRESSED
		
		COL_0:
		MOV DPTR , #COL0 
		SJMP FIND_ROW
		COL_1:
		MOV DPTR, #COL1 
		SJMP FIND_ROW
		COL_2: 
		MOV DPTR, #COL2 
		SJMP FIND_ROW 
		COL_3: 
		MOV DPTR, #COL3 
		SJMP FIND_ROW 
		
		FIND_ROW:
		RLC A
		JNC MATCH 
		INC DPTR 
		SJMP FIND_ROW
		
		MATCH: CLR A 
		MOVC A, @A+DPTR
		RET 
; ------------------------
; Infinite Loop
; ------------------------
 

; ------------------------
; LCD Data Function
; ------------------------
DATAA:  
    MOV P1, A 
    SETB P3.5  ; RS = 1 (Data mode)  
    CLR P3.6   ; RW = 0 (Write)  
    SETB P3.7  ; Enable pulse  
    ACALL DELAY  
    CLR P3.7  
    RET  

; ------------------------
; LCD Command Function
; ------------------------
CMD:  
    MOV P1, A
    CLR P3.5   ; RS = 0 (Command mode)  
    CLR P3.6   ; RW = 0 (Write)  
    SETB P3.7  ; Enable pulse  
    ACALL DELAY  
    CLR P3.7  
    RET  

; ------------------------
; Delay Subroutine
; ------------------------
DELAY:  
    MOV R1, #15 
REPEAT1: 
    MOV R2, #255  
REPEAT2: 
    MOV R3, #255  
REPEAT3: DJNZ R3, REPEAT3  
         DJNZ R2, REPEAT2  
         DJNZ R1, REPEAT1  
         RET  
		 
MYCOM:  DB 38H, 0CH, 02H, 06H, 80H, 01H, 0  ; LCD Commands
   MYDATA: DB "HELLO MY FRIEND", 0  ; String to display
   COL0: DB 'A', 'B', 'C', 'D'
    COL1: DB '3', '6', '9', '#'
	COL2: DB '2', '5', '8', '0'
	COL3: DB '1', '4', '7', '*'

END  
