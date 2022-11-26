# COPIED FROM http://www.piclist.com/techref/microchip/math/radix/b2bhp-8b3d.htm
#define C 0
#define DC 1
#define clrc    bcf     STATUS, C
#define SKPDC   btfss   STATUS, DC
#define SKPNDC  btfsc   STATUS, DC

#define bin             0x1a
#define tens_and_ones   0x1b
#define hundreds        0x1c

        CLRF    hundreds
        SWAPF   bin, W      ; swap the nibbles
        ADDWF   bin, W      ; so we can add the upper to the lower
        ANDLW   0b00001111  ; lose the upper nibble (W is in BCD from now on)
        SKPNDC              ; if we carried a one (upper + lower > 16)
         ADDLW  0x16        ; add 16 (the place value) (1s + 16 * 10s)
        SKPNDC              ; did that cause a carry from the 1's place?
         ADDLW  0x06        ; if so, add the missing 6 (carry is only worth 10)
        ADDLW   0x06        ; fix max digit value by adding 6
        SKPDC               ; if was greater than 9, DC will be set
         ADDLW  -0x06       ; if if it wasn't, get rid of that extra 6
        
        BTFSC   bin,4       ; 16's place
         ADDLW  0x16 - 1 + 0x6  ; add 16 - 1 and check for digit carry
        SKPDC
         ADDLW  -0x06       ; if nothing carried, get rid of that 6
        
        BTFSC   bin, 5      ; 32nd's place
         ADDLW  0x30        ; add 32 - 2
        
        BTFSC   bin, 6      ; 64th's place
         ADDLW  0x60        ; add 64 - 4
        
        BTFSC   bin, 7      ; 128th's place
         ADDLW  0x20        ; add 128 - 8 % 100
        
        ADDLW   0x60        ; has the 10's place overflowed?
        RLF     hundreds, F ; pop carry in hundreds' LSB
        BTFSS   hundreds, 0 ; if it hasn't
         ADDLW  -0x60       ; get rid of that extra 60
        
        MOVWF   tens_and_ones   ; save result
        BTFSC   bin,7       ; remeber adding 28 - 8 for 128?
         INCF   hundreds, F ; add the missing 100 if bit 7 is set