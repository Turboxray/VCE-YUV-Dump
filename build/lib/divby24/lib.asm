
 ;...........................................................
 ; input:  X:Y = MSB:LSB
 ; output: A:Y = MSB:LSB Quotient, X = remainder

DivBy24:

    lda divBy24.branch.tbl,x          ;5

    beq .no_adjust                    ;4/2
    cmp #$01                          ;  2
    beq .adjust_1                     ;  4/2

.adjust_2                         ; ^ = 2+2+2  
    lda divBy24.lsb_Div.tbl.error2,y  ;5  carry is already set
    clc                               ;2
    adc divBy24.msb_div.tbl.lo,x      ;5
    pha                               ;3
    cla                               ;2
    adc divBy24.msb_div.tbl.hi, x     ;5
    ldx divBy24.mod.tbl.error2, y     ;5
    ply                               ;4   
  rts                               ;7 = 49

.adjust_1                         ; ^ = 2+2+4  
    lda divBy24.lsb_Div.tbl.error1,y  ;5  carry is already set
    clc                               ;2
    adc divBy24.msb_div.tbl.lo,x      ;5
    pha                               ;2
    cla                               ;2
    adc divBy24.msb_div.tbl.hi, x     ;5
    ldx divBy24.mod.tbl.error1, y     ;5
    ply                               ;4   
  rts                               ;7 = 51

.no_adjust                        ; ^ = 4  
    lda divBy24.lsb_Div.tbl.base,y    ;5  no error correction, carry not guaranteed to be set
    clc                               ;2
    adc divBy24.msb_div.tbl.lo,x      ;5
    pha                               ;2
    cla                               ;2
    adc divBy24.msb_div.tbl.hi, x     ;5
    ldx divBy24.mod.tbl.noerror, y    ;5
    ply                               ;4   
  rts                               ;7 = 47



 ;...........................................................
 ; input:  X:Y = MSB:LSB
 ; output: A:Y = MSB:LSB Quotient 

DivBy24.noMod:

    lda divBy24.branch.tbl,x          ;5

    beq .no_adjust                    ;4/2
    cmp #$01                          ;  2
    beq .adjust_1                     ;  4/2

.adjust_2                         ; ^ = 2+2+2  
    lda divBy24.lsb_Div.tbl.error2,y  ;5  carry is already set
    clc                               ;2
    adc divBy24.msb_div.tbl.lo,x      ;5
    tay                               ;2
    cla                               ;2
    adc divBy24.msb_div.tbl.hi, x     ;5
  rts                               ;7 = 39

.adjust_1                         ; ^ = 2+2+4  
    lda divBy24.lsb_Div.tbl.error1,y  ;5  carry is already set
    clc                               ;2
    adc divBy24.msb_div.tbl.lo,x      ;5
    tay                               ;2
    cla                               ;2
    adc divBy24.msb_div.tbl.hi, x     ;5
  rts                               ;7 = 41

.no_adjust                        ; ^ = 4  
    lda divBy24.lsb_Div.tbl.base,y    ;5  no error correction, carry not guaranteed to be set
    clc                               ;2
    adc divBy24.msb_div.tbl.lo,x      ;5
    tay                               ;2
    cla                               ;2
    adc divBy24.msb_div.tbl.hi, x     ;5
  rts                               ;7 = 37

 ;...........................................................
 ; input:  X:Y = MSB:LSB
 ; output: X = Remainder 

ModBy24:

    lda divBy24.branch.tbl,x          ;5

    beq .no_adjust                    ;4/2
    cmp #$01                          ;  2
    beq .adjust_1                     ;  4/2

.adjust_2                         ; ^ = 2+2+2  
    ldx divBy24.mod.tbl.error2, y     ;5
  rts                               ;7 = 18

.adjust_1                         ; ^ = 2+2+4  
    ldx divBy24.mod.tbl.error1, y     ;5
  rts                               ;7 = 20

.no_adjust                        ; ^ = 4  
    ldx divBy24.mod.tbl.noerror, y    ;5
  rts                               ;7 = 16

