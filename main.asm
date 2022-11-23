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
    ; DATA:  GP0
    ; CLOCK: GP1
    ; LATCH: GP2

    movlw   8                           
    movwf   0x1a                        ; Use GP register A for loop counter

    movlw   0b10110110                         
    movwf   0x10                        ; Use GP register 0 to store the digit 0

    bcf     GPIO, GPIO_GP2_POSITION     ; Clear GP2 (set LATCH to LOW) 

_data_loop:
    bcf     GPIO, GPIO_GP0_POSITION     ; Clear GP0 (DATA = 0)

    btfsc   0x10, 0                     ; Check if the last bit in GP reg 0 is set
    bsf     GPIO, GPIO_GP0_POSITION     ; Set GP0 if last bit of GP reg 0 is set (DATA = 1)
    rrf     0x10, F                     ; Bit shift right GP register 0
        
                                        ;  -- PULSE CLOCK --
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)

    decfsz 0x1a, F
    goto _data_loop   


    bsf     GPIO, GPIO_GP2_POSITION     ; Set GP2   (set LATCH to HIGH)
    goto    LOOP
    
END resetVec


