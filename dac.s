#include <xc.inc>

 ; share following methods with global progra
global dac_setup, dac_setOutput,pwm_setup, pwm_setDuty
 

    

psect	udata_acs   ; reserve data space in access ram

dac_tmp: ds 1   ;temporary user reg
duty_tmp: ds 1
sw_duty: ds 1
TEMP1: ds 1
    
    
psect dac_code, class=CODE
dac_setup:
    ;setup port F for DAC output. 
    movlw   0x00 ; set all to 0 to rst 
    movwf   TRISJ, A; Port D all control outputs
    movwf LATJ,A ; port D latches off to start
    
    return

  ;---------------------------------------------------------
; Initialize PWM on CCP1 (RC2) at ~1 kHz
;---------------------------------------------------------
pwm_setup:
    BCF TRISC,2,A
    
    ; 249 gives roughly 1khz 
    ; 49 give roughly 5khz
    MOVLW 49
    MOVWF PR2,A

    MOVLW 0x0C
    MOVWF CCP1CON,A

    CLRF CCPR1L,A
    BCF CCP1CON,5,A
    BCF CCP1CON,4,A

    MOVLW 0b00000111
    MOVWF T2CON,A
    RETURN

pwm_setDuty:
    ; WREG = duty (0-255)
    MOVWF duty_tmp,A         ; store 8-bit duty

    ; Convert 8-bit -> 10-bit by multiplying by 4
    MOVF duty_tmp,W,A
    MOVWF PRODL,A
    MOVLW 2
    MULLW PRODL               ; PRODH:PRODL = 8-bit * 4

    ; Upper 8 bits ? CCPR1L
    MOVF PRODH,W,A
    MOVWF CCPR1L,A

    ; Lower 2 bits ? CCP1CON<5:4>
    MOVF PRODL,W,A
    ANDLW 0x03
    MOVWF duty_tmp,A

    BCF CCP1CON,4,A
    BCF CCP1CON,5,A

    BTFSC duty_tmp,0,A
    BSF CCP1CON,4,A
    BTFSC duty_tmp,1,A
    BSF CCP1CON,5,A

    RETURN
    

dac_setOutput: ; W -> PORTF
    movwf LATJ,A
    
    return

    end



