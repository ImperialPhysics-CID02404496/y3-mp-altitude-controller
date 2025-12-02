#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn USS_setup, USS_sendPulse, USS_getReading, USS_calibrateReading
extrn USS_r1
extrn kpd_r1
extrn kpd_setup, kpd_getReading
extrn	LCD_Setup, LCD_Write_Message
	
psect	udata_acs   ; reserve data space in access ram
dly_cnt_l:	ds 1   ; reserve 1 byte for delay low counter
dly_cnt_h:	ds 1   ; reserve 1 byte for delay high counter
dly_cnt_ms:	ds 1   ; reserve 1 byte for delay ms counter
    
counter:    ds 1    ; reserve one byte for arbitrary  counter variable
    
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	
setup:	
	call USS_setup ;setup rangefinder
	call kpd_setup
	;call	UART_Setup	; setup UART
	;call	LCD_Setup	; setup UART
	goto	start
	
	;setup port E as output for testing output of USS
	movlw   0x00 ; set all to 0 to rst 
	movwf   TRISE, A; Port D all control outputs
	movwf LATE,A ; port D latches off to start
	
	;setup port F as output for testing keypad
	movwf   TRISF, A; Port D all control outputs
	movwf LATF,A ; port D latches off to start
	
	; ******* Main programme ****************************************
start: 	
    call USS_sendPulse
    
    call kpd_getReading
    
    movff kpd_r1,LATF,A
    
   
    
    ; pause 100ms
    movlw 1000
    call delay_ms
    
    
    
    goto start


	
	
	
; ** a few delay routines below here as LCD timing can be quite critical ****
delay_ms:		    ; delay given in ms in W
	movwf	dly_cnt_ms, A
dly_lp2:	
	movlw	250	    ; 1 ms delay
	call	delay_x4us	
	decfsz	dly_cnt_ms, A
	bra	dly_lp2
	return
    
delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	dly_cnt_l, A	; now need to multiply by 16
	swapf   dly_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	dly_cnt_l, W, A ; move low nibble to W
	movwf	dly_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	dly_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	delay
	return

delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
dly_lp1:	
	decf 	dly_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	dly_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	dly_lp1		; carry, then loop again
	return			; carry reset so return


    end