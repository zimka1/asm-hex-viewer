INCLUDE macros.inc

.8086
.model small
PUBLIC print_date
.code

; ==============================================================================================
; ==============================================================================================
;
; This code retrieves the system date and time using DOS interrupts (21h), 
; then displays them in the format "Date: YYYY-MM-DD" and "Time: HH:MM:SS". 
; It stores the year, month, day, hour, minute, and second values in variables. 
; To correctly display the data, dashes and colons are printed between 
; the date and time elements. To convert the 8-bit values (month, day, hour, minute, second) 
; into 16-bit values, the `cbw` instruction is used, which extends the byte into a word, 
; as the `print_dec` function expects 16-bit data. 
; The procedure ends by returning control to the calling process.
;
; ==============================================================================================
; ==============================================================================================


EXTRN print_dec:near

print_date PROC
start:
    ; Get the current date using DOS interrupt 21h with function 2Ah
    mov ah, 2Ah                                 ; DOS: Get system date
    int 21h
    mov year, cx                                ; Store the year in 'year' variable
    mov month, dh                               ; Store the month in 'month' variable
    mov day, dl                                 ; Store the day in 'day' variable

    ; Get the current time using DOS interrupt 21h with function 2Ch
    mov ah, 2Ch                                 ; DOS: Get system time
    int 21h
    mov hour, ch                                ; Store the hour in 'hour' variable
    mov minute, cl                              ; Store the minute in 'minute' variable
    mov second, dh                              ; Store the second in 'second' variable

    print_text date_msg                         ; Print the text "Date: "

    ; Print the year
    mov ax, year
    call print_dec                              ; Print the year using the 'print_dec' function

    ; Print a hyphen between year and month
    mov dl, '-'
    mov ah, 02h
    int 21h

    ; Print the month
    mov al, month
    cbw                                         ; Convert byte to word for correct printing
    call print_dec

    ; Print a hyphen between month and day
    mov dl, '-'
    mov ah, 02h
    int 21h

    ; Print the day
    mov al, day
    cbw                                         ; Convert byte to word for correct printing
    call print_dec

    print_line_feed_without_offset              ; Print a new line after the date
    
    print_text time_msg                         ; Print the text "Time: "

    ; Print the hour
    mov al, hour
    cbw                                         ; Convert byte to word for correct printing
    call print_dec

    ; Print a colon between hour and minute
    mov dl, ':'
    mov ah, 02h
    int 21h

    ; Print the minute
    mov al, minute
    cbw                                         ; Convert byte to word for correct printing
    call print_dec

    ; Print a colon between minute and second
    mov dl, ':'
    mov ah, 02h
    int 21h

    ; Print the second
    mov al, second
    cbw                                         ; Convert byte to word for correct printing
    call print_dec

    ret                                         ; Return from the procedure

print_date ENDP

.data
    date_msg db 'Date: ', '$'                   ; Message before printing the date
    time_msg db 'Time: ', '$'                   ; Message before printing the time

    year dw ?                                   ; Variable to store the year
    month db ?                                  ; Variable to store the month
    day db ?                                    ; Variable to store the day
    hour db ?                                   ; Variable to store the hour
    minute db ?                                 ; Variable to store the minute
    second db ?                                 ; Variable to store the second

.stack 100h

end start
