    PROCESSOR    10F200
#include <xc.inc>
    config WDTE  = OFF ; Disable watchdog timer
    config CP    = OFF ; Disable code protection
    config MCLRE = OFF ; Disable reset functionality of GPIO3
    PSECT resetVec,class=CODE,delta=2,abs
resetVec:
INIT:
    movlw   ~(1 << 5)            ; Enable GPIO2 by disabling T0CS = 5th bit
    option                ; and copy this value into OPTION register
    movlw   11111000B            ; turn on GPIO 0, 1, and 2
    tris    GPIO            ; Copy W into GPIO tristate register

LOOP:

    bcf     GPIO, GPIO_GP2_POSITION     ; Clear GP2 (set LATCH to LOW) 

    movlw   0x02
    movwf   0x1a                         ; Set 0x1a to desired digit
    call    DISPLAY_DIGIT
    
    movlw   0x13
    movwf   0x1a                         ; Set 0x1a to desired digit
    call    DISPLAY_DIGIT

    movlw   0x04
    movwf   0x1a                         ; Set 0x1a to desired digit
    call    DISPLAY_DIGIT

    bsf     GPIO, GPIO_GP2_POSITION     ; Set GP2   (set LATCH to HIGH)

    goto    LOOP

DISPLAY_DIGIT:

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
    movf    0x1a, W
    movwf   FSR
    movlw   0b00010000
    iorwf   FSR, F

    movlw   8                           
    movwf   0x1a                        ; Use GP register A for loop counter

_data_loop:
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
    
END resetVec


