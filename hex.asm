INCLUDE macros.inc

.8086
.model small
PUBLIC print_hex
.code


; ==============================================================================================
; Conversion to hex and byte output in hexadecimal
; ==============================================================================================
;
; This code defines a procedure print_hex to print the hexadecimal representation of a byte. 
; It splits the byte into its high and low nibbles, converts them to hex, 
; and displays them one by one. The convert_hex_num procedure handles the conversion 
; of the nibble to its corresponding ASCII character. The shr instruction is used 
; to isolate the high nibble, and and is used to isolate the low nibble. 
; Depending on the value of the nibble, it either converts numbers 0-9 directly 
; or adds an offset to convert letters A-F. The characters are printed using BIOS interrupt 0Eh.
;
; ==============================================================================================
; ==============================================================================================


print_hex PROC
convert_to_hex:
    push ax                                     ; Save registers that will be used
    push bx
    push cx

    mov ah, al                                  ; Copy the original byte to AH for later restoration
    shr al, 4                                   ; Shift the byte to keep only the high nibble (upper 4 bits)
    call convert_hex_num                        ; Convert the high nibble to hex and print it

    mov al, ah                                  ; Restore the original byte to AL
    and al, 0Fh                                 ; Mask AL to keep only the low nibble (lower 4 bits)
    call convert_hex_num                        ; Convert the low nibble to hex and print it
    
    pop cx                                      ; Restore registers
    pop bx
    pop ax
    ret                                         ; Return from the procedure

convert_hex_num:
    push ax                                     ; Save AL register
    and al, 0Fh                                 ; Mask to keep only the lowest 4 bits
    add al, '0'                                 ; Convert the number to ASCII characters
    cmp al, '9'                                 ; Check if the value is greater than 9 (if it's A-F)
    jbe print_hex_num                           ; If AL is between '0' and '9', jump to printing
    add al, 7h                                  ; If it's A-F, add 7h to convert to 'A' (ASCII 41h) to 'F' (ASCII 46h)

print_hex_num:
    mov ah, 0Eh                                 ; BIOS function to print a character on the screen
    int 10h                                     ; Call BIOS interrupt to display the character
    pop ax                                      ; Restore AL register
    ret                                         ; Return from the convert_hex_num procedure

print_hex ENDP

.data

.stack 100h

END