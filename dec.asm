INCLUDE macros.inc

.8086
.model small
PUBLIC print_dec
.code


; ==============================================================================================
; Decimal Number Output
; ==============================================================================================
;
; This code implements the print_dec procedure, which prints a number in decimal format. 
; First, the number is divided by 10 in the convert_loop, and the remainders (digits) 
; are stored in the stack. The division continues until the quotient becomes zero. 
; Then, in the print_loop, the digits are retrieved from the stack in reverse order 
; and printed using DOS interrupt 21h (function 02h). As a result, the number is displayed 
; from left to right, even though division produces digits in reverse order.
;
; ==============================================================================================
; ==============================================================================================


print_dec PROC
    
print_number:
    mov bx, 10                                  ; Divider (for decimal output)
    mov cx, 0                                   ; Digit counter (number of characters)

convert_loop:
    mov dx, 0                                   ; Clear higher part for div
    div bx                                      ; AX / 10 → AX = quotient, DX = remainder
    add dl, '0'                                 ; Convert remainder to ASCII character
    push dx                                     ; Save digit onto the stack
    inc cx                                      ; Increase digit counter
    test ax, ax                                 ; Check if quotient is 0
    jnz convert_loop                            ; If not 0, continue dividing

print_loop:
    pop dx                                      ; Retrieve character from stack
    mov ah, 02h                                 ; Function to print a character
    int 21h                                     ; Print character
    loop print_loop                             ; Repeat while cx > 0
    ret



print_dec ENDP

.data

.stack 100h

END