clean_terminal MACRO
    mov ah, 06h
    mov al, 00h 
    mov bh, 07h 
    mov cx, 0
    mov dx, 184fh 
    int 10h         
ENDM

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


page_monitoring MACRO
    cmp word ptr [characters_in_line], 75
    jbe continue_without_space_or_new_page
    print_line_feed
    mov word ptr [characters_in_line], 0
    inc word ptr [number_of_lines]
    cmp word ptr [number_of_lines], 20
    jb continue_without_space_or_new_page

new_page:
    mov word ptr [characters_in_line], 0
    mov word ptr [number_of_lines], 0
    print_line_feed
    print_text msg_wait
    mov ah, 00h
    int 16h  ; wait_for_key
ENDM
    