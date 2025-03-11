
;//TODO: 
;  check if enable is shorted in the circuit else:
;   add enable line code in the belo code 






;-------------------------------------
; PORT CONNECTION MAP 
;-------------------------------------
; PORT 2 IS ASSIGNED TO MOTOR FOR NOW 
;  ----------------------------
; | PORT IN MC |   PIN  IN     | 
; | / OTR CNN  |    LM293D     |
; |------------|---------------|
; |PORT 2.0    |EN1/2 (PIN 1)  |
; |PORT 2.1    |IN1 (PIN 2)    |
; |PORT 2.2    |IN2 (PIN 7)    |
; |MTR TERM 1  |OUT1 (PIN 3)   |
; |MTR TERM 2  |OUT2 (PIN 6)   |
;  ----------------------------	
ORG 0000H
;------------------------------------------
;  defined constants 
;------------------------------------------
MOTOR_DELAY: DB 28;  multiple of 14 to add seconds delay ; 1 here is 0.0711 seconds
	SJMP START
ORG 0030H;
	; ROTATE THE MOTOR FOR SOME DELAY THAT SETS IT TO 
	; 90 DEGREE OR ANY OTHER ANGLE BY ADJUSTING TIME 
	OPEN_LOCK: 
		CLR P2.2
		SETB P2.1 ; PORT CONNECTED TO IN1 OF LM
		MOV DPTR , #MOTOR_DELAY
		ACALL DELAY
		RET
		
	CLOSE_LOCK:
		CLR P2.1
		SETB P2.2
		MOV DPTR, #MOTOR_DELAY
		ACALL DELAY
		RET
		
	DELAY: 
		CLR A
		MOVC A , @A+DPTR
		MOV R7, A
	LOOP_1:
		ACALL FU_DELAY
		DEC R7;
		CJNE R7,#00,LOOP_1;
		RET
		
	FU_DELAY:
		MOV TMOD , #00010000B
		MOV A,#00
		MOV TH1,A
		MOV A,#00
		MOV TL1,A
		SETB TR1
		STOP: JNB TF1, STOP
		CLR TR1
		CLR TF1
		RET
		
	START: 
		ACALL OPEN_LOCK;
		ACALL CLOSE_LOCK; 
		;SJMP START;
		END
		
		
