bits 16

section _TEXT class=CODE

;
;void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor,
;                         uint64_t *quotient, uint32_t *remainder);
;
global _x86_div64_32
_x86_div64_32:
   ; make a new call frame
   push bp          ; save old call frame
   mov bp, sp       ; init new call frame

   push bx

   ; divide the upper 32 bits
   mov eax, [bp + 8]    ; eax <- upper 32 bits of dividend
   mov ecx, [bp + 12]   ; ecx <- divisor
   xor edx, edx
   div ecx              ; eax <- quotient, edx <- remainder

   ; store the result
   mov bx, [bp + 16]
   mov [bx + 4], eax

   ; divide lower 32 bits
   mov eax, [bp + 4]    ; eax <- lower 32 bits of dividend
                        ; ecx <- old remainder
   div ecx

   ; stor lower 32 bits
   mov [bx], eax
   mov bx, [bp + 18]
   mov [bx], edx

   pop bx

   ; restore old call frame
   mov sp, bp
   pop bp
   ret

;
;   args: character, page
;
global _x86_Video_WriteCharTTY
_x86_Video_WriteCharTTY:
   ; make a new call frame
   push bp          ; save old call frame
   mov bp, sp       ; init new call frame

   ; save bx
   push bx

   ; [bp + 0] - old call frame
   ; [bp + 2] - ret addres (small memory model => 2 bytes)
   ; [bp + 4] - character
   ; [bp + 6] - page
   mov ah, 0Eh
   mov al, [bp + 4]
   mov bh, [bp + 6]
   int 10h

   ; restore bx
   pop bx

   ; restore old call frame
   mov sp, bp
   pop bp
   ret
