INCLUDE macros.inc

.8086
.model small

.code
START:
    mov ax, DGROUP
    mov ds, ax

    mov ah, 62h         ; Get PSP (Program Segment Prefix)
    int 21h
    mov es, bx          ; Store PSP in ES

    mov al, es:80h      ; Get the length of command-line arguments in AL
    or al, al
    jnz arg_not_null    ; If not zero, continue
    jmp far ptr error_handler ; Jump to error handler if no arguments

arg_not_null:
    mov cx, ax          ; CX = length of the argument string
    mov si, 81h         ; Start of arguments
    
parse_args:
    call skip_spaces     ; Skip spaces before arguments
    
    ; Check if the argument is "-h" or there are no arguments
    check_help_info

    ; Display help message
    print_text help_message
    
    inc si
    jmp parse_args   ; Continue processing the remaining arguments

process_filename:
    call copy_filename  ; Copy the filename
    call open_and_read_file  ; Open and read the file
    jmp parse_args      ; Look for the next argument

exit_program:
    mov ah, 4Ch
    int 21h             ; Exit the program

skip_spaces:
    ; Skips spaces in the arguments
    mov al, es:[si]
    cmp al, 32
    jne end_skip_spaces
    inc si
    jmp skip_spaces
end_skip_spaces:
    ret

copy_filename:
    ; Copies the filename (until a space or end of the line)
    mov di, offset filename
copy_loop:
    mov al, es:[si]
    cmp al, 32          ; Stop copying if a space is found
    je end_copy
    cmp al, 0Dh         ; Stop copying if Enter (end of arguments) is found
    je end_copy
    mov [di], al        ; Store the character in the filename buffer
    inc di
    inc si
    jmp copy_loop
end_copy:
    mov byte ptr [di], '$'  ; Add end terminator at the end
    ret

open_and_read_file:  

    print_line_feed

    print_text filename

    print_line_feed

    ; Open the file
    mov ah, 3Dh
    mov al, 0           ; Open for reading
    mov dx, offset filename 
    int 21h
    jnc file_open
    jmp far ptr error_handler ; Jump to error handler if no arguments


file_open:
    mov [file_handle], ax  ; Store file handle

read_file:
    mov bx, [file_handle]  ; Load file handle
    mov ah, 3Fh            ; Read function
    mov cx, 1              ; Read 1 byte
    mov dx, offset save_data
    int 21h                ; Call DOS

    test ax, ax            ; Check if end of file is reached
    jz close_file          ; If yes, close the file

    mov al, [save_data]

    cmp al, 0Ah ; If newline character, print offset
    je print_offset

    inc word ptr [file_offset] ; Increase the read byte count

    push ax ; Save AX on stack to avoid corruption when printing space

    cmp word ptr [file_offset], 1
    je continue_without_space ;
    print_space

continue_without_space:
    pop ax

    call convert_to_hex

    jmp read_file          ; Continue reading


print_offset:
    print_line_feed
    push ax
    mov ax, [file_offset]
    call convert_to_hex
    pop ax
    jmp read_file          ; Continue reading


convert_to_hex:
    push ax
    push bx
    push cx

    mov ah, al     ; Save byte in AH
    shr al, 4      ; Keep only the high nibble
    call convert_num

    mov al, ah     ; Restore original byte
    and al, 0Fh    ; Keep only the low nibble (0xAB → 0x0B)
    call convert_num
    
    pop cx
    pop bx
    pop ax
    ret

convert_num:
    push ax   ; Save AL
    and al, 0Fh    ; Keep only the lowest 4 bits
    add al, '0'    ; Convert 0–9 to '0'–'9'
    cmp al, '9'    
    jbe print_char 
    add al, 7h     ; Convert A–F (A=41h, B=42h, ...)

print_char:
    mov ah, 0Eh    ; BIOS function for character output
    int 10h
    pop ax   ; Restore AL
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
save_data db 16 dup(0)
help_message db 'Print the content of the input in hexadecimal format.', 0Dh, 0Ah
db 'At the beginning of each line, print the offset', 0Dh, 0Ah
db 'of the first displayed value from the start.', 0Dh, 0Ah, '$'

.stack 100h

end START
