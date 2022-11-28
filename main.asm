    PROCESSOR    10F200
#include <xc.inc>
    config WDTE  = OFF ; Disable watchdog timer
    config CP    = OFF ; Disable code protection
    config MCLRE = OFF ; Disable reset functionality of GPIO3
    PSECT resetVec,class=CODE,delta=2,abs

#define C 0
#define DC 1
#define clrc    bcf     STATUS, C
#define skpc    btfss   STATUS, C
#define skpnc   btfsc   STATUS, C
#define skpdc   btfss   STATUS, DC
#define skpndc  btfsc   STATUS, DC

#define bin             0x1a
#define tens_and_ones   0x1b
#define hundreds        0x1c

resetVec:
INIT:
    movlw   ~(1 << 5)                   ; Enable GPIO2 by disabling T0CS = 5th bit
    option                              ; and copy this value into OPTION register
    movlw   11111000B                   ; turn on GPIO 0, 1, and 2
    tris    GPIO                        ; Copy W into GPIO tristate register

    movlw   0
    movwf   0x1d

LOOP:

    movf    0x1d, W
    movwf   0x1a

    call    BINARY_TO_BCD               ; Hundreds is now in 0x1c, tens and ones in 0x1b

    bcf     GPIO, GPIO_GP2_POSITION     ; Clear GP2 (set LATCH to LOW) 

    movf    0x1b, W                     ; Copy tens and ones to W
    andlw   0b00001111                  ; Take the ones information only
    movwf   0x1a                        ; Copy W to F
    call    DISPLAY_DIGIT
    
    swapf   0x1b, W                     ; Swap positions of tens and ones in F
    andlw   0b00001111                  ; Take the tens information only
    movwf   0x1a                        ; Copy W to F
    call    DISPLAY_DIGIT

    movf    0x1c, W                     ; Copy hundreds to W
    movwf   0x1a                        ; Copy W to F
    call    DISPLAY_DIGIT

    bsf     GPIO, GPIO_GP2_POSITION     ; Set GP2   (set LATCH to HIGH)

    btfss   GPIO, GPIO_GP3_POSITION     ; Don't loop yet if GP3 is HIGH
    goto    LOOP

_wait_for_release:
    btfsc   GPIO, GPIO_GP3_POSITION     ; Exit infinite loop if GP3 is LOW
    goto _wait_for_release

    incf    0x1d, F

    goto    LOOP

DISPLAY_DIGIT:
; (39 or 29 cycles) + 73 cycles
; 104 cycles without DP, 114 cycles with DP (decimal point)

    ; PARAMETERS: 0x1a <3..0> contains the value of the desired digit to display
    ;             0x1a <4>    is a flag to turn ON the decimal point

    ; DATA:  GP0
    ; CLOCK: GP1
    ; LATCH: GP2

    movlw   0b11111100                  ; [ A B C D E F     ]       
    movwf   0x10                        ; Use GP register 0 to store the digit 0

    movlw   0b01100000                  ; [   B C           ]    
    movwf   0x11                        ; Use GP register 1 to store the digit 1

    movlw   0b11011010                  ; [ A B   D E F G   ]
    movwf   0x12                        ; Use GP register 2 to store the digit 2

    movlw   0b11110010                  ; [ A B C D     G   ]
    movwf   0x13                        ; Use GP register 3 to store the digit 3

    movlw   0b01100110                  ; [   B C     F G   ]
    movwf   0x14                        ; Use GP register 4 to store the digit 4

    movlw   0b10110110                  ; [ A   C D   F G   ]
    movwf   0x15                        ; Use GP register 5 to store the digit 5

    movlw   0b10111110                  ; [ A   C D E F G   ]
    movwf   0x16                        ; Use GP register 6 to store the digit 6

    movlw   0b11100000                  ; [ A B C           ]
    movwf   0x17                        ; Use GP register 7 to store the digit 7

    movlw   0b11111110                  ; [ A B C D E F G   ]
    movwf   0x18                        ; Use GP register 8 to store the digit 8

    movlw   0b11110110                  ; [ A B C D   F G   ]
    movwf   0x19                        ; Use GP register 9 to store the digit 9

    btfss   0x1a, 4
    goto    _no_decimal_point
    movlw   0x01
    addwf   0x10, F
    addwf   0x11, F
    addwf   0x12, F
    addwf   0x13, F
    addwf   0x14, F
    addwf   0x15, F
    addwf   0x16, F
    addwf   0x17, F
    addwf   0x18, F
    addwf   0x19, F

_no_decimal_point:
    movf    0x1a, W                     ; Copy file 0x1a in into W
    movwf   FSR                         ; Copy 0x1a to FSR
    movlw   0b00010000                  ; Ensure the indexing starts from 16 (GP regs)
    iorwf   FSR, F                      ;  by using IOR to commit results to file FSR

    movlw   8                           
    movwf   0x1a                        ; Use GP register A for loop counter

_data_loop:
    ; loops 1-7: 9 cycles
    ; loop  8  : 8 cycles
    ; 73 cycles total, including retlw
    bcf     GPIO, GPIO_GP0_POSITION     ; Clear GP0 (DATA = 0)

    btfsc   INDF, 0                     ; Check if the last bit in INDF (the register pointed to by FSR) is set
    bsf     GPIO, GPIO_GP0_POSITION     ; Set GP0 if last bit of INDF is set (DATA = 1)
    rrf     INDF, F                     ; Bit shift right GP register 0
        
                                        ;  -- PULSE CLOCK --
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)

    decfsz 0x1a, F
    goto _data_loop   

    retlw   0

; BINARY TO BCD modified from: http://www.piclist.com/techref/microchip/math/radix/b2bhp-8b3d.htm
; ******************************** 
; binary_to_bcd - 8-bits
; 
; Input
;   bin  - 8-bit binary number
;    A1*16+A0
; Outputs
;   hundreds - the hundreds digit of the BCD conversion
;   tens_and_ones - the tens and ones digits of the BCD conversion
; 

BINARY_TO_BCD:

    ; save needed constants
    movlw   0x16
    movwf   0x10

    movlw   0x06
    movwf   0x11

    movlw   -0x06
    movwf   0x12

    movlw   0x16 - 1 + 0x06
    movwf   0x13

    movlw   0x30
    movwf   0x14

    movlw   0x60
    movwf   0x15

    movlw   0x20
    movwf   0x16

    movlw   -0x60
    movwf   0x17

    clrf    hundreds
    swapf   bin, W                      ; swap the nibbles
    addwf   bin, W                      ; so we can add the upper to the lower
    andlw   0b00001111                  ; lose the upper nibble (W is in BCD from now on)
    
    skpndc                              ; if we carried a one (upper + lower > 16)
    addwf   0x10, W  ; (addlw 0x16)     ; add 16 (the place value) (1s + 16 * 10s)
    
    skpndc                              ; did that cause a carry from the 1's place?
    addwf   0x11, W  ; (addlw 0x06)     ; if so, add the missing 6 (carry is only worth 10)
    
    addwf   0x11, W  ; (addlw 0x06)     ; fix max digit value by adding 6
    
    skpdc                               ; if was greater than 9, DC (carry) will be set
    addwf   0x12, W  ; (addlw -0x06)    ; if if it wasn't, get rid of that extra 6
    
    btfsc   bin, 4                      ; 16's place
    addwf   0x13, W  ; (addlw 0x16-1+6) ; add 16 - 1 and check for digit carry
    
    skpdc
    addwf   0x12, W  ; (addlw -0x06)    ; if nothing carried, get rid of that 6
    
    btfsc   bin, 5                      ; 32nd's place
    addwf   0x14, W  ; (addlw 0x30)     ; add 32 - 2
    
    btfsc   bin, 6                      ; 64th's place
    addwf   0x15, W  ; (addlw 0x60)     ; add 64 - 4
    
    btfsc   bin, 7                      ; 128th's place
    addwf   0x16, W  ; (addlw 0x20)     ; add 128 - 8 % 100
    
    addwf   0x15, W  ; (addlw 0x60)     ; has the 10's place overflowed?
    rlf     hundreds, F                 ; pop carry in hundreds' LSB
    btfss   hundreds, 0                 ; if it hasn't
    addwf   0x17, W  ; (addlw -0x60)    ; get rid of that extra 60
    
    movwf   tens_and_ones               ; save result
    btfsc   bin, 7                      ; remeber adding 28 - 8 for 128?
    incf    hundreds, F                 ; add the missing 100 if bit 7 is set


    ; MODIFICATION: Display even values from 0 to 510 instead of integers 0-255
    ; basically multiply everything by 2

    ; we need to temporarily use register 0x10 to store our DC and C flags 
    ; (bits 1 and zero, respectively)
    
    clrf    0x10
    clrc                                ; clear carry
    rlf     hundreds, F                 ; hundreds = hundreds * 2
    
    movf    tens_and_ones, W            ; copy F to W
    addwf   tens_and_ones, W            ; W = F + W
    skpnc                               ; if carry
    bsf     0x10, 0                     ;  then set flag    
    skpndc                              ; if digit carry
    bsf     0x10, 1                     ;  then set flag

    btfsc   0x10, 0                     ; if carry
    addwf   0x15, W ; addlw 0x60        ;  then add 6 to tens digit
    btfsc   0x10, 0                     ; if carry
    incf    hundreds, F                 ;  then increment hundreds

    btfsc   0x10, 1                     ; if digit carry
    addwf   0x11, W ; addlw 0x06        ;  then add 6 to ones digit
    btfsc   0x10, 1                     ; if digit carry
    iorlw   16                          ;  then increment tens by adding 16/16

    addwf   0x11, W ; addlw 0x06        ; try adding 6 to ones place
    skpdc                               ; if that didn't cause a digit carry
    addwf   0x12, W ; addlw -0x06       ;  then remove the 6

    addwf   0x15, W ; addlw 0x60        ; try adding 6 to tens place
    skpnc                               ; if addwf caused a carry
    incf    hundreds, F                 ;  then increment hundreds
    skpc                                ; if addwf didn't cause a carry
    addwf   0x17, W ; addlw -0x60       ;  then remove the 6

    movwf   tens_and_ones

    retlw   0                           ; all done!


END resetVec

