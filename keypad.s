#include <xc.inc>

global kpd_setup, kpd_getReading
global kpd_buffer, kpd_index

;----------------------------------------
; Data Section
;----------------------------------------
psect udata_acs
kpd_index:      ds 1       ; current write position
kpd_tmp:        ds 1       ; temporary variable for scan
kpd_cnt_ms:     ds 1
kpd_cnt_l:      ds 1
kpd_cnt_h:      ds 1

psect udata_bank4
kpd_buffer:     ds 10      ; buffer for up to 10 key presses

charTable:
    db 0,1,2,3,4,5,6,7,8,9,'A','B','C','D','E','F'
    
charTableLen EQU 16

;----------------------------------------
; Code Section
;----------------------------------------
psect USS_code,class=CODE

;----------------------------------------
; kpd_setup
; Configure keypad port and pull-ups
;----------------------------------------
kpd_setup:
    ; clear buffer and index
    clrf kpd_index,A
    movlw 0
    movwf kpd_buffer,A
    movwf kpd_buffer+1,A
    movwf kpd_buffer+2,A
    movwf kpd_buffer+3,A
    movwf kpd_buffer+4,A
    movwf kpd_buffer+5,A
    movwf kpd_buffer+6,A
    movwf kpd_buffer+7,A
    movwf kpd_buffer+8,A
    movwf kpd_buffer+9,A

    ; setup TRIS and LAT for keypad port (example: PORTJ)
    movlw   0b11110000       ; rows as outputs, columns as inputs
    movwf   TRISJ, A
    movlw   0x00
    movwf   LATJ, A

    ; enable pull-ups (switch to correct bank if needed)
    movlb 0x0F
    bsf RJPU

    return

;----------------------------------------
; kpd_getReading
; Scan keypad, store ASCII in buffer
;----------------------------------------
kpd_getReading:

    ; clear temporary key
    clrf kpd_tmp, A

    ; scan row 0
    movlw 0b11111110
    movwf LATJ, A
    call kpd_scanRow
    movf kpd_tmp, W,A
    bnz kpd_row0

    ; scan row 1
    movlw 0b11111101
    movwf LATJ, A
    call kpd_scanRow
    movf kpd_tmp, W,A
    bnz kpd_row1

    ; scan row 2
    movlw 0b11111011
    movwf LATJ, A
    call kpd_scanRow
    movf kpd_tmp, W,A
    bnz kpd_row2

    ; scan row 3
    movlw 0b11110111
    movwf LATJ, A
    call kpd_scanRow
    movf kpd_tmp, W,A
    bnz kpd_row3

    return     ; no key pressed

;----------------------------------------
; Row handlers
;----------------------------------------
kpd_row0: bra kpd_storeKey
kpd_row1: addlw 4
           bra kpd_storeKey
kpd_row2: addlw 8
           bra kpd_storeKey
kpd_row3: addlw 12

;----------------------------------------
; kpd_storeKey
;----------------------------------------
kpd_storeKey:
    ; ignore if no key
    movf kpd_tmp, W,A
    bz kpd_noKey

    decf WREG, W   ,A       ; 1..16 ? 0..15

    ; Load ASCII from charTable
    movlw low charTable
    movwf TBLPTRL
    movlw high charTable
    movwf TBLPTRH
    movlw highword charTable
    movwf TBLPTRU
    addwf TBLPTRL, F
    tblrd*                 ; read ASCII into TABLAT

    ; Store in buffer (bank4)
    movlw high(kpd_buffer)
    movwf FSR0H
    movlw low(kpd_buffer)
    movwf FSR0L
    movf kpd_index, W,A
    addwf FSR0L, F
    movff TABLAT, INDF0

    ; increment index with wrap-around
    incf kpd_index, F,A
    movlw 10
    cpfsgt kpd_index, A
    bra kpd_noWrap
    clrf kpd_index,A
kpd_noWrap:

    ; simple debounce
    movlw 20
    call kpd_delay_ms

kpd_noKey:
    return

;----------------------------------------
; kpd_scanRow
; Returns column number in kpd_tmp (1-4), 0 if none
;----------------------------------------
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

;----------------------------------------
; Delay routines
;----------------------------------------
kpd_delay_ms:
    movwf kpd_cnt_ms, A
kpd_loop_ms:
    movlw 250
    call kpd_delay_x4us
    decfsz kpd_cnt_ms, A
    bra kpd_loop_ms
    return

kpd_delay_x4us:
    movwf kpd_cnt_l, A
    swapf kpd_cnt_l, F, A
    movlw 0x0f
    andwf kpd_cnt_l, W, A
    movwf kpd_cnt_h, A
    movlw 0xf0
    andwf kpd_cnt_l, F, A
    call kpd_delay
    return

kpd_delay:
    movlw 0x00
kpd_loop:
    decf kpd_cnt_l, F, A
    subwfb kpd_cnt_h, F, A
    bc kpd_loop
    return

    end
