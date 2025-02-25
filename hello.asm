INCLUDE macros.inc

.8086
.model small

.code
EXTRN print_hex:near

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
    push si
    call open_and_read_file  ; Open and read the file
    pop si
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
    mov ah, 3Fh                ; Функция чтения
    lea dx, [save_data]       ; Адрес буфера
    mov bx, [file_handle]      ; Загружаем дескриптор файла
    mov cx, 128               ; Читаем 128 байт
    int 21h              ; Call DOS
    jc error_handler

    cmp ax, 0                  ; AX == 0 (конец файла)?
    je close_file              ; Если да, закрываем файл


    lea si, [save_data]  ; Загружаем адрес буфера
    mov cx, ax         ; Количество прочитанных байтов

read_loop:
    mov al, [si]       ; Читаем байт

    cmp al, 0Ah ; If newline character, print offset
    je print_offset

    inc word ptr [file_offset] ; Increase the read byte count

    push ax ; Save AX on stack to avoid corruption when printing space

    cmp word ptr [file_offset], 1
    je continue_without_space ;
    print_space

continue_without_space:

    pop ax

    call print_hex

    inc si

    loop read_loop

    jmp read_file


print_offset:
    print_line_feed
    push ax
    mov ax, [file_offset]
    call print_hex
    pop ax
    inc si
    loop read_loop


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
save_data db 128 dup(0)
help_message db 'Print the content of the input in hexadecimal format.', 0Dh, 0Ah
db 'At the beginning of each line, print the offset', 0Dh, 0Ah
db 'of the first displayed value from the start.', 0Dh, 0Ah, '$'

.stack 100h

end START