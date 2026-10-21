;===========================================================
; VC3Handler.asm
; Lab 7D - Programmable Sine Wave Generator
;===========================================================

include "m8c.inc"
include "memory.inc"
include "PSoCAPI.inc"

;-----------------------------------------------------------
; C variable declared in main.c:
;
; struct I2C_Regs
; {
;     unsigned int  wPhase;
;     unsigned int  wPhaseRate;
;     unsigned char bGainValue;
; } MyI2C_Regs;
;
; Memory layout:
; _MyI2C_Regs + 0 = wPhase HIGH byte
; _MyI2C_Regs + 1 = wPhase LOW byte
; _MyI2C_Regs + 2 = wPhaseRate HIGH byte
; _MyI2C_Regs + 3 = wPhaseRate LOW byte
; _MyI2C_Regs + 4 = bGainValue
;-----------------------------------------------------------

export _VC3Handler


_VC3Handler:

    ;-------------------------------------------------------
    ; Phase = Phase + PhaseRate
    ;
    ; Do LOW byte first so carry propagates to HIGH byte.
    ;-------------------------------------------------------

    mov A, [_MyI2C_Regs + 1]       ; wPhase low byte
    add A, [_MyI2C_Regs + 3]       ; + wPhaseRate low byte
    mov [_MyI2C_Regs + 1], A

    mov A, [_MyI2C_Regs + 0]       ; wPhase high byte
    adc A, [_MyI2C_Regs + 2]       ; + rate high + carry
    mov [_MyI2C_Regs + 0], A

    ;-------------------------------------------------------
    ; High byte of phase is the table index.
    ; A = 0...255
    ;-------------------------------------------------------

    mov A, [_MyI2C_Regs + 0]

    ; Read:
    ;       A = SineTable[A]
    ;
    ; INDEX supports a 256-byte relative lookup table.
    ;-------------------------------------------------------

    index SineTable

    ;-------------------------------------------------------
    ; Write the DAC register.
    ; Manual requires Stall/Unstall around SCDAC_cr0 write.
    ;-------------------------------------------------------

    M8C_Stall
    mov reg[SCDAC_cr0], A
    M8C_Unstall

    reti


;===========================================================
; 256-entry sine lookup table
;
; Generated from the Lab 7D equation:
;
; 31*SIN(2*PI()*n/256)
;
; DAC register value:
; 128 + IF(x<0,32,0) + ABS(ROUND(x,0))
;
; Matches your Lab 7D spreadsheet.
;===========================================================

.literal

SineTable:

db 128,129,130,130,131,132,133,133,134,135,136,136,137,138,138,139
db 140,141,141,142,143,143,144,145,145,146,146,147,148,148,149,149
db 150,150,151,151,152,152,153,153,154,154,155,155,155,156,156,156
db 157,157,157,157,158,158,158,158,158,159,159,159,159,159,159,159
db 159,159,159,159,159,159,159,159,158,158,158,158,158,157,157,157
db 157,156,156,156,155,155,155,154,154,153,153,152,152,151,151,150
db 150,149,149,148,148,147,146,146,145,145,144,143,143,142,141,141
db 140,139,138,138,137,136,136,135,134,133,133,132,131,130,130,129
db 128,161,162,162,163,164,165,165,166,167,168,168,169,170,170,171
db 172,173,173,174,175,175,176,177,177,178,178,179,180,180,181,181
db 182,182,183,183,184,184,185,185,186,186,187,187,187,188,188,188
db 189,189,189,189,190,190,190,190,190,191,191,191,191,191,191,191
db 191,191,191,191,191,191,191,191,190,190,190,190,190,189,189,189
db 189,188,188,188,187,187,187,186,186,185,185,184,184,183,183,182
db 182,181,181,180,180,179,178,178,177,177,176,175,175,174,173,173
db 172,171,170,170,169,168,168,167,166,165,165,164,163,162,162,161

.endliteral