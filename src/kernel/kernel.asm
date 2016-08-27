;=============================================================================;
;                                  FDOS                                       ;
;                         Written by Victor Kindhart                          ;
;                    FDOS - kernel.asm - Kernel for FDOS                      ;
;=============================================================================;
org 0                                                                         ; far jump from the bootloader already set cs
use16                                                                         ; tell FASM to generate 16-bit code
                                                                              ;
include "../libk/definitions.inc"                                             ;
                                                                              ;
;=========================[ main kernel subroutine ]==========================;
kernel_main:                                                                  ;
    call setup_IVT                                                            ; setup FDOS interrupts
    push KERNEL_SEG                                                           ; for comparing strings
    pop es                                                                    ;
                                                                              ;
    mov ah, 0                                                                 ; FDOS print
    mov si, m_kernel                                                          ; load kernel intro message
    int INT_FDOS                                                              ; and print it
.loop:                                                                        ;
    mov ah, 0                                                                 ; FDOS print
    mov si, m_prompt                                                          ; print prompt
    int INT_FDOS                                                              ;
                                                                              ;
    mov di, d_input                                                           ; where user input lies
    mov ah, 1                                                                 ; FDOS read
    mov dl, 63                                                                ; max length
    int INT_FDOS                                                              ;
                                                                              ;
    cmp byte [di], 0                                                          ; and empty line?
    je .loop                                                                  ; yep, do nothing
                                                                              ;
    mov si, c_help                                                            ; load si with address of
    call k_strcmp                                                             ; help command and compare
    je .cmd_help                                                              ; yep, exec!
                                                                              ;
    mov si, c_cls                                                             ; load si with address of
    call k_strcmp                                                             ; cls command and compare
    je .cmd_cls                                                               ; yep, exec!
                                                                              ;
    mov si, e_unknown                                                         ; unknown command
    mov ah, 0                                                                 ;
    int INT_FDOS                                                              ; print out the error message
    jmp .loop                                                                 ; and loop
                                                                              ;
.cmd_help:                                                                    ; print help
    mov si, m_help                                                            ; load help message
    mov ah, 0                                                                 ; and FDOS print interrupt
    int INT_FDOS                                                              ; execute
    jmp .loop                                                                 ; loop again
                                                                              ;
.cmd_cls:                                                                     ; clear the screen
    mov ah, 0                                                                 ; here we just set
    mov al, 3                                                                 ; video mode to
    int INT_VIDEO                                                             ; text mode, 80x25
    jmp .loop                                                                 ; loop again
;=============================================================================;

;============================[ includes go here ]=============================;
include "../libk/interrupt.asm"                                               ; interrupt handlers
include "../libk/string.asm"                                                  ; string functions
;=============================================================================;

;================================[ commands ]=================================;
c_help db "help", 0                                                           ; help command
c_cls db "cls", 0                                                             ; cls command
;=============================================================================;

;================================[ messages ]=================================;
m_kernel db "FDOS ver 0.1, (C) 2016, Victor Kindhart", RN                     ; multiline welcome message
         db "Type help to get help", RN, RN, 0                                ;
;-----------------------------------------------------------------------------;
m_help db "Commands: (commands marked with - are not yet supported)", RN      ; multiline help message
       db "  help: print help message", RN                                    ;
       db "  cls: clear the display", RN                                      ;
       db " -shutdown: shutdown the system", RN, 0                            ;
;-----------------------------------------------------------------------------;
m_prompt db ">> ", 0                                                          ; command prompt
;=============================================================================;

;=================================[ errors ]==================================;
e_unknown db "Unknown command.", RN, 0                                        ; unknown command error
;=============================================================================;

;==================================[ data ]===================================;
d_input: times 64 db 0                                                        ; user input goes here
;=============================================================================;