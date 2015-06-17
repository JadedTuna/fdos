;=============================================================================;
;                                  FDOS                                       ;
;                         Written by Victor Kindhart                          ;
;             FDOS - interrupt.asm - Interrupt handlers for FDOS              ;
;=============================================================================;

;=========[ setup FDOS interrupts ]=========;
setup_IVT:                                  ;
    pusha                                   ; save registers
    cli                                     ; make sure we don't get
                                            ; `interrupted` :D
    xor bx, bx                              ; zero out bx
    mov es, bx                              ; load es with 0 (zeroeth segment)
    mov bx, 0x21                            ; interrupt number
    shl bx, 2                               ; multiply by 4 because IVT
                                            ; consists of 4-byte entries
    mov word [es:bx], FDOS_21_handler       ; store handler's address
    add bx, 2                               ; move further on IVT
    mov word [es:bx], KERNEL_SEG            ; store handler's segment
    sti                                     ; re-enable interrupts
    popa                                    ; restore registers
    ret                                     ; return
;===========================================;

;=========[ handler for int 0x21 ]==========;
FDOS_21_handler:                            ;
    cmp ah, 0                               ; print string?
    je i21_print_str                        ; sure
                                            ;
    cmp ah, 1                               ; read string?
    je i21_read_str                         ; no problem
                                            ;
    iret                                    ; otherwise return
;------------[ print a string ]-------------;
i21_print_str:                              ;
    pusha                                   ; save registers
    mov ah, 0xE                             ; BIOS video function
.loop:                                      ;
    lodsb                                   ; fetch next char
    cmp al, 0                               ; is end of string?
    jz .end                                 ; yep, getting out
                                            ;
    int INT_VIDEO                           ; print out that char
    jmp .loop                               ;
.end:                                       ;
    popa                                    ; restore registers
    iret                                    ; return
;-------------------------------------------;
;-------------[ read a string ]-------------;
i21_read_str:                               ;
    pusha                                   ; save registers
    mov cl, 0                               ; current string's size
.loop:                                      ;
    mov ah, 0                               ; fetch character
    int INT_KEYBOARD                        ; from keyboard
                                            ;
    cmp al, CHAR_BACKSPACE                  ; is backspace?
    je .backspace                           ; erase!
                                            ;
    cmp al, CHAR_CR                         ; is new line?
    je .newline                             ; return!
                                            ;
    cmp cl, dl                              ; string too long?
    je .loop                                ; do nothing!
                                            ;
    stosb                                   ; store character in memory
    inc cl                                  ; increase size
    mov ah, 0xE                             ; and print it
    int INT_VIDEO                           ;
                                            ;
    jmp .loop                               ; and once again
.backspace:                                 ;
    cmp cl, 0                               ; string length is zero?
    jz .loop                                ; nothing to do here
                                            ; 
    mov ah, 0xE                             ; print backspace char
    int INT_VIDEO                           ;
                                            ;
    mov al, CHAR_SPACE                      ; write space to empty
    int INT_VIDEO                           ; the cell
                                            ;
    mov al, CHAR_BACKSPACE                  ; and go back once again
    int INT_VIDEO                           ;
                                            ;
    dec di                                  ; decrease string's size
    dec cl                                  ;
                                            ;
    jmp .loop                               ; and loop!
.newline:                                   ;
    mov ah, 0xE                             ; print carriage return
    int INT_VIDEO                           ;
                                            ;
    mov al, CHAR_NL                         ; and a newline
    int INT_VIDEO                           ;
                                            ;
    mov al, 0                               ; store NULL char
    stosb                                   ;
                                            ;
    mov byte [.size], cl                    ; a hack to save string's size
    popa                                    ; restore registers
    mov dl, byte [.size]                    ; here it is :D
    iret                                    ; and return!
.size db 0                                  ; string size
;-------------------------------------------;
;===========================================;