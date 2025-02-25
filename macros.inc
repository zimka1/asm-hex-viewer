print_space MACRO
    mov dl, ' '
    mov ah, 02h  
    int 21h 
ENDM

print_line_feed MACRO
    mov dl, 0Ah  
    mov ah, 02h
    int 21h

    mov dl, 0Dh  
    int 21h
ENDM


print_text MACRO text
    mov dx, offset text
    mov ah, 9
    int 21h
ENDM

check_help_info MACRO
    cmp byte ptr es:[si], 0Dh
    je exit_program      ; If there are no more arguments, exit

    cmp byte ptr es:[si], '-'  ; Check if the argument starts with '-'
    jne process_filename

    inc si
    cmp byte ptr es:[si], 'h'  ; Check if it's the '-h' flag
    jne parse_args
ENDM