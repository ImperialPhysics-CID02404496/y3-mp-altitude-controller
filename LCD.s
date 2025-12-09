#include <xc.inc>

global  LCD_Setup, LCD_Write_Message,LCD_clr,LCD_setPos,LCD_Send_Byte_D
global LCD_Write_Number


psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage
LCD_pos: ds 1 ; cursor position
    



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
	
LCD_clr:
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

;----------------------------------------------------------
; LCD_setPos
;   W = 0..31  cursor absolute position
;----------------------------------------------------------
LCD_setPos:
    movwf   LCD_pos, A

    ; if pos < 16 ? line 1
    movlw   16
    subwf   LCD_pos, W, A     ; W = pos - 16
    bc      LCD_Pos_Line2     ; C=1 when pos >= 16

;-------- line 1: DDRAM = 0x00 + pos ------------
LCD_Pos_Line1:
    movf    LCD_pos, W, A
    iorlw   0x80
    call    LCD_Send_Byte_I
    
    ;delay to allow switch
    movlw 5
    call LCD_delay_ms
    return

;-------- line 2: DDRAM = 0x40 + (pos-16) -------
LCD_Pos_Line2:
    movlw   16
    subwf   LCD_pos, F, A
    movf    LCD_pos, W, A
    addlw   0x40
    iorlw   0x80
    call    LCD_Send_Byte_I
    
    ;delay to allow switch
    movlw 5
    call LCD_delay_ms
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

; AUTO-GENERATED STUPID 0?255 LCD NUMBER PRINTER USING LCD_tmp AS SOURCE
LCD_Write_Number:
    movwf LCD_tmp, A    ; save original W
    movlw 0
    cpfsgt LCD_tmp, A
    goto Print_0
    movlw 1
    cpfsgt LCD_tmp, A
    goto Print_1
    movlw 2
    cpfsgt LCD_tmp, A
    goto Print_2
    movlw 3
    cpfsgt LCD_tmp, A
    goto Print_3   
    movlw 4
    cpfsgt LCD_tmp, A
    goto Print_4
    movlw 5
    cpfsgt LCD_tmp, A
    goto Print_5
    movlw 6
    cpfsgt LCD_tmp, A
    goto Print_6
    movlw 7
    cpfsgt LCD_tmp, A
    goto Print_7
    movlw 8
    cpfsgt LCD_tmp, A
    goto Print_8
    movlw 9
    cpfsgt LCD_tmp, A
    goto Print_9
    movlw 10
    cpfsgt LCD_tmp, A
    goto Print_10
    movlw 11
    cpfsgt LCD_tmp, A
    goto Print_11
    movlw 12
    cpfsgt LCD_tmp, A
    goto Print_12
    movlw 13
    cpfsgt LCD_tmp, A
    goto Print_13
    movlw 14
    cpfsgt LCD_tmp, A
    goto Print_14
    movlw 15
    cpfsgt LCD_tmp, A
    goto Print_15
    movlw 16
    cpfsgt LCD_tmp, A
    goto Print_16
    movlw 17
    cpfsgt LCD_tmp, A
    goto Print_17
    movlw 18
    cpfsgt LCD_tmp, A
    goto Print_18
    movlw 19
    cpfsgt LCD_tmp, A
    goto Print_19
    movlw 20
    cpfsgt LCD_tmp, A
    goto Print_20
    movlw 21
    cpfsgt LCD_tmp, A
    goto Print_21
    movlw 22
    cpfsgt LCD_tmp, A
    goto Print_22
    movlw 23
    cpfsgt LCD_tmp, A
    goto Print_23
    movlw 24
    cpfsgt LCD_tmp, A
    goto Print_24
    movlw 25
    cpfsgt LCD_tmp, A
    goto Print_25
    movlw 26
    cpfsgt LCD_tmp, A
    goto Print_26
    movlw 27
    cpfsgt LCD_tmp, A
    goto Print_27
    movlw 28
    cpfsgt LCD_tmp, A
    goto Print_28
    movlw 29
    cpfsgt LCD_tmp, A
    goto Print_29
    movlw 30
    cpfsgt LCD_tmp, A
    goto Print_30
    movlw 31
    cpfsgt LCD_tmp, A
    goto Print_31
    movlw 32
    cpfsgt LCD_tmp, A
    goto Print_32
    movlw 33
    cpfsgt LCD_tmp, A
    goto Print_33
    movlw 34
    cpfsgt LCD_tmp, A
    goto Print_34
    movlw 35
    cpfsgt LCD_tmp, A
    goto Print_35
    movlw 36
    cpfsgt LCD_tmp, A
    goto Print_36
    movlw 37
    cpfsgt LCD_tmp, A
    goto Print_37
    movlw 38
    cpfsgt LCD_tmp, A
    goto Print_38
    movlw 39
    cpfsgt LCD_tmp, A
    goto Print_39
    movlw 40
    cpfsgt LCD_tmp, A
    goto Print_40
    movlw 41
    cpfsgt LCD_tmp, A
    goto Print_41
    movlw 42
    cpfsgt LCD_tmp, A
    goto Print_42
    movlw 43
    cpfsgt LCD_tmp, A
    goto Print_43
    movlw 44
    cpfsgt LCD_tmp, A
    goto Print_44
    movlw 45
    cpfsgt LCD_tmp, A
    goto Print_45
    movlw 46
    cpfsgt LCD_tmp, A
    goto Print_46
    movlw 47
    cpfsgt LCD_tmp, A
    goto Print_47
    movlw 48
    cpfsgt LCD_tmp, A
    goto Print_48
    movlw 49
    cpfsgt LCD_tmp, A
    goto Print_49
    movlw 50
    cpfsgt LCD_tmp, A
    goto Print_50
    movlw 51
    cpfsgt LCD_tmp, A
    goto Print_51
    movlw 52
    cpfsgt LCD_tmp, A
    goto Print_52
    movlw 53
    cpfsgt LCD_tmp, A
    goto Print_53
    movlw 54
    cpfsgt LCD_tmp, A
    goto Print_54
    movlw 55
    cpfsgt LCD_tmp, A
    goto Print_55
    movlw 56
    cpfsgt LCD_tmp, A
    goto Print_56
    movlw 57
    cpfsgt LCD_tmp, A
    goto Print_57
    movlw 58
    cpfsgt LCD_tmp, A
    goto Print_58
    movlw 59
    cpfsgt LCD_tmp, A
    goto Print_59
    movlw 60
    cpfsgt LCD_tmp, A
    goto Print_60
    movlw 61
    cpfsgt LCD_tmp, A
    goto Print_61
    movlw 62
    cpfsgt LCD_tmp, A
    goto Print_62
    movlw 63
    cpfsgt LCD_tmp, A
    goto Print_63
    movlw 64
    cpfsgt LCD_tmp, A
    goto Print_64
    movlw 65
    cpfsgt LCD_tmp, A
    goto Print_65
    movlw 66
    cpfsgt LCD_tmp, A
    goto Print_66
    movlw 67
    cpfsgt LCD_tmp, A
    goto Print_67
    movlw 68
    cpfsgt LCD_tmp, A
    goto Print_68
    movlw 69
    cpfsgt LCD_tmp, A
    goto Print_69
    movlw 70
    cpfsgt LCD_tmp, A
    goto Print_70
    movlw 71
    cpfsgt LCD_tmp, A
    goto Print_71
    movlw 72
    cpfsgt LCD_tmp, A
    goto Print_72
    movlw 73
    cpfsgt LCD_tmp, A
    goto Print_73
    movlw 74
    cpfsgt LCD_tmp, A
    goto Print_74
    movlw 75
    cpfsgt LCD_tmp, A
    goto Print_75
    movlw 76
    cpfsgt LCD_tmp, A
    goto Print_76
    movlw 77
    cpfsgt LCD_tmp, A
    goto Print_77
    movlw 78
    cpfsgt LCD_tmp, A
    goto Print_78
    movlw 79
    cpfsgt LCD_tmp, A
    goto Print_79
    movlw 80
    cpfsgt LCD_tmp, A
    goto Print_80
    movlw 81
    cpfsgt LCD_tmp, A
    goto Print_81
    movlw 82
    cpfsgt LCD_tmp, A
    goto Print_82
    movlw 83
    cpfsgt LCD_tmp, A
    goto Print_83
    movlw 84
    cpfsgt LCD_tmp, A
    goto Print_84
    movlw 85
    cpfsgt LCD_tmp, A
    goto Print_85
    movlw 86
    cpfsgt LCD_tmp, A
    goto Print_86
    movlw 87
    cpfsgt LCD_tmp, A
    goto Print_87
    movlw 88
    cpfsgt LCD_tmp, A
    goto Print_88
    movlw 89
    cpfsgt LCD_tmp, A
    goto Print_89
    movlw 90
    cpfsgt LCD_tmp, A
    goto Print_90
    movlw 91
    cpfsgt LCD_tmp, A
    goto Print_91
    movlw 92
    cpfsgt LCD_tmp, A
    goto Print_92
    movlw 93
    cpfsgt LCD_tmp, A
    goto Print_93
    movlw 94
    cpfsgt LCD_tmp, A
    goto Print_94
    movlw 95
    cpfsgt LCD_tmp, A
    goto Print_95
    movlw 96
    cpfsgt LCD_tmp, A
    goto Print_96
    movlw 97
    cpfsgt LCD_tmp, A
    goto Print_97
    movlw 98
    cpfsgt LCD_tmp, A
    goto Print_98
    movlw 99
    cpfsgt LCD_tmp, A
    goto Print_99
    movlw 100
    cpfsgt LCD_tmp, A
    goto Print_100
    movlw 101
    cpfsgt LCD_tmp, A
    goto Print_101
    movlw 102
    cpfsgt LCD_tmp, A
    goto Print_102
    movlw 103
    cpfsgt LCD_tmp, A
    goto Print_103
    movlw 104
    cpfsgt LCD_tmp, A
    goto Print_104
    movlw 105
    cpfsgt LCD_tmp, A
    goto Print_105
    movlw 106
    cpfsgt LCD_tmp, A
    goto Print_106
    movlw 107
    cpfsgt LCD_tmp, A
    goto Print_107
    movlw 108
    cpfsgt LCD_tmp, A
    goto Print_108
    movlw 109
    cpfsgt LCD_tmp, A
    goto Print_109
    movlw 110
    cpfsgt LCD_tmp, A
    goto Print_110
    movlw 111
    cpfsgt LCD_tmp, A
    goto Print_111
    movlw 112
    cpfsgt LCD_tmp, A
    goto Print_112
    movlw 113
    cpfsgt LCD_tmp, A
    goto Print_113
    movlw 114
    cpfsgt LCD_tmp, A
    goto Print_114
    movlw 115
    cpfsgt LCD_tmp, A
    goto Print_115
    movlw 116
    cpfsgt LCD_tmp, A
    goto Print_116
    movlw 117
    cpfsgt LCD_tmp, A
    goto Print_117
    movlw 118
    cpfsgt LCD_tmp, A
    goto Print_118
    movlw 119
    cpfsgt LCD_tmp, A
    goto Print_119
    movlw 120
    cpfsgt LCD_tmp, A
    goto Print_120
    movlw 121
    cpfsgt LCD_tmp, A
    goto Print_121
    movlw 122
    cpfsgt LCD_tmp, A
    goto Print_122
    movlw 123
    cpfsgt LCD_tmp, A
    goto Print_123
    movlw 124
    cpfsgt LCD_tmp, A
    goto Print_124
    movlw 125
    cpfsgt LCD_tmp, A
    goto Print_125
    movlw 126
    cpfsgt LCD_tmp, A
    goto Print_126
    movlw 127
    cpfsgt LCD_tmp, A
    goto Print_127
    movlw 128
    cpfsgt LCD_tmp, A
    goto Print_128
    movlw 129
    cpfsgt LCD_tmp, A
    goto Print_129
    movlw 130
    cpfsgt LCD_tmp, A
    goto Print_130
    movlw 131
    cpfsgt LCD_tmp, A
    goto Print_131
    movlw 132
    cpfsgt LCD_tmp, A
    goto Print_132
    movlw 133
    cpfsgt LCD_tmp, A
    goto Print_133
    movlw 134
    cpfsgt LCD_tmp, A
    goto Print_134
    movlw 135
    cpfsgt LCD_tmp, A
    goto Print_135
    movlw 136
    cpfsgt LCD_tmp, A
    goto Print_136
    movlw 137
    cpfsgt LCD_tmp, A
    goto Print_137
    movlw 138
    cpfsgt LCD_tmp, A
    goto Print_138
    movlw 139
    cpfsgt LCD_tmp, A
    goto Print_139
    movlw 140
    cpfsgt LCD_tmp, A
    goto Print_140
    movlw 141
    cpfsgt LCD_tmp, A
    goto Print_141
    movlw 142
    cpfsgt LCD_tmp, A
    goto Print_142
    movlw 143
    cpfsgt LCD_tmp, A
    goto Print_143
    movlw 144
    cpfsgt LCD_tmp, A
    goto Print_144
    movlw 145
    cpfsgt LCD_tmp, A
    goto Print_145
    movlw 146
    cpfsgt LCD_tmp, A
    goto Print_146
    movlw 147
    cpfsgt LCD_tmp, A
    goto Print_147
    movlw 148
    cpfsgt LCD_tmp, A
    goto Print_148
    movlw 149
    cpfsgt LCD_tmp, A
    goto Print_149
    movlw 150
    cpfsgt LCD_tmp, A
    goto Print_150
    movlw 151
    cpfsgt LCD_tmp, A
    goto Print_151
    movlw 152
    cpfsgt LCD_tmp, A
    goto Print_152
    movlw 153
    cpfsgt LCD_tmp, A
    goto Print_153
    movlw 154
    cpfsgt LCD_tmp, A
    goto Print_154
    movlw 155
    cpfsgt LCD_tmp, A
    goto Print_155
    movlw 156
    cpfsgt LCD_tmp, A
    goto Print_156
    movlw 157
    cpfsgt LCD_tmp, A
    goto Print_157
    movlw 158
    cpfsgt LCD_tmp, A
    goto Print_158
    movlw 159
    cpfsgt LCD_tmp, A
    goto Print_159
    movlw 160
    cpfsgt LCD_tmp, A
    goto Print_160
    movlw 161
    cpfsgt LCD_tmp, A
    goto Print_161
    movlw 162
    cpfsgt LCD_tmp, A
    goto Print_162
    movlw 163
    cpfsgt LCD_tmp, A
    goto Print_163
    movlw 164
    cpfsgt LCD_tmp, A
    goto Print_164
    movlw 165
    cpfsgt LCD_tmp, A
    goto Print_165
    movlw 166
    cpfsgt LCD_tmp, A
    goto Print_166
    movlw 167
    cpfsgt LCD_tmp, A
    goto Print_167
    movlw 168
    cpfsgt LCD_tmp, A
    goto Print_168
    movlw 169
    cpfsgt LCD_tmp, A
    goto Print_169
    movlw 170
    cpfsgt LCD_tmp, A
    goto Print_170
    movlw 171
    cpfsgt LCD_tmp, A
    goto Print_171
    movlw 172
    cpfsgt LCD_tmp, A
    goto Print_172
    movlw 173
    cpfsgt LCD_tmp, A
    goto Print_173
    movlw 174
    cpfsgt LCD_tmp, A
    goto Print_174
    movlw 175
    cpfsgt LCD_tmp, A
    goto Print_175
    movlw 176
    cpfsgt LCD_tmp, A
    goto Print_176
    movlw 177
    cpfsgt LCD_tmp, A
    goto Print_177
    movlw 178
    cpfsgt LCD_tmp, A
    goto Print_178
    movlw 179
    cpfsgt LCD_tmp, A
    goto Print_179
    movlw 180
    cpfsgt LCD_tmp, A
    goto Print_180
    movlw 181
    cpfsgt LCD_tmp, A
    goto Print_181
    movlw 182
    cpfsgt LCD_tmp, A
    goto Print_182
    movlw 183
    cpfsgt LCD_tmp, A
    goto Print_183
    movlw 184
    cpfsgt LCD_tmp, A
    goto Print_184
    movlw 185
    cpfsgt LCD_tmp, A
    goto Print_185
    movlw 186
    cpfsgt LCD_tmp, A
    goto Print_186
    movlw 187
    cpfsgt LCD_tmp, A
    goto Print_187
    movlw 188
    cpfsgt LCD_tmp, A
    goto Print_188
    movlw 189
    cpfsgt LCD_tmp, A
    goto Print_189
    movlw 190
    cpfsgt LCD_tmp, A
    goto Print_190
    movlw 191
    cpfsgt LCD_tmp, A
    goto Print_191
    movlw 192
    cpfsgt LCD_tmp, A
    goto Print_192
    movlw 193
    cpfsgt LCD_tmp, A
    goto Print_193
    movlw 194
    cpfsgt LCD_tmp, A
    goto Print_194
    movlw 195
    cpfsgt LCD_tmp, A
    goto Print_195
    movlw 196
    cpfsgt LCD_tmp, A
    goto Print_196
    movlw 197
    cpfsgt LCD_tmp, A
    goto Print_197
    movlw 198
    cpfsgt LCD_tmp, A
    goto Print_198
    movlw 199
    cpfsgt LCD_tmp, A
    goto Print_199
    movlw 200
    cpfsgt LCD_tmp, A
    goto Print_200
    movlw 201
    cpfsgt LCD_tmp, A
    goto Print_201
    movlw 202
    cpfsgt LCD_tmp, A
    goto Print_202
    movlw 203
    cpfsgt LCD_tmp, A
    goto Print_203
    movlw 204
    cpfsgt LCD_tmp, A
    goto Print_204
    movlw 205
    cpfsgt LCD_tmp, A
    goto Print_205
    movlw 206
    cpfsgt LCD_tmp, A
    goto Print_206
    movlw 207
    cpfsgt LCD_tmp, A
    goto Print_207
    movlw 208
    cpfsgt LCD_tmp, A
    goto Print_208
    movlw 209
    cpfsgt LCD_tmp, A
    goto Print_209
    movlw 210
    cpfsgt LCD_tmp, A
    goto Print_210
    movlw 211
    cpfsgt LCD_tmp, A
    goto Print_211
    movlw 212
    cpfsgt LCD_tmp, A
    goto Print_212
    movlw 213
    cpfsgt LCD_tmp, A
    goto Print_213
    movlw 214
    cpfsgt LCD_tmp, A
    goto Print_214
    movlw 215
    cpfsgt LCD_tmp, A
    goto Print_215
    movlw 216
    cpfsgt LCD_tmp, A
    goto Print_216
    movlw 217
    cpfsgt LCD_tmp, A
    goto Print_217
    movlw 218
    cpfsgt LCD_tmp, A
    goto Print_218
    movlw 219
    cpfsgt LCD_tmp, A
    goto Print_219
    movlw 220
    cpfsgt LCD_tmp, A
    goto Print_220
    movlw 221
    cpfsgt LCD_tmp, A
    goto Print_221
    movlw 222
    cpfsgt LCD_tmp, A
    goto Print_222
    movlw 223
    cpfsgt LCD_tmp, A
    goto Print_223
    movlw 224
    cpfsgt LCD_tmp, A
    goto Print_224
    movlw 225
    cpfsgt LCD_tmp, A
    goto Print_225
    movlw 226
    cpfsgt LCD_tmp, A
    goto Print_226
    movlw 227
    cpfsgt LCD_tmp, A
    goto Print_227
    movlw 228
    cpfsgt LCD_tmp, A
    goto Print_228
    movlw 229
    cpfsgt LCD_tmp, A
    goto Print_229
    movlw 230
    cpfsgt LCD_tmp, A
    goto Print_230
    movlw 231
    cpfsgt LCD_tmp, A
    goto Print_231
    movlw 232
    cpfsgt LCD_tmp, A
    goto Print_232
    movlw 233
    cpfsgt LCD_tmp, A
    goto Print_233
    movlw 234
    cpfsgt LCD_tmp, A
    goto Print_234
    movlw 235
    cpfsgt LCD_tmp, A
    goto Print_235
    movlw 236
    cpfsgt LCD_tmp, A
    goto Print_236
    movlw 237
    cpfsgt LCD_tmp, A
    goto Print_237
    movlw 238
    cpfsgt LCD_tmp, A
    goto Print_238
    movlw 239
    cpfsgt LCD_tmp, A
    goto Print_239
    movlw 240
    cpfsgt LCD_tmp, A
    goto Print_240
    movlw 241
    cpfsgt LCD_tmp, A
    goto Print_241
    movlw 242
    cpfsgt LCD_tmp, A
    goto Print_242
    movlw 243
    cpfsgt LCD_tmp, A
    goto Print_243
    movlw 244
    cpfsgt LCD_tmp, A
    goto Print_244
    movlw 245
    cpfsgt LCD_tmp, A
    goto Print_245
    movlw 246
    cpfsgt LCD_tmp, A
    goto Print_246
    movlw 247
    cpfsgt LCD_tmp, A
    goto Print_247
    movlw 248
    cpfsgt LCD_tmp, A
    goto Print_248
    movlw 249
    cpfsgt LCD_tmp, A
    goto Print_249
    movlw 250
    cpfsgt LCD_tmp, A
    goto Print_250
    movlw 251
    cpfsgt LCD_tmp, A
    goto Print_251
    movlw 252
    cpfsgt LCD_tmp, A
    goto Print_252
    movlw 253
    cpfsgt LCD_tmp, A
    goto Print_253
    movlw 254
    cpfsgt LCD_tmp, A
    goto Print_254
    movlw 255
    cpfsgt LCD_tmp, A
    goto Print_255

    return

Print_0:
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_1:
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_2:
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_3:
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_4:
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_5:
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_6:
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_7:
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_8:
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_9:
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_10:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_11:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_12:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_13:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_14:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_15:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_16:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_17:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_18:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_19:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_20:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_21:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_22:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_23:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_24:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_25:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_26:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_27:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_28:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_29:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_30:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_31:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_32:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_33:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_34:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_35:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_36:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_37:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_38:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_39:
    movlw '3'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_40:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_41:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_42:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_43:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_44:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_45:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_46:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_47:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_48:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_49:
    movlw '4'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_50:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_51:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_52:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_53:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_54:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_55:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_56:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_57:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_58:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_59:
    movlw '5'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_60:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_61:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_62:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_63:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_64:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_65:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_66:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_67:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_68:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_69:
    movlw '6'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_70:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_71:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_72:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_73:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_74:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_75:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_76:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_77:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_78:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_79:
    movlw '7'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_80:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_81:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_82:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_83:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_84:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_85:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_86:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_87:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_88:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_89:
    movlw '8'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_90:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_91:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_92:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_93:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_94:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_95:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_96:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_97:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_98:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_99:
    movlw '9'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_100:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_101:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_102:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_103:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_104:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_105:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_106:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_107:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_108:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_109:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_110:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_111:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_112:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_113:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_114:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_115:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_116:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_117:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_118:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_119:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_120:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_121:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_122:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_123:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_124:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_125:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_126:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_127:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_128:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_129:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_130:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_131:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_132:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_133:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_134:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_135:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_136:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_137:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_138:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_139:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_140:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_141:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_142:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_143:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_144:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_145:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_146:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_147:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_148:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_149:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_150:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_151:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_152:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_153:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_154:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_155:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_156:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_157:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_158:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_159:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_160:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_161:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_162:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_163:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_164:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_165:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_166:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_167:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_168:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_169:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_170:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_171:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_172:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_173:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_174:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_175:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_176:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_177:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_178:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_179:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_180:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_181:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_182:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_183:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_184:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_185:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_186:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_187:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_188:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_189:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_190:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_191:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_192:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_193:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_194:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_195:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_196:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_197:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_198:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_199:
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_200:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_201:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_202:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_203:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_204:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_205:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_206:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_207:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_208:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_209:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_210:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_211:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_212:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_213:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_214:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_215:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_216:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_217:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_218:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_219:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_220:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_221:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_222:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_223:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_224:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_225:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_226:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_227:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_228:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_229:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_230:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_231:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_232:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_233:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_234:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_235:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_236:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_237:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_238:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_239:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_240:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_241:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_242:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_243:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_244:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_245:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    return

Print_246:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '6'
    call LCD_Send_Byte_D
    return

Print_247:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '7'
    call LCD_Send_Byte_D
    return

Print_248:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '8'
    call LCD_Send_Byte_D
    return

Print_249:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    movlw '9'
    call LCD_Send_Byte_D
    return

Print_250:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '0'
    call LCD_Send_Byte_D
    return

Print_251:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '1'
    call LCD_Send_Byte_D
    return

Print_252:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '2'
    call LCD_Send_Byte_D
    return

Print_253:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '3'
    call LCD_Send_Byte_D
    return

Print_254:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '4'
    call LCD_Send_Byte_D
    return

Print_255:
    movlw '2'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
    movlw '5'
    call LCD_Send_Byte_D
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


