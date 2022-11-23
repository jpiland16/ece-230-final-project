    PROCESSOR	10F200
#include <xc.inc>
    config WDTE  = OFF ; Disable watchdog timer
    config CP    = OFF ; Disable code protection
    config MCLRE = OFF ; Disable reset functionality of GPIO3
    PSECT resetVec,class=CODE,delta=2,abs
resetVec:
INIT:
    movlw  ~(1 << 5)                  ; Enable GPIO2 by disabling T0CS = 5th bit
    option                            ; and copy this value into OPTION register
    movlw  11111001B                  ; turn on GPIO 1 and 2
    tris   GPIO                       ; Copy W into GPIO tristate register
LOOP:
    bsf    GPIO, GPIO_GP1_POSITION    ; Set GP1's bit to 1 (turn ON  GP1)
    bcf    GPIO, GPIO_GP2_POSITION    ; Set GP1's bit to 0 (turn ON  GP1)
    call   DELAY
    bcf    GPIO, GPIO_GP1_POSITION    ; Set GP1's bit to 0 (turn OFF GP1)
    bsf    GPIO, GPIO_GP2_POSITION    ; Set GP1's bit to 1 (turn ON  GP1)
    call   DELAY
    goto   LOOP
DELAY:
    movlw  0
    movwf  0x10
    movlw  81
    movwf  0x11
DELAY_LOOP:
    decfsz 0x10, F
    goto   DELAY_LOOP
    decfsz 0x11, F
    goto   DELAY_LOOP
    retlw 0
    
END resetVec


