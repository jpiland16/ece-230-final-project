; MODIFIED FROM http://www.piclist.com/techref/microchip/math/div/16by8lz.htm

#define bf_carry 3, 0
#define bf_zero 3, 2

#define same 1

#define stc bsf bf_carry
#define clc bcf bf_carry

#define f_divhi 0x10
#define f_divlo 0x11
#define f_divsr 0x12

;-[ Div ]--------------------------------------------------------------
; Call w/: Number in f_divhi:f_divlo, divisor in f_divsr.
; Returns: Quotient in f_divlo, remainder in f_divhi. W set to 0.
;          Carry set if error. Z if divide by zero, NZ if divide overflow.
; Notes:   Works by left shifted subtraction.
;          ** SPEED MAY DIFFER, modifications made by Jonathan Piland, 11/26/22.
;          Size = 29, Speed(w/ call&ret) = 7 cycles if div by zero
;          Speed = 94 minimum, 129 maximum cycles

    call Div
    goto END

Div;

    movlw 8
    movwf 0x13       ; used for loop later

    movlw 0
    addwf f_divsr, W ; w = divisor + 0 (to test for div by zero and move F to W)
    stc              ; set carry in case of error
    btfsc bf_zero    ; if zero
     retlw 0         ;   return (error C,Z)

    call DivSkipHiShift

_div_loop:

    movf f_divsr, W ; because we constantly write the literal 0 to W

    call DivCode

    decfsz 0x13, F
     goto _div_loop

    rlf f_divlo, same ; C << lo << C

    ; If the first subtract didn't underflow, and the carry was shifted
    ; into the quotient, then it will be shifted back off the end by this
    ; last RLF. This will automatically raise carry to indicate an error.
    ; The divide will be accurate to quotients of 9-bits, but past that
    ; the quotient and remainder will be bogus and carry will be set.

    bcf bf_zero  ; NZ (in case of overflow error)
    retlw 0      ; we are done!

DivCode
    rlf f_divlo, same    ; C << lo << C
    rlf f_divhi, same    ; C << hi << C
    btfss bf_carry       ; if Carry
     goto DivSkipHiShift ;
    subwf f_divhi, same  ;   hi-=w
    stc                  ;   ignore carry
    retlw 0              ;   done
                         ; endif
DivSkipHiShift
    subwf f_divhi, same  ; hi-=w
    btfsc bf_carry       ; if carry set
     retlw 0             ;   done
    addwf f_divhi, same  ; hi+=w
    clc                  ; clear carry
    retlw 0              ; done

END
    movlw 0