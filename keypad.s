#include <xc.inc>

 ; share following methods with global progra
global kpd_setup, kpd_getReading
global kpd_r1
    

psect	udata_acs   ; reserve data space in access ram
kpd_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
kpd_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
kpd_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
    
kpd_counter_1: ds 1 ; arbitrary counter
    
kpd_tmp_1: ds 1   ;temporary user reg
kpd_tmp_2: ds 1
    
kpd_r1: ds 1 ;1B for pulse duration
    
psect udata_bank4 ;reserve data anywhere in RAM (at 0x400)
kpd_inputs: ds 0x0A ;rsrv 10 bytes for input data
kpd_charTable: ds 0x10 ;rsrv 16 bytes for char table

psect data
; char table, data in program memory, and its length
charTable:
    db	0,1,2,3,4,5,6,7,8,9,'A','B','C','D','E','F'
charTableLen EQU 16
align 2
    
    
psect USS_code, class=CODE
kpd_setup:
    
    
    ;setup port J for keypad input. 
    movlw   0x00 ; set all to 0 to rst 
    movwf   TRISD, A; Port D all control outputs
    movwf LATD,A ; port D latches off to start

    movlb 0x0f ; PADCFG1 (and RDPU) are not in access Ram, switch to bank memory
    bsf RDPU ; Turn on pull-ups for Port D
    
    ; setup flash memory
    bcf	CFGS	; point to Flash program memory  
    bsf	EEPGD 	; access Flash program memory
    
load_data:
	;load chartable into RAM
	lfsr	0, kpd_charTable	; Load FSR0 with address in RAM	
	movlw	low highword(charTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(charTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(charTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	charTableLen	; bytes to read
	movwf 	kpd_counter_1, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	kpd_counter_1, A		; count down to zero
	bra	loop		; keep going until finished

    return
    
    
kpd_getReading:
    ;set 0x0F (lowest nibble) as out HIGH. read 0xF0 (high nibble) as input
    ;repeat with nibbles reversed so 0xF0 out HIGH, 0x0F input reading
    ;merge to get binary code of input (in1 AND in2). save in reg.
    
    movlw 0xf0
    movwf TRISD,A ;lowest nibble set to output. highest nibble set to input
    
    ;set out to high
    movlw 0x0f
    movwf LATD,A
    
    ;setup inputs
    movlb 0x0f ; PADCFG1 (and RDPU) are not in access Ram, switch to bank memory
    bsf RDPU ; Turn on pull-ups for Port D
    
    ;get input 
    movf PORTD,A
    movwf kpd_tmp_1,A
    
    ;switch nibbles
    movlw 0x0f
    movwf TRISD,A ;lowest nibble set to output. highest nibble set to input
    
    ;set out to high
    movlw 0xf0
    movwf LATD,A
    
    ;get input 
    movf PORTD,A
   
    ;and the input results together - store in kpd_r1
    andwf kpd_tmp_1,W,A
    movwf kpd_tmp_2,A
    
    ;check against no input - don't wanna store no input
    movlw 0
    cpfseq kpd_tmp_2
    movwf kpd_r1,A
    
    return
    
    
USS_calibrateReading:
    ; TODO convert time duration to distance using distance = duration * speed of sound
    ; USS_r1 has duration of pulse in ms = 2 * distance * speed of sound
    

    
    
; ** a few delay routines below here****
kpd_delay_ms:		    ; delay given in ms in W
	movwf	kpd_cnt_ms, A
kpdlp2:	
	movlw	250	    ; 1 ms delay
	call	kpd_delay_x4us	
	decfsz	kpd_cnt_ms, A
	bra	kpdlp2
	return
    
kpd_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	kpd_cnt_l, A	; now need to multiply by 16
	swapf   kpd_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	kpd_cnt_l, W, A ; move low nibble to W
	movwf	kpd_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	kpd_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	kpd_delay
	return

kpd_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
kpdlp1:	
	decf 	kpd_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	kpd_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	kpdlp1		; carry, then loop again
	return			; carry reset so return


    end



