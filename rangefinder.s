#include <xc.inc>

 ; share following methods with global progra
global USS_setup, USS_sendPulse, USS_getReading, USS_calibrateReading 
    

psect	udata_acs   ; reserve data space in access ram
USS_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
USS_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
USS_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
    
USS_tmp: ds 1   ;temporary user reg

global USS_r1
USS_r1: ds 1 ;1B for pulse duration
    
    
psect USS_code, class=CODE
USS_setup:
    ;setup port D for rangefinder. 
    ; use vcc and gnd pins for power, use rd0 as trig (OUT), rd1 as signal (IN)
    movlw   0x00 ; set all to 0 to rst 
    movwf   TRISD, A; Port D all control outputs
    movwf LATD,A ; port D latches off to start

    ;set portD rd2 input
    movlw 0x02 ; rd1 only
    movwf TRISD, A 
    movlb 0x0f ; PADCFG1 (and RDPU) are not in access Ram, switch to bank memory
    bsf RDPU ; Turn on pull-ups for Port D
    
    return

    
    
USS_sendPulse: ;send 10us pulse
    ;set rd1 high for 20ms
    movlw 0x01
    movwf LATD,A
    
    ;10ms dly
    movlw 3
    call USS_delay_x4us
    
    ;set port rd1 low
    movlw 0x00
    movwf LATD,A
    return
    
    ; wait 20ms
    movlw 20
    call USS_delay_ms
    

USS_getReading:
    ;set tmp at 0 for counter
    movlw 0x00
    movwf USS_tmp,A
   
    ;send trigger
    call USS_sendPulse
    
    ;wait until rd1 is high (return pulse has started)
RD1_pause:
    btfsc   PORTD, 1,A      ; Skip next instruction if RD1 == 1 (HIGH)
    goto    RD1_check   ; If high ? exit loop
    goto    RD1_pause ; If low ? stay in loop
    
    
RD1_check:
    btfsc   PORTD,1,A     ; Test RD1 bit (skip next instruction if CLEAR)
    goto    RD1_HIGH        ; If bit = 1 ? HIGH

    ; If execution gets here, RD1 = LOW
RD1_LOW:
    ; off so signal over, move on to continue
    goto    CONTINUE

RD1_HIGH:
    ; signal on, increment counter and wait 1ms before checking again
    incf USS_tmp, A
    
    movlw 1
    call USS_delay_ms
    
    goto RD1_check

CONTINUE:
    movff USS_r1,USS_tmp,A  ;move temp reading to r1 as read pulse duration
    
    return
    
    
    
USS_calibrateReading:
    ; TODO convert time duration to distance using distance = duration * speed of sound
    ; USS_r1 has duration of pulse in ms = 2 * distance * speed of sound
    

    
    
; ** a few delay routines below here****
USS_delay_ms:		    ; delay given in ms in W
	movwf	USS_cnt_ms, A
USSlp2:	movlw	250	    ; 1 ms delay
	call	USS_delay_x4us	
	decfsz	USS_cnt_ms, A
	bra	USSlp2
	return
    
USS_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	USS_cnt_l, A	; now need to multiply by 16
	swapf   USS_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	USS_cnt_l, W, A ; move low nibble to W
	movwf	USS_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	USS_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	USS_delay
	return

USS_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
USSlp1:	decf 	USS_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	USS_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	USSlp1		; carry, then loop again
	return			; carry reset so return


    end



