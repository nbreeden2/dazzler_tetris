; JOYSTICK.ASM — Read Cromemco JS-1 joystick X/Y positions from both
; joystick consoles on the Cromemco D+7A I/O card and continuously
; display voltages on the CP/M console until a key is pressed.
;
; Assembler: Microsoft M80 (Intel 8080 mnemonics)
; System:    CP/M with Cromemco D+7A at default port addresses
;
; JS-1 #1: X axis = analog channel 1 (port 19h)
;          Y axis = analog channel 2 (port 1Ah)
; JS-1 #2: X axis = analog channel 3 (port 1Bh)
;          Y axis = analog channel 4 (port 1Ch)
;
; Each raw byte is signed two's complement; 1 LSB = 20 mV.
; Range: -2.56V to +2.54V.
;
; Output format (single line, updated in place):
;   X1: +N.NNV  Y1: +N.NNV  X2: +N.NNV  Y2: +N.NNV

        ORG  0100H          ; CP/M TPA

; --- CP/M BDOS equates ---
BDOS    EQU  0005H
C_WRITE EQU  02H           ; BDOS console output function
C_STAT  EQU  0BH           ; BDOS console status function
C_READ  EQU  01H           ; BDOS console input function

; --- Cromemco D+7A port addresses (default base 18h) ---
JS1X    EQU  19H           ; Analog channel 1 — JS-1 #1 X axis
JS1Y    EQU  1AH           ; Analog channel 2 — JS-1 #1 Y axis
JS2X    EQU  1BH           ; Analog channel 3 — JS-1 #2 X axis
JS2Y    EQU  1CH           ; Analog channel 4 — JS-1 #2 Y axis

; =====================================================================
; Main program
; =====================================================================
START:
        ; --- Print header ---
        LXI  H,MSGHDR
        CALL PRTSTR

; --- Main loop: read and display until keypress ---
LOOP:
        ; --- Check for keypress (BDOS function 11) ---
        MVI  C,C_STAT
        CALL BDOS
        ORA  A              ; A = 0FFh if key ready, 00h if not
        JNZ  EXIT           ; Key pressed — exit

        ; --- Read all four axes ---
        IN   JS1X           ; A = signed JS#1 X position
        STA  X1RAW
        IN   JS1Y           ; A = signed JS#1 Y position
        STA  Y1RAW
        IN   JS2X           ; A = signed JS#2 X position
        STA  X2RAW
        IN   JS2Y           ; A = signed JS#2 Y position
        STA  Y2RAW

        ; --- Print "X1: " and X1 voltage ---
        LXI  H,MSGX1
        CALL PRTSTR
        LDA  X1RAW
        CALL SHOWV

        ; --- Print "V  Y1: " and Y1 voltage ---
        LXI  H,MSGY1
        CALL PRTSTR
        LDA  Y1RAW
        CALL SHOWV

        ; --- Print "V  X2: " and X2 voltage ---
        LXI  H,MSGX2
        CALL PRTSTR
        LDA  X2RAW
        CALL SHOWV

        ; --- Print "V  Y2: " and Y2 voltage ---
        LXI  H,MSGY2
        CALL PRTSTR
        LDA  Y2RAW
        CALL SHOWV

        ; --- Print "V" then CR (no LF) to overwrite same line ---
        MVI  A,'V'
        CALL CONOUT
        MVI  A,0DH          ; Carriage return only
        CALL CONOUT

        JMP  LOOP

; --- Exit: consume keystroke, print newline, return to CP/M ---
EXIT:
        MVI  C,C_READ       ; Consume the pending keystroke
        CALL BDOS
        MVI  A,0DH          ; CR
        CALL CONOUT
        MVI  A,0AH          ; LF
        CALL CONOUT
        RST  0              ; Warm boot to CP/M

; =====================================================================
; SHOWV — Print signed D+7A reading as a voltage: +N.NN or -N.NN
;
; Entry: A = signed two's complement reading (-128 to +127)
; Exit:  Voltage printed to console, all registers clobbered
;
; Method: |voltage| = |A| * 2 (in units of 10 mV), then divide
;         to extract volts, tenths, hundredths digits.
;
; Special case: A = -128 (80h) produces 256 in 10-mV units which
;               is correct (+2.56 absolute value). Handled via
;               16-bit arithmetic after the multiply-by-2 step.
; =====================================================================
SHOWV:
        ORA  A              ; Test sign
        JP   SVPOS
        ; Negative: print '-' and negate
        PUSH PSW
        MVI  A,'-'
        CALL CONOUT
        POP  PSW
        CMA                 ; Complement
        INR  A              ; Negate (two's complement)
        JMP  SVCONV
SVPOS:
        ; Positive or zero: print '+'
        PUSH PSW
        MVI  A,'+'
        CALL CONOUT
        POP  PSW
SVCONV:
        ; A = absolute value (0-128; 128 only if original was -128)
        ; Multiply by 2 to get value in units of 10 mV (0-256 range)
        MOV  L,A
        MVI  H,0
        DAD  H              ; HL = A * 2 (units of 10 mV, range 0-256)

        ; Divide HL by 100 to get the volts digit
        MVI  B,0            ; Volts quotient
SV100:
        MOV  A,L
        SUI  100
        MOV  L,A
        MOV  A,H
        SBI  0
        MOV  H,A
        JC   SVDV           ; Underflow — done dividing
        INR  B
        JMP  SV100
SVDV:
        ; Restore remainder (add 100 back)
        MOV  A,L
        ADI  100
        MOV  L,A
        ; B = volts digit (0-2), L = remainder in 10-mV units

        ; Print volts digit
        MOV  A,B
        ADI  '0'
        CALL CONOUT

        ; Print decimal point
        MVI  A,'.'
        CALL CONOUT

        ; Divide remainder by 10 for tenths digit
        MOV  A,L
        MVI  B,0
SV10:
        SUI  10
        JC   SVDT
        INR  B
        JMP  SV10
SVDT:
        ADI  10             ; Restore hundredths remainder
        PUSH PSW            ; Save hundredths digit
        ; Print tenths digit
        MOV  A,B
        ADI  '0'
        CALL CONOUT
        ; Print hundredths digit
        POP  PSW
        ADI  '0'
        CALL CONOUT
        RET

; =====================================================================
; CONOUT — Output character to CP/M console
;
; Entry: A = ASCII character
; Exit:  All registers preserved except A
; =====================================================================
CONOUT:
        PUSH B
        PUSH D
        PUSH H
        MOV  E,A            ; Character in E
        MVI  C,C_WRITE      ; BDOS function 2
        CALL BDOS
        POP  H
        POP  D
        POP  B
        RET

; =====================================================================
; PRTSTR — Print $-terminated string
;
; Entry: HL = address of string (terminated by '$')
; Exit:  All registers preserved except A
; =====================================================================
PRTSTR:
        PUSH B
        PUSH D
        PUSH H
        XCHG                ; DE = string address
        MVI  C,09H          ; BDOS print string function
        CALL BDOS
        POP  H
        POP  D
        POP  B
        RET

; =====================================================================
; Data area
; =====================================================================
X1RAW:  DB   0              ; Raw JS#1 X-axis reading
Y1RAW:  DB   0              ; Raw JS#1 Y-axis reading
X2RAW:  DB   0              ; Raw JS#2 X-axis reading
Y2RAW:  DB   0              ; Raw JS#2 Y-axis reading

; Message strings (CP/M '$'-terminated)
MSGHDR: DB   'Cromemco JS-1 Dual Joystick Reader',0DH,0AH,'$'
MSGX1:  DB   'X1: $'
MSGY1:  DB   'V  Y1: $'
MSGX2:  DB   'V  X2: $'
MSGY2:  DB   'V  Y2: $'

        END  START
