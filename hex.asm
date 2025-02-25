INCLUDE macros.inc

.8086
.model small
PUBLIC print_hex
.code

print_hex PROC
    
convert_to_hex:
    push ax
    push bx
    push cx

    mov ah, al     ; Save byte in AH
    shr al, 4      ; Keep only the high nibble
    call convert_hex_num

    mov al, ah     ; Restore original byte
    and al, 0Fh    ; Keep only the low nibble (0xAB → 0x0B)
    call convert_hex_num
    
    pop cx
    pop bx
    pop ax
    ret

convert_hex_num:
    push ax   ; Save AL
    and al, 0Fh    ; Keep only the lowest 4 bits
    add al, '0'    ; Convert 0–9 to '0'–'9'
    cmp al, '9'    
    jbe print_hex_num 
    add al, 7h     ; Convert A–F (A=41h, B=42h, ...)

print_hex_num:
    mov ah, 0Eh    ; BIOS function for character output
    int 10h
    pop ax   ; Restore AL
    ret



print_hex ENDP

.data

.stack 100h

END