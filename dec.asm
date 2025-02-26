INCLUDE macros.inc

.8086
.model small
PUBLIC print_dec
.code

print_dec PROC
    
print_number:
    mov bx, 10          ; Divider (for decimal output)
    mov cx, 0           ; Digit counter (number of characters)

convert_loop:
    mov dx, 0           ; Clear higher part for div
    div bx              ; AX / 10 → AX = quotient, DX = remainder
    add dl, '0'         ; Convert remainder to ASCII character
    push dx             ; Save digit onto the stack
    inc cx              ; Increase digit counter
    test ax, ax         ; Check if quotient is 0
    jnz convert_loop    ; If not 0, continue dividing

print_loop:
    pop dx              ; Retrieve character from stack
    mov ah, 02h         ; Function to print a character
    int 21h             ; Print character
    loop print_loop     ; Repeat while cx > 0
    ret



print_dec ENDP

.data

.stack 100h

END