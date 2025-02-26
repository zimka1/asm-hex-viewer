INCLUDE macros.inc

.8086
.model small
PUBLIC print_date
.code

EXTRN print_dec:near

print_date PROC
start:
    ; geting date
    mov ah, 2Ah  ; DOS: Get system date
    int 21h
    mov year, cx
    mov month, dh
    mov day, dl

    ; geting time
    mov ah, 2Ch  ; DOS: Get system time
    int 21h
    mov hour, ch
    mov minute, cl
    mov second, dh

    print_text date_msg

    mov ax, year
    call print_dec

    mov dl, '-'
    mov ah, 02h
    int 21h

    mov al, month
    cbw
    call print_dec

    mov dl, '-'
    mov ah, 02h
    int 21h

    mov al, day
    cbw
    call print_dec

    print_line_feed_without_offset

    print_text time_msg

    mov al, hour
    cbw
    call print_dec

    mov dl, ':'
    mov ah, 02h
    int 21h

    mov al, minute
    cbw
    call print_dec

    mov dl, ':'
    mov ah, 02h
    int 21h

    mov al, second
    cbw
    call print_dec

    ret

print_date ENDP

.data
    date_msg db 'Date: ', '$'
    time_msg db 'Time: ', '$'

    year    dw ?
    month   db ?
    day     db ?
    hour    db ?
    minute  db ?
    second  db ?

.stack 100h

end start
