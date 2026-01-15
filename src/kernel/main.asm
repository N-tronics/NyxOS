org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

_start:
    jmp main

; Prints a character to the screen
; Params:
;  - ds:si points to the string
puts:
    ; save registers
    push si
    push ax
.loop:
    lodsb       ; Loads a single byte from DS:SI address to AL register
    or al, al   ; Check if byte is 0
    jz .done
    
    mov ah, 0x0e    ; Call BIOS interrupt for printing character to screen
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    pop ax
    pop si
    ret

main:
    ; setup data segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    ; setup stack
    mov ss, ax
    mov sp, 0x7C00

    mov si, hw_msg
    call puts

    hlt

.halt:
    jmp .halt

hw_msg db "Hello, World!", ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
