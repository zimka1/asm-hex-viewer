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
;                       Plus 1 point: When paging, the absolute path of the displayed
;                        (processed) input file will always be shown. If it is longer
;                        than a line, it will be appropriately shortened in the middle.
;
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

; ==============================================================================================
; ==============================================================================================
;
; This code fragment opens a file for reading using the name stored in filename. 
; Then, it reads data from the file in 128-byte chunks and stores them in the save_data 
; buffer. If the file is empty or the end is reached, the program closes the file and 
; finishes processing. If reading is successful, the data is copied into the buffer, and 
; a null byte is added at the end to mark the end of the string. 
; If the file cannot be opened or read, the program jumps to error handling.
;
; ==============================================================================================
; ==============================================================================================


open_and_read_file:  
    print_line_feed_without_offset              ; Print a new line before processing the file

    ; Open the file
    mov ah, 3Dh                                 ; DOS function: Open file
    mov al, 0                                   ; Open for reading
    mov dx, offset filename                     ; Load the filename address
    int 21h                                     ; Call DOS interrupt
    jnc file_open                               ; If successful, go to store the file handle
    jmp error_handler                           ; If failed, jump to error handler

file_open:
    mov [file_handle], ax                       ; Store the file handle in memory

read_file:
    ; Read data from the file
    mov ah, 3Fh                                 ; DOS function: Read from file
    lea dx, [save_data]                         ; Load buffer address for storing data
    mov bx, [file_handle]                       ; Load the file handle
    mov cx, 128                                 ; Read up to 128 bytes
    int 21h                                     ; Call DOS interrupt
    jnc without_reading_problem                 ; If successful, go process what you read
    jmp error_handler                           ; If failed, jump to error handler

without_reading_problem:
    cmp ax, 0                                   ; Check if AX (bytes read) is 0 (end of file)
    jne it_isnt_end                             ; If not, continue processing
    jmp close_file                              ; If end of file, close the file and exit

it_isnt_end:
    lea si, [save_data]                         ; Load buffer address into SI
    mov cx, ax                                  ; Set CX to the number of bytes read
    mov di, si                                  ; Copy buffer address into DI
    add di, cx                                  ; DI now points to the end of the data
    mov byte ptr [di], 0                        ; Store null terminator at the end of the buffer

; ==============================================================================================
; ==============================================================================================
;
; This code fragment reads a file byte by byte and displays its contents in hexadecimal format.
; If a newline character is encountered, it checks whether a new page 
; should be created for paginated output. For each read byte, the offset counter is incremented, 
; and a procedure is called to print it in hexadecimal format. When the buffer is exhausted, 
; the program loads a new portion of data from the file. After processing the entire file, 
; it is closed, and if pagination is enabled, a new page is created before exiting.
;
; ==============================================================================================
; ==============================================================================================

read_loop:
    mov al, [si]                                ; Read a byte from the buffer
    cmp al, 00h                                 ; Check if it's a null terminator (end of buffer)
    je read_file                                ; If so, read more data from the file
    cmp al, 0Ah                                 ; Check if it's a newline character
    jne not_newline                             ; If not, continue processing the byte

    ; Handle newlines and paging
    cmp byte ptr paging_flag, 0                 ; If paging is disabled, continue normally
    je without_new_page
    cmp word ptr [number_of_lines], 20          ; Check if a new page is needed
    jb without_new_page
    make_new_page_with_filepath                 ; Create a new page and display the path, date and time

without_new_page:
    print_line_feed                             ; Print a newline character
    dec cx                                      ; Decrease the remaining character count
    jz end_loop                                 ; If no more characters, exit the loop
    jmp far ptr read_loop                       ; Continue reading the next byte

end_loop:
    jmp close_file                              ; Close the file after processing all data

not_newline:
    inc word ptr [file_offset]                  ; Increase the file offset
    push ax                                     ; Save AX register to avoid corruption

    cmp word ptr [file_offset], 1               ; If it's the first character, skip space
    jne continue_with_space
    jmp continue_without_space_or_new_page

continue_with_space:
    inc word ptr [characters_in_line]           ; Increase line character count
    print_space                                 ; Print a space between values
    page_monitoring                             ; Check if a new page is needed

continue_without_space_or_new_page:
    add word ptr [characters_in_line], 2        ; Update character count
    pop ax                                      ; Restore AX register
    call print_hex                              ; Print the byte in hex format
    inc si                                      ; Move to the next character
    dec cx                                      ; Decrease the character counter
    jz read_more_bytes                          ; If no more characters, read more data
    jmp read_loop                               ; Continue processing

read_more_bytes:
    jmp read_file                               ; Read the next block of data from the file

print_offset:
    ; Save registers to avoid corruption
    push ax
    push bx
    push cx
    mov ax, [file_offset]                       ; Load the current file offset
    call print_dec                              ; Print the offset in decimal format
    add word ptr [characters_in_line], cx       ; Update character count
    ; Restore registers
    pop cx
    pop bx
    pop ax
    inc si                                      ; Move to the next character
    ret

close_file:
    ; Close the currently opened file
    mov word ptr [file_offset], 0               ; Reset file offset
    mov ah, 3Eh                                 ; DOS function to close a file
    mov bx, [file_handle]                       ; Load the file handle
    int 21h                                     ; Call DOS interrupt

    cmp byte ptr [paging_flag], 0               ; If paging is disabled, return
    je return
    make_new_page_with_filepath                ; Create a new page before returning
return:
    ret                                         ; Return from the procedure


error_handler:
    print_text msg_error                        ; Displays the error message
    mov ax, 4C10h                               ; Terminates the program with an error
    int 21h                                     ; Calls DOS interrupt


.data   
filename db 64 dup(0)                                       ; Buffer to store the filename 
msg_error db 'Error opening file', 0Dh, 0Ah, '$'            ; Error message to display when a file cannot be opened
msg_filepath db 'Path: ', '$'                               ; Message prefix for displaying the file path
file_handle dw ?                                            ; The file handle
file_offset dw 0                                            ; The file's byte offset
characters_in_line dw 0                                     ; The number of characters in the current line
number_of_lines dw 0                                        ; The number of lines processed
paging_flag db, 0                                           ; The paging flag
save_data db 128 dup(0)                                     ; Data read from the file
help_message db 'Program Overview:', 0Dh, 0Ah
db 'This program reads files and displays their content in hexadecimal format.', 0Dh, 0Ah
db 'It can process multiple files specified as arguments and display their contents line by line.', 0Dh, 0Ah
db 'Each line starts with the offset of the first displayed value from the start of the file.', 0Dh, 0Ah
db '', 0Dh, 0Ah
db 'Usage instructions:', 0Dh, 0Ah
db 'To display help, use the "-h" flag.', 0Dh, 0Ah
db 'To enable paging, use the "-p" flag.', 0Dh, 0Ah
db 'To display help and enable paging, use the "-ph" or the "-hp" flag.', 0Dh, 0Ah
db 'Example usage:', 0Dh, 0Ah
db '    tasm main', 0Dh, 0Ah
db '    tasm hex', 0Dh, 0Ah
db '    tasm dec', 0Dh, 0Ah
db '    tasm date', 0Dh, 0Ah
db '    tlink main hex dec date', 0Dh, 0Ah
db '    main -hp file1.txt file2.txt', 0Dh, 0Ah
db '', 0Dh, 0Ah
db 'In this example, file1.txt and file2.txt will be processed with paging enabled.', 0Dh, 0Ah
db 'You can specify as many files as needed.', 0Dh, 0Ah
db '$'
msg_wait db 'Press any key to continue...', 0Dh, 0Ah, '$'   ; Message to ask press any key


.stack 100h

end START
