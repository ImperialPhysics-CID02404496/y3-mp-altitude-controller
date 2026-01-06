#include <xc.inc>

global kpd_setup, kpd_getReading
global kpd_buffer, kpd_index

;----------------------------------------
; Data Section
;----------------------------------------
psect udata_acs
kpd_index:      ds 1       ; current write position
kpd_tmp:        ds 1       ; temporary variable for column
RowIdx:         ds 1       ; temporary row offset
TempIdx:        ds 1       ; temp table index
kpd_cnt_ms:     ds 1
kpd_cnt_l:      ds 1
kpd_cnt_h:      ds 1

psect udata_bank4
kpd_buffer:     ds 10      ; buffer for up to 10 key presses

; charTable mapped to physical layout
charTable:
    db 1,2,3,'F'    ; row0
    db   4,5,6,'E'   ; row1
    db   7,8,9,'D'   ; row2
    db   'A',0,'B','C' ; row3
charTableLen EQU 16

;----------------------------------------
; Code Section
;----------------------------------------
psect kpd_code,class=CODE

;----------------------------------------
; kpd_setup
;----------------------------------------
kpd_setup:
    ; clear buffer
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

    ; Setup keypad: rows outputs, columns inputs
    movlw 0b11110000
    movwf TRISJ,A
    movlw 0x0F
    movwf LATJ,A      ; drive all rows high initially

    ; Enable pull-ups if available
    movlb 0x0F
    bsf RJPU

    ; Setup LATC for debug (columns)
    movlw 0x00
    movwf LATC,A
    movlw 0x00
    movwf TRISC,A

    return

;----------------------------------------
; kpd_getReading
;----------------------------------------
kpd_getReading:
    clrf kpd_tmp,A    ; clear column

    ; Scan row 0
    movlw 0b11111110  ; row0 low
    movwf LATJ,A
    call kpd_scanRow
    bnz setRow0
    goto scan_row1

setRow0:
    movlw 0
    movwf RowIdx,A
    bra kpd_row0

scan_row1:
    movlw 0b11111101
    movwf LATJ,A
    call kpd_scanRow
    bnz setRow1
    goto scan_row2

setRow1:
    movlw 4
    movwf RowIdx,A
    bra kpd_row1

scan_row2:
    movlw 0b11111011
    movwf LATJ,A
    call kpd_scanRow
    bnz setRow2
    goto scan_row3

setRow2:
    movlw 8
    movwf RowIdx,A
    bra kpd_row2

scan_row3:
    movlw 0b11110111
    movwf LATJ,A
    call kpd_scanRow
    bnz setRow3
    return

setRow3:
    movlw 12
    movwf RowIdx,A
    bra kpd_row3

;----------------------------------------
; Row handlers
;----------------------------------------
kpd_row0: bra kpd_storeKey
kpd_row1: bra kpd_storeKey
kpd_row2: bra kpd_storeKey
kpd_row3: bra kpd_storeKey

;----------------------------------------
; kpd_scanRow
; Sets kpd_tmp = column number (1-4), 0 if none
; Active-low: pressed = 0
;----------------------------------------
kpd_scanRow:
    clrf kpd_tmp,A
    btfsc PORTJ,4,A
        goto col0_not_set
    movlw 1
    movwf kpd_tmp,A
    return
col0_not_set:
    btfsc PORTJ,5,A
        goto col1_not_set
    movlw 2
    movwf kpd_tmp,A
    return
col1_not_set:
    btfsc PORTJ,6,A
        goto col2_not_set
    movlw 3
    movwf kpd_tmp,A
    return
col2_not_set:
    btfsc PORTJ,7,A
        goto col3_not_set
    movlw 4
    movwf kpd_tmp,A
col3_not_set:
    return

;----------------------------------------
; kpd_storeKey
;----------------------------------------
kpd_storeKey:
    movf kpd_tmp,W,A
    

    movwf LATC
    bz kpd_noKey        ; skip if no key pressed

    ; Debug: show column on LATC
    movf kpd_tmp,W,A
    movwf LATC,A

    decf WREG,W,A        ; column 1-4 -> 0-3
    addwf RowIdx,W,A     ; index = row*4 + col
    movwf TempIdx,A

    ; Read key from charTable
    movlw low charTable
    movwf TBLPTRL,A
    movlw high charTable
    movwf TBLPTRH,A
    movlw highword charTable
    movwf TBLPTRU,A
    addwf TBLPTRL,F,A
    tblrd*               ; TABLAT = key

    ; Store in buffer
    movlw high(kpd_buffer)
    movwf FSR0H,A
    movlw low(kpd_buffer)
    movwf FSR0L,A
    movf kpd_index,W,A
    addwf FSR0L,F,A
    movff TABLAT, INDF0

    ; Increment index with wrap-around
    incf kpd_index,F,A
    movlw 10
    cpfsgt kpd_index,A
    bra kpd_noWrap
    clrf kpd_index,A
kpd_noWrap:

    ; Debounce (~20ms)
    movlw 20
    call kpd_delay_ms

kpd_noKey:
    return

;----------------------------------------
; Delay routines
;----------------------------------------
kpd_delay_ms:
    movwf kpd_cnt_ms,A
kpd_loop_ms:
    movlw 250
    call kpd_delay_x4us
    decfsz kpd_cnt_ms,A
    bra kpd_loop_ms
    return

kpd_delay_x4us:
    movwf kpd_cnt_l,A
    swapf kpd_cnt_l,F,A
    movlw 0x0F
    andwf kpd_cnt_l,W,A
    movwf kpd_cnt_h,A
    movlw 0xF0
    andwf kpd_cnt_l,F,A
    call kpd_delay
    return

kpd_delay:
    movlw 0x00
kpd_loop:
    decf kpd_cnt_l,F,A
    subwfb kpd_cnt_h,F,A
    bc kpd_loop
    return

    end
