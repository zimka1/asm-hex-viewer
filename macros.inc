; Clears the terminal screen
clean_terminal MACRO
    mov ah, 06h
    mov al, 00h 
    mov bh, 07h 
    mov cx, 0
    mov dx, 184Fh 
    int 10h         
ENDM

; Prints a single space character
print_space MACRO
    mov dl, ' '
    mov ah, 02h  
    int 21h 
ENDM

; Prints a new line without an offset
print_line_feed_without_offset MACRO
    mov dl, 0Ah  ; Line feed (LF)
    mov ah, 02h
    int 21h

    mov dl, 0Dh  ; Carriage return (CR)
    int 21h
ENDM

; Prints a new line and updates line/offset tracking
print_line_feed MACRO
    mov word ptr [characters_in_line], 0
    inc word ptr [number_of_lines]
    print_line_feed_without_offset
    call print_offset
ENDM

; Prints a given text string
print_text MACRO text
    mov dx, offset text
    mov ah, 09h
    int 21h
ENDM

; Checks if the "-h" (help) argument is provided
check_flags MACRO
    cmp byte ptr es:[si], 0Dh
    jne start_check_flags
    jmp far ptr exit_program      ; If no more arguments, exit

start_check_flags:
    cmp byte ptr es:[si], '-'  ; Check if the argument starts with '-'
    jne process_filename

    inc si
    cmp byte ptr es:[si], 'h'  ; Check if it's the '-h' flag
    jne continue_check_flags
    call print_help_message
    jmp check_second_flag

continue_check_flags:
    cmp byte ptr es:[si], 'p' ; Check if it's the '-p' flag
    jne parse_args
    call set_paging_flag

check_second_flag:
    inc si
    cmp byte ptr es:[si], 'h'  ; Check if it's the '-h' flag
    jne continue_check_second_flag
    call print_help_message
    jmp got_flags

continue_check_second_flag:
    cmp byte ptr es:[si], 'p' ; Check if it's the '-p' flag
    jne parse_args
    call set_paging_flag

got_flags:
    inc si
    jmp parse_args   ; Continue parsing arguments
ENDM

; Monitors line width and handles new page transitions
page_monitoring MACRO
    cmp word ptr [characters_in_line], 70  ; Check if line exceeds 70 chars
    jnbe check_flag
    jmp far ptr continue_without_space_or_new_page

check_flag:
    cmp byte ptr paging_flag, 0 ; If paging flag is 0, then we dont need pages
    je continue_only_with_line_feed

    cmp word ptr [number_of_lines], 21  ; If near page limit, handle accordingly
    jb continue_only_with_line_feed
    jmp continue_with_new_page_and_new_line

continue_only_with_line_feed:  ; Move to a new line and continue
    print_line_feed
    print_space
    jmp continue_without_space_or_new_page

continue_with_new_page_and_new_line:  ; Create a new page before the next line
    make_new_page
    print_line_feed
    print_space
ENDM

; Creates a new page and waits for user input
make_new_page MACRO
    mov word ptr [characters_in_line], 0
    mov word ptr [number_of_lines], 0
    print_line_feed_without_offset
    print_text msg_wait
    mov ah, 00h
    int 16h  ; Wait for a key press
    push bx
    push cx
    push dx
    clean_terminal
    pop dx
    pop cx
    pop bx
ENDM
