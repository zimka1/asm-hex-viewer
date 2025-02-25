print_space MACRO
    mov dl, ' '  ; выводим разделительный пробел
    mov ah, 02h  
    int 21h 
ENDM

print_line_feed MACRO
    mov dl, 0Ah   ; выводим код символа новой строки
    mov ah, 02h
    int 21h

    mov dl, 0Dh   ; выводим код возврата каретки
    int 21h
ENDM

