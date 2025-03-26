ORG 0000H

MOV P1, #0FFH  ; Set P1 as input (default)
LCALL GET_KEY
MOV B,A
ORG 3000H
	
KEYPRESS: 
	MOV A, P1
	
GET_KEY:
    MOV P1, #0FEH  ; Row 1 low, others high
    MOV A, P1
    JB ACC.4, CC1_1
    MOV A, #01H  ; Key '1'
    RET
    CC1_1:JB ACC.5, CC1_2
    MOV A, #02H  ; Key '2'
    RET
    CC1_2:JB ACC.6, CC1_3
    MOV A, #03H  ; Key '3'
    RET
    CC1_3:JB ACC.7, CHECK_ROW2
    MOV A, #'A'
    RET

CHECK_ROW2:
    MOV P1, #0FDH  ; Row 2 low, others high
    MOV A, P1
    JB ACC.4, CC2_1
    MOV A, #04H  ; Key '4'
    RET
    CC2_1:JB ACC.5, CC2_2
    MOV A, #05H  ; Key '5'
    RET
    CC2_2:JB ACC.6, CC2_3
    MOV A, #06H  ; Key '6'
    RET
    CC2_3:JB ACC.7, CHECK_ROW3
    MOV A, #'B'
    RET

CHECK_ROW3:
    MOV P1, #0FBH  ; Row 3 low, others high
    MOV A, P1
    JB ACC.4, CC3_1
    MOV A, #07H  ; Key '7'
    RET
CC3_1:JB ACC.5, CC3_2
    MOV A, #08H  ; Key '8'
    RET
CC3_2:JB ACC.6, CC3_3
    MOV A, #09H  ; Key '9'
    RET
CC3_3:JB ACC.7, CHECK_ROW4
    MOV A, #'C'
    RET

CHECK_ROW4:
    MOV P1, #0F7H  ; Row 4 low, others high
    MOV A, P1
    JB ACC.4, CC4_1; No key pressed, restart scan
    MOV A, #'*'
    RET
    CC4_1:JB ACC.5, CC4_2
    MOV A, #00H  ; Key '0'
    RET
    CC4_2:JB ACC.6, CC4_3
    MOV A, #'#'
    RET
    CC4_3:JB ACC.7, GET_KEY
    MOV A, #'D'
    RET

END
