; ==============================================================================================
; ==============================================================================================
; 
; Task:     Number 5
; Author:   Aliaksei Zimnitski
;
; Task (10 points):     Print the input content in hexadecimal format. 
;                       At the beginning of each line, print the offset 
;                       of the first value being printed from the beginning.
; Tasks (5 points):
;                       Plus 2 points can be earned if the task is implemented 
;                        as an external procedure (compiled separately and linked 
;                        to the final program).
;                       Plus 2 points: If multiple input files can be specified.
;                       Plus 1 point: When the '-p' switch is entered, the output 
;                        should be paginated, meaning after the screen is filled, 
;                        the program will wait for a key press.
; Bonuses (3 points):
;                       Plus 1 point: During pagination, the current date and time 
;                        should always be displayed.
;                       Plus 1 point can be earned for (good) comments or documentation 
;                        in English.
; Date:     26.02.2025
;
; Academic year:    2
; Semester:         4
; Field of study:   informatika
;
; ==============================================================================================
; ==============================================================================================
INCLUDE macros.inc

.8086
.model small

.code
EXTRN print_hex:near
EXTRN print_date:near
EXTRN print_dec:near

START:
    mov ax, @data                               ; Load data segment address into AX
    mov ds, ax                                  ; Move AX into DS to set the data segment

    clean_terminal                              ; Call a procedure to clean the terminal screen

; ==============================================================================================
; ==============================================================================================
;
; This code fragment processes command-line arguments, which are retrieved from 
; the Program Segment Prefix (PSP), where flags come first, followed by filenames. 
; The program first checks the flags (e.g., -h for help or -p for paging). Then, 
; for each filename, the program copies it into a buffer, opens the file, reads its content, 
; and processes it. Only after completing the processing of the current file does the program 
; move on to the next file in the argument list.
;
; ==============================================================================================
; ==============================================================================================



    ; Get PSP (Program Segment Prefix)
    mov ah, 62h                                 ; DOS function: Get Program Segment Prefix (PSP)
    int 21h                                     ; Call DOS interrupt 21h
    mov es, bx                                  ; Store the value of PSP segment into ES

    ; Get the length of command-line arguments
    mov al, es:80h                              ; Load the length of command-line arguments into AL
    or al, al                                   ; Check if AL is zero (no arguments provided)
    jnz arg_not_null                            ; If arguments exist, jump to arg_not_null
    jmp error_handler                           ; If no arguments, jump to error handler

arg_not_null:
    mov cx, ax                                  ; Store the length of the argument string in CX
    mov si, 81h                                 ; Set SI to the start of arguments (in the PSP)

parse_args:
    call skip_spaces                            ; Call procedure to skip leading spaces

    check_flags                                 ; Check if the "-h" (help) or "-p" (paging) argument is present

print_help_message:
    print_text help_message                     ; Print the help message
    make_new_page                               ; Make a new page (for paging)
    ret

set_paging_flag:
    mov byte ptr paging_flag, 1                 ; Set the paging flag to 1
    ret

process_filename:
    call copy_filename                          ; Copy the filename from arguments to filename buffer
    push si                                     ; Push SI to stack to preserve it
    call open_and_read_file                     ; Open and read the file
    pop si                                      ; Restore SI from stack
    jmp parse_args                              ; Continue parsing other arguments

exit_program:
    mov ah, 4Ch                                 ; DOS function to terminate the program
    int 21h                                     ; Call DOS interrupt to exit the program

skip_spaces:
    ; Skips spaces in the argument string
    mov al, es:[si]                             ; Load the current character into AL
    cmp al, 32                                  ; Compare it with the ASCII value of space (32)
    jne end_skip_spaces                         ; If it's not space, exit the loop
    inc si                                      ; Move to the next character
    jmp skip_spaces                             ; Repeat the process

end_skip_spaces:
    ret                                         ; Return from skip_spaces procedure

copy_filename:
    ; Copies the filename (stops at space or end of line)
    mov di, offset filename                     ; Set DI to the beginning of the filename buffer
copy_loop:
    mov al, es:[si]                             ; Load the current character into AL
    cmp al, 32                                  ; Compare it with space (ASCII 32)
    je end_copy                                 ; If space is encountered, stop copying
    cmp al, 0Dh                                 ; Compare it with Enter (ASCII 0Dh)
    je end_copy                                 ; If Enter is encountered, stop copying
    mov [di], al                                ; Store the character in the filename buffer
    inc di                                      ; Move to the next position in the filename buffer
    inc si                                      ; Move to the next character in the argument string
    jmp copy_loop                               ; Repeat copying

end_copy:
    mov byte ptr [di], '$'                      ; Add string terminator ('$') to mark the end of the filename
    ret                                         ; Return from copy_filename procedure




open_and_read_file:  
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
    mov di, si           ; Копируем адрес буфера в DI
    add di, cx           ; DI = адрес конца данных
    mov byte ptr [di], 0 ; Записываем нулевой байт

read_loop:
    mov al, [si]       ; Read byte
    cmp al, 00h
    je read_file
    cmp al, 0Ah        ; If newline character, print offset
    jne not_newline
    cmp byte ptr paging_flag, 0 ; If paging flag is 0, then we dont need pages
    je without_new_page
    cmp word ptr [number_of_lines], 20 ; Check if page break is needed
    jb without_new_page
    make_new_page_with_file_name
without_new_page:
    print_line_feed
    dec cx
    jz end_loop
    jmp far ptr read_loop
end_loop:
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
    call print_dec
    add word ptr [characters_in_line], cx
    pop cx
    pop bx
    pop ax
    inc si
    ret


close_file:
    ; Close the file
    mov word ptr [file_offset], 0
    mov ah, 3Eh
    mov bx, [file_handle]
    int 21h
    cmp byte ptr [paging_flag], 0
    je return
    make_new_page_with_file_name
return:
    ret

error_handler:
    print_text msg_error
    mov ax, 4C10h
    int 21h

.data   
filename db 64 dup(0)
msg_error db 'Error opening file', 0Dh, 0Ah, '$'
msg_filename db 'Path: ', '$'
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
