#include <xc.inc>

global  LCD_Setup, LCD_Write_Message,LCD_rst,LCD_UpdateDisplay
extrn USS_r1
extrn kpd_tmp,kpd_tmp2,kpd_buffer,kpd_index

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage
    
kpd_quotient:  ds 1      ; quotient
    
div_w_divisor: ds 1

	LCD_E	EQU 5	; LCD enable bit
    	LCD_RS	EQU 4	; LCD register select bit

psect	lcd_code,class=CODE
    
LCD_Setup:
	clrf    LATB, A
	movlw   11000000B	    ; RB0:5 all outputs
	movwf	TRISB, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00001111B	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	movlw	00000110B	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	return

LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter, A
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return
	
LCD_rst:
    	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms

LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD
	return
	
; Set cursor to row 0 or 1 (row1/row2)
LCD_SetCursor:
    movf WREG, W, A
    bz Row1
    ; row2
    movlw 0x40
    bra SetCursorDone
Row1:
    movlw 0x00
SetCursorDone:
    call LCD_Send_Byte_I
    return
    
    

LCD_PrintHeight:
    ; Copy USS_r1 to kpd_tmp2
    movf USS_r1, W, A
    movwf kpd_tmp2,a

    ; -------- Hundreds Digit --------
    movlw 100
    movwf div_w_divisor,a       ; divisor = 100
    call div_w_safe           ; quotient -> kpd_quotient, remainder -> kpd_tmp
    movf kpd_quotient, W, A
    addlw '0'
    call LCD_Send_Byte_D

    ; -------- Tens Digit --------
    movf kpd_tmp, W, A        ; remainder from hundreds
    movwf kpd_tmp2,a
    movlw 10
    movwf div_w_divisor,a
    call div_w_safe
    movf kpd_quotient, W, A
    addlw '0'
    call LCD_Send_Byte_D

    ; -------- Units Digit --------
    movf kpd_tmp, W, A        ; remainder from tens
    addlw '0'
    call LCD_Send_Byte_D

    return

; Simple repeated subtraction division (0?255)
div_w_safe:
    movf kpd_tmp2, W, A
    movwf kpd_tmp2,a        ; ensure dividend copy
    clrf kpd_quotient,a     ; quotient = 0

div_loop:
    movf kpd_tmp2, W, A
    subwf div_w_divisor, W, A   ; W = dividend - divisor
    bc div_done                  ; if borrow set -> dividend < divisor -> done

    incf kpd_quotient, F,a         ; quotient++
    subwf kpd_tmp2, F, A         ; remainder -= divisor
    bra div_loop

div_done:
    movf kpd_tmp2, W, A
    movwf kpd_tmp,a             ; remainder
    return
    
LCD_UpdateDisplay:
    movlw 0
    call LCD_SetCursor     ; row 1
    call LCD_PrintHeight

    movlw 1
    call LCD_SetCursor     ; row 2
    lfsr 2, kpd_buffer
    movf kpd_index, W, A
    bz LCD_KeypadDone

KeypadLoop:
    movf INDF2, W, A
    call LCD_Send_Byte_D
    incf FSR2L, F, A
    decfsz kpd_index, F, A
    bra KeypadLoop
LCD_KeypadDone:
    return
	
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return


    end


