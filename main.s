#include <xc.inc>
;import modules
extrn dac_setup, dac_setOutput
extrn USS_setup, USS_getReading, USS_calibrateReading
;extrn kpd_setup, kpd_getReading
extrn LCD_Setup, LCD_Write_Message,LCD_clr,LCD_setPos,LCD_Send_Byte_D
extrn LCD_Write_Number
extrn pwm_setup,pwm_setDuty
extrn motor_init, motor_enable, motor_disable, motor_forward
extrn motor_reverse, motor_stop, motor_brake

;import variables
extrn USS_r1
extrn kpd_buffer, kpd_index

global dy
	
psect	udata_acs   ; reserve data space in access ram
dly_cnt_l:	ds 1   ; reserve 1 byte for delay low counter
dly_cnt_h:	ds 1   ; reserve 1 byte for delay high counter
dly_cnt_ms:	ds 1   ; reserve 1 byte for delay ms counter
    
counter:    ds 1    ; reserve one byte for arbitrary  counter variable
tmp: ds 1
    
TempIdx: ds 1 ;used for printing kpd buff
    
h_wanted: ds 1
dy: ds 1    

    
LCD_USS_Table_len   EQU 7   ; "height:"
LCD_KPD_Table_len   EQU 6   ; "input:"
    
LCD_number_bank: ds 10

psect udata_bank4
    LCD_USS_Table_RAM:   ds LCD_USS_Table_len
    LCD_KPD_Table_RAM:   ds LCD_KPD_Table_len
    
    
    LetterTable: ds 1   ; temporary 1-byte table for letters (printing kpd buff)
    

;
psect data
LCD_USS_Table:
    db 'h','e','i','g','h','t',':'
LCD_KPD_Table:
    db 'i','n','p','u','t',':'


    
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	
setup:	
	call USS_setup ;setup rangefinder
	call dac_setup
	;call pwm_setup
	;call motor_init
	;call sw_pwm_init
	;call kpd_setup
	call	LCD_Setup	; setup UART
	
	;call motor_enable
	;call motor_forward
	call LCD_clr
	
	 ; setup flash memory
    ;bcf	CFGS	; point to Flash program memory  
    ;bsf	EEPGD 	; access Flash program memory
    
    goto	start
    

	; ******* Main programme ****************************************
start: 	
    ;sensor readings
    call USS_getReading
    call USS_calibrateReading
    
    
    ;print on lcd
    movlw 0
    call LCD_setPos
    movf USS_r1,W,A
    call LCD_Write_Number
    
    ;get input - kpd doesnt work so we shall consider arbitrary height
    movlw 65
    movf h_wanted,A
    
    ;configure and output to dac
    call configure_height
    ;movlw 255
    call dac_setOutput

    movlw 200
    call delay_ms
 
    goto start



; Inputs:
;   WREG = DESIRED height
;   CURRENT_HEIGHT = current height (8-bit)
; Output:
;   WREG = (DESIRED - CURRENT) + 128       ; range 0..255

configure_height:
    MOVWF tmp, A          ; tmp = DESIRED

    MOVF USS_r1, W, A   ; W = CURRENT
    SUBWF tmp, W, A        ; W = tmp - W = DESIRED - CURRENT   (signed diff in W)

    ; Now add 128 offset
    ;ADDLW 128              ; W = (DESIRED - CURRENT) + 128

    RETURN
	
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