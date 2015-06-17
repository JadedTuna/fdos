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
CHAR_BACKSPACE equ 8                        ; backspace char
CHAR_SPACE equ ' '                          ; space char
CHAR_CR equ 0xD                             ; carriage return char
CHAR_NL equ 0xA                             ; newline char
                                            ;
INT_VIDEO equ 0x10                          ; BIOS video interrupt
INT_DISK equ 0x13                           ; BIOS disk interrupt
INT_KEYBOARD equ 0x16                       ; BIOS keyboard interrupt
INT_FDOS equ 0x21                           ; FDOS general functions' interrupt
;===========================================;

jmp kernel_main ; jump over the data section

;=================[ data ]==================;
d_input: times 64 db 0                      ; user input goes here
;===========================================;

;===============[ messages ]================;
m_booting db "FDOS bootloader ver 1.0", RN  ; multiline booting
          db "Loading FDOS...", RN, 0       ; message
m_prompt db ">> ", 0                        ;
;===========================================;

;=========[ main kernel function ]==========;
kernel_main:                                ;
    call setup_IVT                          ; setup FDOS interrupts
.loop:                                      ;
    mov ah, 0                               ; FDOS print
    mov si, m_prompt                        ; print prompt
    int INT_FDOS                            ;
                                            ;
    mov si, d_input                         ; where user input lies
    mov ah, 1                               ; FDOS read
    mov dl, 63                              ; max length
    int INT_FDOS                            ;
                                            ;
    mov ah, 0                               ; FDOS print
    int INT_FDOS                            ;
    jmp .loop                               ; and loop
;===========================================;

;=======[ all other stuff goes here ]=======;
include "libk/interrupt.asm"                ; interrupt handlers
include "libk/string.asm"                   ; string functions
;===========================================;