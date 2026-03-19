; CPU DETECTION: 8080 VS Z80
;
; The 8080 flags register has bits 3 and 5
; hardwired to 0. The Z80 uses all 8 bits.
; Method: force all flag bits high via the
; stack, then read them back.
;
	ORG	0100H
;
BDOS	EQU	0005H
;
START:	LXI	H,0FFFFH
	PUSH	H
	POP	PSW
	PUSH	PSW
	POP	H
	MOV	A,L
	ANI	28H
	JNZ	ISZ80
;
	LXI	D,MSG80
	JMP	PRINT
;
ISZ80:	LXI	D,MSGZ80
;
PRINT:	MVI	C,09H
	CALL	BDOS
	RET
;
MSG80:	DB	'CPU is Intel 8080'
	DB	0DH,0AH,'$'
;
MSGZ80:	DB	'CPU is Zilog Z80'
	DB	0DH,0AH,'$'
;
	END	START
