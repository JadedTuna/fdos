;=============================================================================;
;                                  FDOS                                       ;
;                         Written by Victor Kindhart                          ;
;                 FDOS - bootloader.asm - Bootloader for FDOS                 ;
;=============================================================================;
org 0 ; cs will cope with that
use16 ; tell FASM we are REAL!

;==============[ definitions ]==============;
KERNEL_SEG equ 0x7E0                        ; kernel segment
BOOT_SEG equ 0x7C0                          ; bootloader segment
                                            ;
RN equ 0xD, 0xA                             ; newline as seen by BIOS
                                            ;
INT_VIDEO equ 0x10                          ; BIOS video interrupt
INT_DISK equ 0x13                           ; BIOS disk interrupt
;===========================================;

jmp BOOT_SEG:boot ; perform a far jump to modify cs register

;===============[ messages ]================;
m_booting db "FDOS bootloader ver 1.0", RN  ; multiline booting
          db "Loading FDOS...", RN, 0       ; message
;===========================================;

;================[ errors ]=================;
e_read db "Failed to read kernel.", RN, 0   ; read failure error
;===========================================;

;=======[ main bootloader function ]========;
boot:                                       ;
    cli                                     ; disable interrupts
    mov ax, cs                              ; make sure ds is the same as cs
    mov ds, ax                              ;
                                            ;
    shl ax, 4                               ; multiply ax by 0x10 (16)
    mov sp, ax                              ; set stack pointer to 0x7C00
    xor ax, ax                              ; now stack has around
    mov ss, ax                              ; 30 KB of free space
    sti                                     ; get interrupts back 'n running
                                            ;
    call init_video                         ; detect and init video
    mov si, m_booting                       ; print booting message
    call print_str                          ;
                                            ;
    mov al, 8                               ; number of sectors to read
    call read_disk                          ; read kernel from the disk
                                            ;
                                            ; prepare for going to kernel mode
    mov ax, KERNEL_SEG                      ; make ds point to the kernel's
    mov ds, ax                              ; segment
                                            ;
    xor ax, ax                              ; zero out ax
    mov es, ax                              ; zero out segment registers
    mov fs, ax                              ;
    mov gs, ax                              ;
                                            ;
    xor bx, bx                              ; zero out other general purpose
    xor cx, cx                              ; registers
    xor dx, dx                              ;
                                            ;
    mov si, 0                               ; zero out source and destination
    mov di, 0                               ; registers
                                            ;
    jmp KERNEL_SEG:0                        ; far jump to the kernel to set cs
;===========================================;

;=============[ halt the cpu ]==============;
halt:                                       ;
    cli                                     ; disable interrupts
    hlt                                     ; halt the CPU
    jmp halt                                ; in case somebody uses black magic
;===========================================;

;===========[ initialize video ]============;
init_video:                                 ;
    push ax                                 ; save ax
    mov ah, 0                               ; set video mode function
    mov al, 3                               ; text mode, 80x25
    int INT_VIDEO                           ; magic here happens
    pop ax                                  ; restore ax
    ret                                     ; return
;===========================================;

;===========[ reset disk system ]===========;
reset_disk:                                 ;
    push ax                                 ; save ax
    xor ax, ax                              ; disk reset function
    int INT_DISK                            ; call BIOS interrupt
    pop ax                                  ; restore ax
    ret                                     ; return
;===========================================;

;============[ read from disk ]=============;
read_disk:                                  ;
    pusha                                   ; save all the registers
    xor dh, dh                              ; head number
    mov bx, KERNEL_SEG                      ; store kernel's segment
    mov es, bx                              ; in es register
    xor bx, bx                              ; the padding
                                            ;
    mov cx, 3                               ; cx will be the loop counter
.loop:                                      ;
    push cx                                 ; save cx
                                            ;
    mov ah, 2                               ; disk read function
    mov ch, 0                               ; cylinder
    mov cl, 2                               ; sector
                                            ;
    call reset_disk                         ; reset disk system
                                            ;
    push dx                                 ; some BIOSes trash dx
    int INT_DISK                            ; magic!
    pop dx                                  ;
                                            ;
    jnc .end                                ; end it if no error occured
                                            ;
    pop cx                                  ; restore cx as loop counter
    loop .loop                              ; loopey-loop
                                            ;
    mov si, e_read                          ; failure
    call print_str                          ; we should inform the user of it
    jmp halt                                ; and halt
.end:                                       ;
    pop cx                                  ; restore cx
    popa                                    ; and all regs
    ret                                     ; return
;===========================================;

;============[ print a string ]=============;
print_str:                                  ;
    pusha                                   ; save registers
    mov ah, 0xE                             ; BIOS print char interrupt
.loop:                                      ;
    lodsb                                   ; fetch next char
    cmp al, 0                               ; end of string?
    jz .end                                 ; yes, returning
                                            ;
    int INT_VIDEO                           ; print out that character
    jmp .loop                               ; loopey-woopey
.end:                                       ;
    popa                                    ; restore registers
    ret                                     ; return
;===========================================;

;================[ padding ]================;
times 510 - ($ - $$) db 0                   ; boot sector should be 512 bytes
dw 0xAA55                                   ; BIOS magic number so it finds us
;===========================================;