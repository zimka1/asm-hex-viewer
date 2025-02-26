INCLUDE macros.inc

.8086
.model small

.code
EXTRN print_hex:near

START:
    mov ax, DGROUP
    mov ds, ax

    clean_terminal

    ; Get PSP (Program Segment Prefix)
    mov ah, 62h
    int 21h
    mov es, bx

    ; Get the length of command-line arguments
    mov al, es:80h
    or al, al
    jnz arg_not_null
    jmp error_handler   ; Error if no arguments are provided

arg_not_null:
    mov cx, ax          ; CX = length of the argument string
    mov si, 81h         ; Start of arguments
    
parse_args:
    call skip_spaces     ; Skip leading spaces
    
    ; Check if the "-h" (help) or the "-p"(paging) argument is present
    check_flags

print_help_message:
    print_text help_message
    make_new_page
    ret

set_paging_flag:
    mov byte ptr paging_flag, 1
    ret


process_filename:
    call copy_filename      ; Copy the filename from arguments
    push si
    call open_and_read_file ; Open and read the file
    pop si
    jmp parse_args          ; Continue parsing other arguments

exit_program:
    mov ah, 4Ch
    int 21h                 ; Terminate program

skip_spaces:
    ; Skips spaces in the argument string
    mov al, es:[si]
    cmp al, 32
    jne end_skip_spaces
    inc si
    jmp skip_spaces
end_skip_spaces:
    ret

copy_filename:
    ; Copies the filename (stops at space or end of line)
    mov di, offset filename
copy_loop:
    mov al, es:[si]
    cmp al, 32          ; Stop copying at space
    je end_copy
    cmp al, 0Dh         ; Stop copying at Enter (end of arguments)
    je end_copy
    mov [di], al        ; Store the character in filename buffer
    inc di
    inc si
    jmp copy_loop
end_copy:
    mov byte ptr [di], '$'  ; Add string terminator
    ret

open_and_read_file:  
    print_line_feed_without_offset
    print_text filename
    inc word ptr [number_of_lines]
    print_line_feed_without_offset

    ; Open the file
    mov ah, 3Dh
    mov al, 0           ; Open for reading
    mov dx, offset filename 
    int 21h
    jnc file_open
    jmp error_handler   ; Jump to error handler if file can't be opened

file_open:
    mov [file_handle], ax  ; Store file handle

read_file:
    mov ah, 3Fh         ; Read file function
    lea dx, [save_data] ; Address of buffer
    mov bx, [file_handle] ; Load file descriptor
    mov cx, 128         ; Read 128 bytes
    int 21h
    jnc without_reading_problem
    jmp error_handler   ; Jump to error handler if read fails

without_reading_problem:
    cmp ax, 0           ; AX == 0 (end of file)?
    jne it_isnt_end
    jmp close_file      ; Close file if end reached

it_isnt_end:
    lea si, [save_data]  ; Load buffer address
    mov cx, ax         ; Set bytes read count

read_loop:
    mov al, [si]       ; Read byte
    cmp al, 00h
    je read_file
    cmp al, 0Ah        ; If newline character, print offset
    jne not_newline
    cmp byte ptr paging_flag, 0 ; If paging flag is 0, then we dont need pages
    je without_new_page
    cmp word ptr [number_of_lines], 21 ; Check if page break is needed
    jb without_new_page
    make_new_page
without_new_page:
    print_line_feed
    dec cx
    jnz read_loop
    jmp close_file

not_newline:
    inc word ptr [file_offset] ; Increase read byte count
    push ax                   ; Save AX on stack to avoid corruption
    cmp word ptr [file_offset], 1
    jne continue_with_space
    jmp continue_without_space_or_new_page

continue_with_space:
    inc word ptr [characters_in_line]
    print_space
    page_monitoring

continue_without_space_or_new_page:
    add word ptr [characters_in_line], 2
    pop ax
    call print_hex
    inc si
    dec cx
    jz read_more_bytes
    jmp read_loop

read_more_bytes:
    jmp read_file

print_offset:
    push ax
    push bx
    push cx
    mov ax, [file_offset]
    call print_number
    add word ptr [characters_in_line], cx
    pop cx
    pop bx
    pop ax
    inc si
    ret

print_number:
    mov bx, 10          ; Divider (for decimal output)
    mov cx, 0           ; Digit counter (number of characters)

convert_loop:
    mov dx, 0           ; Clear higher part for division
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

close_file:
    ; Close the file
    mov word ptr [file_offset], 0
    mov ah, 3Eh
    mov bx, [file_handle]
    int 21h
    ret

error_handler:
    print_text msg_error
    mov ax, 4C10h
    int 21h

.data   
filename db 64 dup(0)
msg_error db 'Error opening file', 0Dh, 0Ah, '$'
file_handle dw ?
file_offset dw 0
characters_in_line dw 0
number_of_lines dw 0
paging_flag db, 0
save_data db 128 dup(0)
help_message db 'Print the content of the input in hexadecimal format.', 0Dh, 0Ah
db 'At the beginning of each line, print the offset', 0Dh, 0Ah
db 'of the first displayed value from the start.', 0Dh, 0Ah, '$'
msg_wait db 'Press any key to continue...', 0Dh, 0Ah, '$'

.stack 100h

end START
