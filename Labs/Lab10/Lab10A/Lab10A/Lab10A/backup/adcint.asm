;;*****************************************************************************
;;*****************************************************************************
;;  FILENAME: ADCINT.asm
;;  Version: 1.20, Updated on 2015/3/4 at 22:21:26
;;
;;  DESCRIPTION: Assembler interrupt service routine for the ADCINC
;;               A/D Converter User Module. This code works for both the
;;               first and second-order modulator topologies.
;;-----------------------------------------------------------------------------
;;  Copyright (c) Cypress Semiconductor 2015. All Rights Reserved.
;;*****************************************************************************
;;*****************************************************************************

include "m8c.inc"
include "memory.inc"
include "ADC.inc"


;-----------------------------------------------
;  Global Symbols
;-----------------------------------------------

export _ADC_ADConversion_ISR

export _ADC_iResult
export  ADC_iResult
export _ADC_fStatus
export  ADC_fStatus
export _ADC_bState
export  ADC_bState
export _ADC_fMode
export  ADC_fMode
export _ADC_bNumSamples
export  ADC_bNumSamples

;-----------------------------------------------
; Variable Allocation
;-----------------------------------------------
AREA InterruptRAM(RAM,REL)
 ADC_iResult:
_ADC_iResult:                              BLK  2 ;Calculated answer
  iTemp:                                   BLK  2 ;internal temp storage
 ADC_fStatus:
_ADC_fStatus:                              BLK  1 ;ADC Status
 ADC_bState:
_ADC_bState:                               BLK  1 ;State value of ADC count
 ADC_fMode:
_ADC_fMode:                                BLK  1 ;Integrate and reset mode.
 ADC_bNumSamples:
_ADC_bNumSamples:                          BLK  1 ;Number of samples to take.

;-----------------------------------------------
;  EQUATES
;-----------------------------------------------

;@PSoC_UserCode_INIT@ (Do not change this line.)
;---------------------------------------------------
; Insert your custom declarations below this banner
;---------------------------------------------------

;------------------------
;  Constant Definitions
;------------------------


;------------------------
; Variable Allocation
;------------------------


;---------------------------------------------------
; Insert your custom declarations above this banner
;---------------------------------------------------
;@PSoC_UserCode_END@ (Do not change this line.)


AREA UserModules (ROM, REL)

;-----------------------------------------------------------------------------
;  FUNCTION NAME: _ADC_ADConversion_ISR
;
;  DESCRIPTION: Perform final filter operations to produce output samples.
;
;-----------------------------------------------------------------------------
;
;    The decimation rate is established by the PWM interrupt. Four timer
;    clocks elapse for each modulator output (decimator input) since the
;    phi1/phi2 generator divides by 4. This means the timer period and thus
;    it's interrupt must equal 4 times the actual decimation rate.  The
;    decimator is ru  for 2^(#bits-6).
;
_ADC_ADConversion_ISR:
    dec  [ADC_bState]
if1:
    jc endif1 ; no underflow
    reti
endif1:
    cmp [ADC_fMode],0
if2: 
    jnz endif2  ;leaving reset mode
    push A                            ;read decimator
    mov  A, reg[ADC_DEC_DL]
    mov  [iTemp + LowByte],A
    mov  A, reg[ADC_DEC_DH]
    mov  [iTemp + HighByte], A
    pop A
    mov [ADC_fMode],1
    mov [ADC_bState],((1<<(ADC_bNUMBITS- 6))-1)
    reti
endif2:
    ;This code runs at end of integrate
    ADC_RESET_INTEGRATOR_M
    push A
    mov  A, reg[ADC_DEC_DL]
    sub  A,[iTemp + LowByte]
    mov  [iTemp +LowByte],A
    mov  A, reg[ADC_DEC_DH]
    sbb  A,[iTemp + HighByte]

       ;check for overflow
IF     ADC_8_OR_MORE_BITS
    cmp A,(1<<(ADC_bNUMBITS - 8))
if3: 
    jnz endif3 ;overflow
    dec A
    mov [iTemp + LowByte],ffh
endif3:
ELSE
    cmp [iTemp + LowByte],(1<<(ADC_bNUMBITS))
if4: 
    jnz endif4 ;overflow
    dec [iTemp + LowByte]
endif4:
ENDIF
IF ADC_SIGNED_DATA
IF ADC_9_OR_MORE_BITS
    sub A,(1<<(ADC_bNUMBITS - 9))
ELSE
    sub [iTemp +LowByte],(1<<(ADC_bNUMBITS - 1))
    sbb A,0
ENDIF
ENDIF
    mov  [ADC_iResult + LowByte],[iTemp +LowByte]
    mov  [ADC_iResult + HighByte],A
    mov  [ADC_fStatus],1
ConversionReady:
    ;@PSoC_UserCode_BODY@ (Do not change this line.)
    ;---------------------------------------------------
    ; Insert your custom code below this banner
    ;---------------------------------------------------
    ;  Sample data is now in iResult
    ;
    ;  NOTE: This interrupt service routine has already
    ;  preserved the values of the A CPU register. If
    ;  you need to use the X register you must preserve
    ;  its value and restore it before the return from
    ;  interrupt.
    ;---------------------------------------------------
    ; Insert your custom code above this banner
    ;---------------------------------------------------
    ;@PSoC_UserCode_END@ (Do not change this line.)
    pop A
    cmp [ADC_bNumSamples],0
if5: 
    jnz endif5 ; Number of samples is zero
    mov [ADC_fMode],0
    mov [ADC_bState],0
    ADC_ENABLE_INTEGRATOR_M
    reti       
endif5:
    dec [ADC_bNumSamples]
if6:
    jz endif6  ; count not zero
    mov [ADC_fMode],0
    mov [ADC_bState],0
    ADC_ENABLE_INTEGRATOR_M
    reti       
endif6:
    ;All samples done
    M8C_SetBank1
    and reg[E7h], 3Fh            ; if we are in 29xxx or 24x94   
    or  reg[E7h], 80h            ; then set to incremental Mode
    M8C_SetBank0
    ADC_STOPADC_M
 reti 
; end of file ADCINT.asm
