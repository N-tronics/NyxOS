org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;
; FAT12 Header
;
jmp short _start
nop

bpb_oem:                    db 'MSWIN4.1'   ; 8 bytes
bpb_bytes_per_sector:       dw 512
bpb_sectors_per_cluster:    db 1
bpb_reserved_sectors:       dw 1
bpb_fat_count:              db 2
bpb_dir_entries_count:      dw 0E0h
bpb_total_sectors:          dw 2880
bpb_media_descriptor_type:  db 0F0h         ; F0 = 3.5" Floppy disk
bpb_sectors_per_fat:        dw 9
bpb_sectors_per_track:      dw 18
bpb_heads:                  dw 2
bpb_hidden_sectors:         dd 0
bpb_large_sector_count:     dd 0
; extended boot record
ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h
ebr_volume_label:           db 'NYX OS     '    ; 11 Bytes
ebr_system_id:              db 'FAT12   '       ; 8 Bytes

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
    ; BIOS sets the drive number in DL register
    mov [ebr_drive_number], dl

    mov ax, 1           ; LBA=1, 2nd sector
    mov cl, 1           ; read 1 sector
    mov bx, 0x7E00      ; destination address
    call disk_read

    mov si, msg_hello
    call puts

    jmp halt

;
; Disk Routines
;

; Converts LBA address to CHS address
; Params:
;   - ax: LBA address
; Returns:
;   - cx [0-5]: sector number
;   - cx [6-15]: cylinder
;   - dh: head
lba_to_chs:
    push ax
    push dx

    xor dx, dx                          ; dx = 0
    div word [bpb_sectors_per_track]    ; ax = LBA / sectorsPerTrack
                                        ; dx = LBA % sectorsPerTrack
    inc dx                              ; dx = LBA % sectorsPerTrack + 1 = sector
    mov cx, dx

    xor dx, dx
    div word [bpb_heads]                ; ax = (LBA / sectorsPerTrack) / Heads = cylinder
                                        ; dx = (LBA / sectorsPerTrack) % Heads = head
    mov dh, dl
    mov ch, al                          ; Put upper 2 bits of cylinder in CL
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret


; Reads from a Disk
; Params:
;   - ax: LBA address
;   - cl: number of sectors to read
;   - dl: drive number
;   - es:bx: memory address where to store read data
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx     ; Save CL
    call lba_to_chs
    pop ax

    mov ah, 02h
    mov di, 3   ; Retry count
.retry:
    pusha       ; save all registers since we dont know what BIOS modifies
    stc         ; set carry flag
    int 13h     ; If carry = 0, sucess
    jnc .done

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry
    jmp floppy_error

.done:
    popa
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Resets disk controller
; Params:
;   - dl: Drive number
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


;
; Error Handlers
;
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0       ; jump to begging of BIOS
    jmp halt

halt:
    cli     ; Disable interrupts
    hlt

msg_hello           db "Hello, World!", ENDL, 0
msg_read_failed     db "Read from disk failed!", ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
