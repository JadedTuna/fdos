;=============================================================================;
;                                  FDOS                                       ;
;                         Written by Victor Kindhart                          ;
;          FDOS - definitions.inc - Definitions used by varios files          ;
;=============================================================================;

;==============[ definitions ]==============;
KERNEL_SEG equ 0xF00                        ; kernel segment
BOOT_SEG   equ 0x7C0                        ; bootloader segment
FAT_SEG    equ 0x800                        ; FAT segment
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
INT_FDOS equ 0x21                           ; FDOS functions interrupt
;===========================================;
