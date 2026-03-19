	TITLE	'D+7A Digital Port Display'
;
; DIGDISPLAY.ASM
;
; Continuously reads the Cromemco D+7A digital input port
; and displays the value on the terminal in binary and hex.
; Loops until a key is pressed.
;
; Output format example:  10110011  B3
;
; Assembler: Microsoft M80 (Intel 8080 mnemonics)
; System:    CP/M with Cromemco D+7A at default base address
;

; --- CP/M BDOS equates ---
BDOS	EQU	0005H		; BDOS entry point
CONOUT	EQU	2		; Console output function
CONST	EQU	11		; Console status function

; --- D+7A port addresses (default configuration) ---
DGPORT	EQU	18H		; Digital parallel I/O (octal 030)

; --- ASCII constants ---
CR	EQU	0DH
LF	EQU	0AH

	ORG	100H

;-------------------------------------------------------
; Main program
;-------------------------------------------------------
START:	LXI	SP,STACK	; Set up local stack

LOOP:
; --- Check for keypress (BDOS function 11) ---
	MVI	C,CONST
	CALL	BDOS		; A = 0FFh if key ready, 00h if not
	ORA	A
	JNZ	DONE		; Exit if key pressed

; --- Read the digital port ---
	IN	DGPORT		; A = 8 digital input bits
	STA	READING		; Save current reading

; --- Display binary representation (8 bits) ---
	LDA	READING
	MVI	B,8		; 8 bits to display
BINLP:	RLC			; Rotate MSB into carry
	PUSH	PSW		; Save A and flags
	JC	BIT1
	MVI	A,'0'		; Carry clear = bit is 0
	JMP	PBIT
BIT1:	MVI	A,'1'		; Carry set = bit is 1
PBIT:	CALL	CHROUT		; Print the digit
	POP	PSW		; Restore A (rotated value)
	DCR	B
	JNZ	BINLP

; --- Print two spaces separator ---
	MVI	A,' '
	CALL	CHROUT
	MVI	A,' '
	CALL	CHROUT

; --- Display hex representation (2 nybbles) ---
	LDA	READING
	PUSH	PSW		; Save full byte
	RRC			; Shift high nybble to low
	RRC
	RRC
	RRC
	CALL	HEXDIG		; Print high nybble as hex digit
	POP	PSW		; Restore full byte
	CALL	HEXDIG		; Print low nybble as hex digit

; --- Print carriage return to overwrite line ---
	MVI	A,CR
	CALL	CHROUT

	JMP	LOOP		; Read again

;-------------------------------------------------------
; Exit - consume the keypress, print newline, return
;-------------------------------------------------------
DONE:	MVI	C,1		; BDOS function 1: console input
	CALL	BDOS		; Read and discard the key

	MVI	A,CR
	CALL	CHROUT
	MVI	A,LF
	CALL	CHROUT

	RST	0		; Warm boot (return to CP/M)

;-------------------------------------------------------
; HEXDIG - Print low nybble of A as a hex digit (0-F)
; Entry: A = value (only low 4 bits used)
; Clobbers: A
;-------------------------------------------------------
HEXDIG:	ANI	0FH		; Mask to low nybble
	CPI	10		; Is it A-F?
	JC	HEXNUM		; No, 0-9
	ADI	'A'-10		; Convert 10-15 to 'A'-'F'
	JMP	HEXPR
HEXNUM:	ADI	'0'		; Convert 0-9 to '0'-'9'
HEXPR:	CALL	CHROUT
	RET

;-------------------------------------------------------
; CHROUT - Print character in A via BDOS
; Preserves: B, H, L
;-------------------------------------------------------
CHROUT:	PUSH	B
	PUSH	D
	PUSH	H
	MOV	E,A		; Character to E
	MVI	C,CONOUT	; BDOS console output
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	RET

;-------------------------------------------------------
; Data area
;-------------------------------------------------------
READING: DB	0		; Current digital port reading

; --- Stack ---
	DS	64		; 32-level stack
STACK	EQU	$

	END	START
