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

print_line_feed_without_offset MACRO
    mov dl, 0Ah  
    mov ah, 02h
    int 21h

    mov dl, 0Dh  
    int 21h
ENDM

print_line_feed MACRO
    mov word ptr [characters_in_line], 0
    inc word ptr [number_of_lines]
    print_line_feed_without_offset
    call print_offset
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
    cmp word ptr [characters_in_line], 70
    jbe continue_without_space_or_new_page
    cmp word ptr [number_of_lines], 22 ; Если перенос строки прям перед новой страницей, то мы перенесем строку на следующую страницу
    jb continue_only_with_line_feed
    jmp continue_with_new_page_and_new_line
continue_only_with_line_feed: ; перенесём строку и сразу продолжим разбирать символы
    print_line_feed
    print_space
    jmp far ptr continue_without_space_or_new_page
continue_with_new_page_and_new_line: ; сделаем новую страницу и уже там будет ожидать новая строка
    make_new_page
    print_line_feed
    print_space
ENDM

make_new_page MACRO
    mov word ptr [characters_in_line], 0
    mov word ptr [number_of_lines], 0
    print_line_feed_without_offset
    print_text msg_wait
    mov ah, 00h
    int 16h  ; wait_for_key
ENDM