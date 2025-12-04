#include <xc.inc>

 ; share following methods with global progra
global kpd_setup, kpd_getReading
global kpd_buffer, kpd_index,kpd_tmp,kpd_tmp2
 
; get lcd stuff to print onto screen

    

psect	udata_acs   ; reserve data space in access ram

kpd_index: ds 1	; current pos in key press store
kpd_tmp: ds 1
kpd_tmp2: ds 1
    
psect udata_bank4
kpd_buffer: ds 10   ; stores up to 16 key presses
    
kpd_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
kpd_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
kpd_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
    
kpd_counter_1: ds 1 ; arbitrary counter
;    
;kpd_tmp_1: ds 1   ;temporary user reg
;kpd_tmp_2: ds 1

psect charTable_class, class=CODE, reloc=2
charTable:
    db  '1','2','3','F'
    db  '4','5','6','E'
    db  '7','8','9','D'
    db  'A','0','B','C'    

psect USS_code, class=CODE
kpd_setup:
    
    
    ;setup port J for keypad input. 
    movlw   0b11110000 ; set all to 0 to rst 
    movwf   TRISJ, A; Port J all control outputs
    movlw 0x00
    movwf LATJ,A ; port J latches off to start

    movlb 0x0f ; PADCFG1 (and RDPU) are not in access Ram, switch to bank memory
    bsf RJPU ; Turn on pull-ups for Port D
    
    return
    
   
kpd_getReading:

    ; --- No key by default ---
    clrf kpd_tmp, A

    ; -------- Row 0 --------
    movlw 0b11111110     ; J0=0, J1-3=1, J4-7 inputs
    movwf LATJ, A
    call kpd_scanRow
    movf kpd_tmp, W, A
    bnz keyFoundRow0

    ; -------- Row 1 --------
    movlw 0b11111101
    movwf LATJ, A
    call kpd_scanRow
    movf kpd_tmp, W, A
    bnz keyFoundRow1

    ; -------- Row 2 --------
    movlw 0b11111011
    movwf LATJ, A
    call kpd_scanRow
    movf kpd_tmp, W, A
    bnz keyFoundRow2

    ; -------- Row 3 --------
    movlw 0b11110111
    movwf LATJ, A
    call kpd_scanRow
    movf kpd_tmp, W, A
    bnz keyFoundRow3

    return             ; no key pressed


; ========== ROW-based decode ==========
keyFoundRow0:
    ; kpd_tmp = column (1?4)
    ; Key number = (row*4 + col)
    movf kpd_tmp, W, A       ; row 0 ? key = col
    bra storeKey

keyFoundRow1:
    movf kpd_tmp, W, A
    addlw 4
    bra storeKey

keyFoundRow2:
    movf kpd_tmp, W, A
    addlw 8
    bra storeKey

keyFoundRow3:
    movf kpd_tmp, W, A
    addlw 12
    ; fall through


; ========== STORE KEY IN BUFFER ==========
storeKey:
    ; W = key number (1?16)
    decf WREG, W, A          ; convert to 0?15 for table lookup

    ; Load ASCII from charTable
    movlw low charTable
    movwf TBLPTRL, A
    movlw high charTable
    movwf TBLPTRH, A
    movlw highword charTable
    movwf TBLPTRU, A

    addwf TBLPTRL, F, A      ; add offset, table entries are single byte
    tblrd*                  ; read ASCII into TABLAT

    ; Store ASCII into kpd_buffer[kpd_index]
    lfsr 0, kpd_buffer
    movf kpd_index, W, A
    addwf FSR0L, F, A
    movff TABLAT, INDF0

    ; Increment index (simple wrap at 10 chars)
    incf kpd_index, F, A
    movlw 10
    cpfsgt kpd_index, A
    bra noWrap
    clrf kpd_index, A
noWrap:

    ; Simple debounce delay
    movlw 20
    call kpd_delay_ms

    return



; ============================================================
; Support routine: returns column number in kpd_tmp (1?4) or 0
; ============================================================
kpd_scanRow:
    clrf kpd_tmp, A

    btfss PORTJ, 4, A
    movlw 1
    btfss PORTJ, 5, A
    movlw 2
    btfss PORTJ, 6, A
    movlw 3
    btfss PORTJ, 7, A
    movlw 4

    movwf kpd_tmp, A
    return
    
    
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



