; Clears the terminal screen
clean_terminal MACRO
    mov ah, 06h                                 ; BIOS scroll function
    mov al, 00h                                 ; Scroll entire screen
    mov bh, 07h                                 ; Set text attribute (white text on black background)
    mov cx, 0                                   ; Upper-left corner
    mov dx, 184Fh                               ; Lower-right corner
    int 10h                                     ; Call BIOS interrupt to perform the scroll
ENDM


; Prints a single space character
print_space MACRO
    mov dl, ' '                                 ; Load space character into DL
    mov ah, 02h                                 ; DOS function to print a character
    int 21h                                     ; Call DOS interrupt to print the character
ENDM


; Prints a new line (line feed and carriage return) without displaying an offset
print_line_feed_without_offset MACRO
    mov dl, 0Ah                                 ; Line feed (LF) - moves the cursor to the next line
    mov ah, 02h                                 ; DOS function to print a character
    int 21h                                     ; Call DOS interrupt to print LF

    mov dl, 0Dh                                 ; Carriage return (CR) - moves the cursor to the beginning of the line
    int 21h                                     ; Call DOS interrupt to print CR
ENDM


; Prints a new line and updates line/offset tracking
print_line_feed MACRO
    mov word ptr [characters_in_line], 0        ; Reset character count for the new line
    inc word ptr [number_of_lines]              ; Increment the line counter
    print_line_feed_without_offset              ; Print a line feed (LF + CR)
    call print_offset                           ; Print the current offset at the beginning of the new line
ENDM


; Prints a given text string
; Parameters:
;   text - The address of the null-terminated string to print
print_text MACRO text
    mov dx, offset text                         ; Load the address of the string into DX
    mov ah, 09h                                 ; DOS function to print a string
    int 21h                                     ; Call DOS interrupt to display the text
ENDM


; Checks if the "-h" (help) or "-p" (paging) argument is provided
check_flags MACRO
    cmp byte ptr es:[si], 0Dh                   ; Check if we reached the end of arguments
    jne start_check_flags
    jmp far ptr exit_program                    ; If no more arguments, exit

start_check_flags:
    cmp byte ptr es:[si], '-'                   ; Check if the argument starts with '-'
    je check_letter
    jmp far ptr process_filename                ; If not a flag, process it as a filename

check_letter:
    inc si
    cmp byte ptr es:[si], 'h'                   ; Check if it's the '-h' flag (help)
    jne continue_check_flags
    call print_help_message                     ; Print help message
    jmp check_second_flag                       ; Check if another flag follows

continue_check_flags:
    cmp byte ptr es:[si], 'p'                   ; Check if it's the '-p' flag (paging)
    jne parse_args
    call set_paging_flag                        ; Enable paging mode

check_second_flag:
    inc si
    cmp byte ptr es:[si], 'h'                   ; Check again if '-h' is present
    jne continue_check_second_flag
    call print_help_message                     ; Print help message again if necessary
    jmp got_flags

continue_check_second_flag:
    cmp byte ptr es:[si], 'p'                   ; Check again if '-p' is present
    jne parse_args
    call set_paging_flag                        ; Enable paging mode

got_flags:
    inc si
    jmp parse_args                              ; Continue parsing remaining arguments
ENDM


; ==============================================================================================
; Page monitoring
; ==============================================================================================
;
; Paging limits the number of lines per page to 20 and the number of characters per line to 70.
; When this limit is reached, a new page is created, and the program waits 
; for a key press to continue. If paging is disabled, the text is printed without breaks. 
; When a page break occurs, the screen is cleared, and before continuing the output, 
; the file path, as well as the current date and time, are displayed again. 
; This makes it easier to view long files.
;
; ==============================================================================================
; ==============================================================================================

; Monitors line width and handles new page transitions
page_monitoring MACRO
    cmp word ptr [characters_in_line], 70       ; Check if line exceeds 70 characters
    jnbe check_flag                             ; If greater, check the paging flag
    jmp far ptr continue_without_space_or_new_page ; Otherwise, continue normal processing

check_flag:
    cmp byte ptr paging_flag, 0                 ; If paging mode is disabled, just break the line
    je continue_only_with_line_feed

    cmp word ptr [number_of_lines], 20          ; If the number of lines reaches 20, create a new page
    jb continue_only_with_line_feed
    jmp continue_with_new_page_and_new_line

continue_only_with_line_feed:                   ; Move to a new line and continue
    print_line_feed
    print_space
    jmp continue_without_space_or_new_page

continue_with_new_page_and_new_line:            ; Create a new page before continuing
    make_new_page_with_filepath
    print_line_feed
    print_space
ENDM

; Creates a new page and waits for user input
make_new_page MACRO
    mov word ptr [characters_in_line], 0
    mov word ptr [number_of_lines], 0
    print_line_feed_without_offset
    print_text msg_wait                         ; Display "Press any key to continue..."
    call print_date                             ; Print the current date
    mov ah, 00h
    int 16h                                     ; Wait for a key press
    push bx
    push cx
    push dx
    clean_terminal                              ; Clear the terminal screen
    pop dx
    pop cx
    pop bx
ENDM

; Creates a new page and prints the file path before continuing
make_new_page_with_filepath MACRO
    print_line_feed_without_offset
    print_text msg_filepath               ; Display "Path: "
    print_text filename                    ; Print the current filename
    make_new_page
ENDM

