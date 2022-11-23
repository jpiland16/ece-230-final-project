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
    bcf     GPIO, GPIO_GP2_POSITION     ; Clear GP2 (set LATCH to LOW) 
    
    bsf     GPIO, GPIO_GP0_POSITION     ; Set GP0    (DATA = 1)
    
                                        ;  -- PULSE CLOCK --
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)
    
                                        ;  -- PULSE CLOCK -- 2
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)
    
                                        ;  -- PULSE CLOCK -- 3
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)
    
                                        ;  -- PULSE CLOCK -- 4
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)
    
                                        ;  -- PULSE CLOCK -- 5
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)

    bcf     GPIO, GPIO_GP0_POSITION     ; Clear GP0 (DATA = 0)
    
                                        ;  -- PULSE CLOCK -- 6
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)
    
                                        ;  -- PULSE CLOCK -- 7
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)
    
                                        ;  -- PULSE CLOCK -- 8
    bsf     GPIO, GPIO_GP1_POSITION     ; Set GP1   (set CLOCK to HIGH)
    bcf     GPIO, GPIO_GP1_POSITION     ; Clear GP1 (set CLOCK to LOW)
    
    bsf     GPIO, GPIO_GP2_POSITION     ; Set GP2   (set LATCH to HIGH)
    goto    LOOP
    
END resetVec


