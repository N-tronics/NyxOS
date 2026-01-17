; Main job of this stage of the bootloader is to search for the 
; ext_boot.bin file in the floppy disk and load the extended bootloader

; BIOS loads the first 512 Bytes of the disk into memory at address 0x7C00
org 0x7C00
; At boot, CPU is in 16 bit real mode
bits 16

%define ENDL 0x0D, 0x0A

;
; FAT12 Header
;

; FAT12 Specifications and header
; First instruction is to jump to main segment
jmp short main
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

main:
    ; setup data segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    ; setup stack
    mov ss, ax
    mov sp, 0x7C00
    
    ; make sure BIOS has started at 0000:7C00 instead of 07C0:0000
    push es
    push word .after
    retf
.after:

    ; BIOS sets the drive number in DL register
    mov [ebr_drive_number], dl
    
    ; Print the loading message
    mov si, msg_loading
    call puts

    ; read drive parameters(sectorsPerTrack and head count)
    push es
    mov ah, 08h
    int 13h
    jc floppy_error
    pop es

    and cl, 0x3f
    xor ch, ch
    mov [bpb_sectors_per_track], cx
    inc dh
    mov [bpb_heads], dh

    ; compute root directory offset
    mov ax, [bpb_sectors_per_fat]       ; lba of root directory = reserved + fats * sectors_per_fat
    mov bl, [bpb_fat_count]
    xor bh, bh
    mul bx
    add ax, [bpb_reserved_sectors]      ; ax = lba
    push ax
    ; compute root dir size
    mov ax, [bpb_dir_entries_count]     
    shl ax, 5                           ; ax *= 32
    xor dx, dx
    div word [bpb_bytes_per_sector]
    test dx, dx                         ; If we have a partial sector, we should increase sector count
    jz .root_dir_after
    inc ax
.root_dir_after:
    ;  Read Root directory
    mov cl, al                          ; Number of sectors to read = size of root dir
    pop ax                              ; lba of root dir
    mov dl, [ebr_drive_number]
    mov bx, buffer                      ; es:bx = destination address
    call disk_read

    ; Search for ext_boot.bin
    ; bx holds the number of entries searched so far
    xor bx, bx
    mov di, buffer

.search_ext_boot:
    mov si, file_ext_boot_bin
    mov cx, 11                      ; compare 11 characters
    push di
    ; Compare strings at ds:si and es:di
    ; cmpsb comapres cx bytes from each string
    ; cmpsb instruction automatically sets the equal flag if strings are equal
    repe cmpsb
    pop di
    je .found_ext_boot
    
    ; If we haven't found the ext_boot, we go to the next entry by moving 32 bytes further
    add di, 32
    ; increment bx and check if we have searched all root directory entries
    inc bx
    cmp bx, [bpb_dir_entries_count]
    jl .search_ext_boot
    
    ; ext_boot was not found
    jmp ext_boot_not_found

.found_ext_boot:
    ; Read the clusters of the ext_boot file
    ; di points to the address of the directory entry
    ; cluster address is at an offset of 26 bytes from the start of the entry
    mov ax, [di + 26]
    mov [ext_boot_cluster], ax

    ; load FAT from disk
    mov ax, [bpb_reserved_sectors]
    mov bx, buffer
    mov cl, [bpb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    ; address space 0x7E00 ~ 0x7FFFF ( = 480.5 KiB) is non-reserved onventional memory
    mov bx, EXT_BOOT_LOAD_SEGMENT
    mov es, bx
    mov bx, EXT_BOOT_LOAD_OFFSET
.load_ext_boot_loop:
    ; read next cluster
    mov ax, [ext_boot_cluster]
    ; TODO: Fix hard coded 31 value
    add ax, 31
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read
    ; TODO: bx can overflow if the ext_boot file is too large
    add bx, [bpb_bytes_per_sector]
    
    ; Compute next location
    mov ax, [ext_boot_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx                          ; ax = index of entry in FAT, dx = cluster mod 2

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz .even

.odd:
    shr ax, 4
    jmp .next_cluster

.even:
    and ax, 0x0FFF

.next_cluster:
    cmp ax, 0x0FF8                  ; Check for end of chain
    jae .read_finished

    mov [ext_boot_cluster], ax
    jmp .load_ext_boot_loop

.read_finished:
    ; Jump to ext_boot
    mov dl, [ebr_drive_number]
    mov ax, EXT_BOOT_LOAD_SEGMENT
    mov ds, ax
    mov es, ax

    jmp EXT_BOOT_LOAD_SEGMENT:EXT_BOOT_LOAD_OFFSET
    
    ; Halt the system
    ; This should not execute
    jmp wait_key_and_reboot

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

ext_boot_not_found:
    mov si, msg_ext_boot_not_found
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

msg_loading               db "Loading...", ENDL, 0
msg_read_failed           db "Read from disk failed!", ENDL, 0
msg_ext_boot_not_found    db "EXT_BOOT.BIN file not found!", ENDL, 0
file_ext_boot_bin         db "EXT_BOOTBIN"
; Stores the current cluster of the ext_boot file
ext_boot_cluster          dw 0

EXT_BOOT_LOAD_SEGMENT     equ 0x2000
EXT_BOOT_LOAD_OFFSET      equ 0

; Ensure that the boot sector is 512 bytes
times 510-($-$$) db 0
; Boot signature
dw 0AA55h

; Extra space at the end of the boot sector to store intermediate data
; such as root directory entires and the FAT
buffer:
