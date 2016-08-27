;=============================================================================;
;                                  FDOS                                       ;
;                         Written by Victor Kindhart                          ;
;                FDOS - string.asm - String functions for FDOS                ;
;=============================================================================;

;================================[ k_strcmp ]=================================;
; Compare two strings.                                                        ;
;                                                                             ;
; DS:SI - pointer to the first string                                         ;
; ES:DI - pointer to the second string                                        ;
;-----------------------------------------------------------------------------;
k_strcmp:                                                                     ;
    pusha                                                                     ; save all the registers
.loop:                                                                        ;
    lodsb                                                                     ; al has the byte stored at si
    mov bl, [di]                                                              ; bl has the byte stored at di
    inc di                                                                    ; advance di
                                                                              ;
    cmp al, bl                                                                ;
    jne .end                                                                  ; and return if they don't match
                                                                              ;
    cmp al, 0                                                                 ; end of string?
    je .end                                                                   ; yep
                                                                              ;
    jmp .loop                                                                 ; continue
.end:                                                                         ;
    popa                                                                      ; restore registers
    ret                                                                       ; return
;=============================================================================;