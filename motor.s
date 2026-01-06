#include <xc.inc>
    
   GLOBAL motor_init
    GLOBAL motor_enable
    GLOBAL motor_disable
    GLOBAL motor_forward
    GLOBAL motor_reverse
    GLOBAL motor_stop
    GLOBAL motor_brake

    PSECT motor_driver, class=CODE

; mikroBUS1 ? PIC18F87K22 pins on EasyPIC PRO v7:
; AN  = RA0  ? Direction A
; RST = RE1  ? Direction B
; CS  = RB2  ? Standby/Enable

motor_init:
    ; Direction pins
    BCF TRISA,0,A    ; RA0 output
    BCF TRISC,0,A    ; Rc0 output

    ; Enable pin
    BCF TRISE,0,A    ; RE0 output

    ; Default: disabled
    BCF LATE,0,A
    RETURN

motor_enable:
    BSF LATE,0,A
    RETURN

motor_disable:
    BCF LATE,0,A
    RETURN

motor_forward:
    BSF LATA,0,A     ; AN  = 1
    BCF LATC,0,A     ; RST = 0
    RETURN

motor_reverse:
    BCF LATA,0,A     ; AN  = 0
    BSF LATC,0,A     ; RST = 1
    RETURN

motor_stop:
    BCF LATA,0,A     ; AN = 0
    BCF LATC,0,A     ; RST = 0
    RETURN

motor_brake:
    BSF LATA,0,A    ; AN = 1
    BSF LATC,0,A     ; RST = 1
    RETURN
    
    
    end



