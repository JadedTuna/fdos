;=============================================================================;
;                                  FDOS                                       ;
;                         Written by Victor Kindhart                          ;
;                 FDOS - bootloader.asm - Bootloader for FDOS                 ;
;=============================================================================;
org 0x7C00                                                                    ; set code origin 
use16                                                                         ; tell FASM to create 16-bit code
                                                                              ;
include "../libk/definitions.inc"                                             ;
                                                                              ;
jmp short boot                                                                ; jump over the BPB
nop                                                                           ; required for correct padding
                                                                              ;
;==========================[ BIOS Parameter Block ]===========================;
bpbOEMLabel:            db "FDOSBOOT"                                         ; disk label
bpbBytesPerSector:      dw 512                                                ; number of bytes per sector
bpbSectorsPerCluster:   db 1                                                  ; number of sectors per cluster
bpbReservedSectors:     dw 2                                                  ; number of reserved sectors
bpbNumberOfFats:        db 2                                                  ; number of FAT tables
bpbRootDirEntries:      dw 224                                                ; number of entires in the root dir
bpbLogicalSectors:      dw 2880                                               ; number of logical sectors
bpbMediaDescriptorType: db 0xF0                                               ; media descriptor byte
bpbSectorsPerTable:     dw 9                                                  ; number of sectors per FAT table
bpbSectorsPerTrack:     dw 18                                                 ; number of sectors per track
bpbHeadsPerCylinder:    dw 2                                                  ; number of sides/heads
bpbHiddenSectors:       dd 1                                                  ; number of hidden sectors
bpbLargeSectors:        dd 0                                                  ; number of large sectors
bpbDriveNumber:         db 0                                                  ; drive number
bpbNTReserved:          db 0                                                  ; reserved by Windows NT
bpbSignature:           db 0x29                                               ; drive signature (0x29 for floppy)
bpbVolumeID:            dd 42                                                 ; volume ID (any number)
bpbVolumeLabel:         db "FDOS v0.1  "                                      ; name of the disk
bpbFileSystem:          db "FAT12   "                                         ; file system type
;=============================================================================;

;=======================[ main bootloader subroutine ]========================;
boot:                                                                         ;
    cli                                                                       ; disable interrupts
    mov ax, cs                                                                ; make sure ds is the same as cs
    mov ds, ax                                                                ; nop, 0
                                                                              ;
    push 0x07c0                                                               ; set stack pointer
    pop sp                                                                    ; to 0xFFFF
    xor ax, ax                                                                ; now stack has around
    mov ss, ax                                                                ; 600 KB of free space
    sti                                                                       ; get interrupts back and running
                                                                              ;
    call init_video                                                           ; detect and init video
    mov si, m_booting                                                         ; print booting message
    call puts                                                                 ;
                                                                              ;
    ;call check_a20                                                           ; check if A20 line is enabled
    ;jnz .continue                                                            ; yes, continue execution
    ;call enable_a20                                                          ; nope, enable it
                                                                              ;
.continue:                                                                    ;
    mov cx, [bpbReservedSectors]                                              ; number of sectors to read
    dec cx                                                                    ;
    push 0x7c0                                                                ; segment
    pop es                                                                    ;
    mov bx, 512                                                               ; offset
    mov ax, 1                                                                 ; starting sector
                                                                              ;
    call read_sectors                                                         ; read extended bootloader
                                                                              ;
    call fat12_init                                                           ; initialize FAT12
                                                                              ;
    mov si, d_filename                                                        ; load kernel filename
    call search_file                                                          ; and search the filesystem for it
                                                                              ;
    jc .file_not_found                                                        ; kernel was not found
                                                                              ;
    mov si, m_found                                                           ;
    call puts                                                                 ;
                                                                              ;
    mov ax, 3                                                                 ; first cluster
    push KERNEL_SEG                                                           ;
    pop es                                                                    ;
    mov bx, 0                                                                 ;
                                                                              ;
    call read_file                                                            ; read KERNEL.SYS
                                                                              ;
;-----------------------------------------------------------------------------;
;                      prepare for jumping to the kernel                      ;
;-----------------------------------------------------------------------------;
    push KERNEL_SEG                                                           ; make ds point to the kernel's
    pop ds                                                                    ; segment
                                                                              ;
    xor ax, ax                                                                ; zero out ax
    mov es, ax                                                                ; zero out segment registers
    mov fs, ax                                                                ;
    mov gs, ax                                                                ;
                                                                              ;
    xor bx, bx                                                                ; zero out other general purpose
    xor cx, cx                                                                ; registers
    xor dx, dx                                                                ;
                                                                              ;
    mov si, 0                                                                 ; zero out source and destination
    mov di, 0                                                                 ; registers
                                                                              ;
    jmp KERNEL_SEG:0                                                          ; far jump to the kernel to set cs
                                                                              ;
.file_not_found:                                                              ;
    mov si, e_not_found                                                       ;
    call puts                                                                 ;
    jmp halt                                                                  ;
                                                                              ;
;=============================================================================;

;==============================[ halt the cpu ]===============================;
halt:                                                                         ;
    cli                                                                       ; disable interrupts
    hlt                                                                       ; halt the CPU
    jmp halt                                                                  ; in case somebody uses black magic
;=============================================================================;

;==========================[ initialize video mode ]==========================;
init_video:                                                                   ;
    push ax                                                                   ; save ax
    mov ah, 0                                                                 ; set video mode function
    mov al, 3                                                                 ; text mode, 80x25
    int INT_VIDEO                                                             ; magic here happens
    pop ax                                                                    ; restore ax
    ret                                                                       ; return
;=============================================================================;

;============================[ reset disk system ]============================;
reset_disk:                                                                   ;
    push ax                                                                   ; save ax
    xor ax, ax                                                                ; disk reset function
    int INT_DISK                                                              ; call BIOS interrupt
    pop ax                                                                    ; restore ax
    ret                                                                       ; return
;=============================================================================;

;==========================[ read several sectors ]===========================;
; AX => starting sector                                                       ;
; CX => number of sectors to read                                             ;
; ES:BX => start of buffer                                                    ;
;-----------------------------------------------------------------------------;
read_sectors:                                                                 ;
    pusha                                                                     ; save all the registers
.main:                                                                        ;
    mov di, 5                                                                 ; number of retries
.loop:                                                                        ;
    push ax                                                                   ; save registers
    push bx                                                                   ;
    push cx                                                                   ;
                                                                              ;
    call LBAtoCHS                                                             ; convert LBA to CHS
                                                                              ;
    mov ah, 2                                                                 ; disk read function
    mov al, 1                                                                 ; number of sectors to read
    mov ch, BYTE [lbachs_absoluteTrack]                                       ; cylinder
    mov cl, BYTE [lbachs_absoluteSector]                                      ; sector
    mov dh, BYTE [lbachs_absoluteHead]                                        ; head
    mov dl, BYTE [bpbDriveNumber]                                             ; drive number
                                                                              ;
                                                                              ;
    call reset_disk                                                           ; reset disk system
                                                                              ;
    push dx                                                                   ; some BIOSes trash dx
    int INT_DISK                                                              ; magic!
    pop dx                                                                    ;
                                                                              ;
    jnc .end                                                                  ; end it if no error occured
                                                                              ;
    call reset_disk                                                           ; reset disk
    dec di                                                                    ; decrement error counter
                                                                              ;
    pop cx                                                                    ; restore registers
    pop bx                                                                    ;
    pop ax                                                                    ;
                                                                              ;
                                                                              ;
    pop cx                                                                    ; restore cx as loop counter
    loop .loop                                                                ; loopey-loop
                                                                              ;
    mov si, e_read                                                            ; failure
    call puts                                                                 ; we should inform the user of it
    jmp halt                                                                  ; and halt
.end:                                                                         ;
    pop cx                                                                    ;
    pop bx                                                                    ;
    pop ax                                                                    ;
    popa                                                                      ; and all regs
    ret                                                                       ; return
;-----------------------------------------------------------------------------;
.totalSectors dw 0                                                            ;
;=============================================================================;

;===========================[ convert LBA to CHS ]============================;
; AX => LBA to convert                                                        ;
;                                                                             ;
; sector = (logical_sector/sectors_per_track) + 1                             ;
; head = (logical_sector/sectors_per_track) % number_of_heads                 ;
; track = logical_sector/(sectors_per_track * number_of_heads)                ;
;-----------------------------------------------------------------------------;
LBAtoCHS:                                                                     ;
    xor dx, dx                                                                ;
    div WORD [bpbSectorsPerTrack]                                             ;
    inc dl                                                                    ;
    mov BYTE [lbachs_absoluteSector], dl                                      ;
                                                                              ;
    xor dx, dx                                                                ;
    div WORD [bpbHeadsPerCylinder]                                            ;
    mov BYTE [lbachs_absoluteHead], dl                                        ;
    mov BYTE [lbachs_absoluteTrack], al                                       ;
                                                                              ;
    ret                                                                       ;
;-----------------------------------------------------------------------------;
lbachs_absoluteTrack db 0                                                     ;
lbachs_absoluteSector db 0                                                    ;
lbachs_absoluteHead db 0                                                      ;
;=============================================================================;

;=============================[ print a string ]==============================;
puts:                                                                         ;
    pusha                                                                     ; save registers
    mov ah, 0xE                                                               ; BIOS print char interrupt
.loop:                                                                        ;
    lodsb                                                                     ; fetch next char
    cmp al, 0                                                                 ; end of string?
    jz .end                                                                   ; yes, returning
                                                                              ;
    int INT_VIDEO                                                             ; print out that character
    jmp .loop                                                                 ; loopey-woopey
.end:                                                                         ;
    popa                                                                      ; restore registers
    ret                                                                       ; return
;=============================================================================;

;================================[ messages ]=================================;
m_booting db "FDOS bootloader ver 1.0", RN                                    ; multiline booting message
          db "Looking for KERNEL.SYS...", RN, 0                               ;
m_found db "Found KERNEL.SYS, loading...", RN, 0                              ;
                                                                              ;
;=============================================================================;

;=================================[ errors ]==================================;
e_read db "Failed to read kernel.", RN, 0                                     ; read failure error
e_not_found db "KERNEL.SYS not found", RN, 0                                  ; kernel not found
;=============================================================================;

;===============================[ FAT12 data ]================================;
fat12_firstFATSector dw 0                                                     ; first FAT sector
fat12_rootDirSectors dw 0                                                     ; number of root directory sectors
fat12_firstRootDirSector dw 0                                                 ; first sector of the root directory
fat12_firstDataSector dw 0                                                    ; first sector of data
fat12_rootDirOffset dw 0                                                      ;  offset of root directory in memory
;=============================================================================;

;===============================[ other data ]================================;
d_filename db "KERNEL  SYS"                                                   ; kernel's filename
;=============================================================================;

;=================================[ padding ]=================================;
times 510 - ($ - $$) db 0                                                     ; boot sector should be 512 bytes
dw 0xAA55                                                                     ; BIOS magic number so it finds the bootloader
;=============================================================================;



;=============================================================================;
;                                                                             ;
;                        second part of the bootloader                        ;
;                                                                             ;
;=============================================================================;

;============================[ initialize FAT12 ]=============================;
fat12_init:                                                                   ;
    pusha                                                                     ;
    mov ax, WORD [bpbReservedSectors]                                         ;
    mov [fat12_firstFATSector], WORD ax                                       ;
                                                                              ;
    mov cx, [bpbSectorsPerTable]                                              ;
    push FAT_SEG                                                              ;
    pop es                                                                    ;
    xor bx, bx                                                                ;
    call read_sectors                                                         ; read FAT
                                                                              ;
    mov ax, 32                                                                ; size of root directory entry
    mul WORD [bpbRootDirEntries]                                              ; total size of directory
    div WORD [bpbBytesPerSector]                                              ; number of sectors used by directory
    mov [fat12_rootDirSectors], ax                                            ;
                                                                              ;
                                                                              ;
    xor ax, ax                                                                ;
    mov al, BYTE [bpbNumberOfFats]                                            ; compute first root directory sector
    mul WORD [bpbSectorsPerTable]                                             ;
    add ax, [bpbReservedSectors]                                              ;
    mov [fat12_firstRootDirSector], ax                                        ;
                                                                              ;
    add ax, [fat12_rootDirSectors]                                            ; compute first data sector
    mov [fat12_firstDataSector], ax                                           ;
                                                                              ;
    mov ax, WORD [bpbSectorsPerTable]                                         ;
    mul WORD [bpbBytesPerSector]                                              ;
    mov [fat12_rootDirOffset], WORD ax                                        ; offset of root directory in memory
    mov bx, ax                                                                ;
    mov ax, WORD [fat12_firstRootDirSector]                                   ;
    mov cx, WORD [fat12_rootDirSectors]                                       ;
    push FAT_SEG                                                              ;
    pop es                                                                    ;
    call read_sectors                                                         ; read root directory
                                                                              ;
    popa                                                                      ;
    ret                                                                       ;
;=============================================================================;

;============================[ search for a file ]============================;
; DS:SI => pointer to the filename                                            ;
;-----------------------------------------------------------------------------;
search_file:                                                                  ;
    push es                                                                   ; save registers
    pusha                                                                     ;
                                                                              ;
    push FAT_SEG                                                              ; position of the first entry
    pop es                                                                    ;
    mov di, [fat12_rootDirOffset]                                             ;
    mov cx, 11                                                                ; filename length
                                                                              ;
.loop:                                                                        ;
    cmp [es:di], BYTE 0                                                       ; end of root directory?
    jz .not_found                                                             ;
    cmp [es:di], BYTE 0xE5                                                    ; unused directory entry?
    je .loop                                                                  ;
    push si                                                                   ;
    push di                                                                   ;
    repe cmpsb                                                                ; compare two strings
    pop di                                                                    ;
    pop si                                                                    ;
    je .found                                                                 ;
                                                                              ;
    add di, 32                                                                ; next directory entry
                                                                              ;
    jmp .loop                                                                 ; keep searching
                                                                              ;
.found:                                                                       ; file found
    clc                                                                       ;
    jmp .end                                                                  ;
.not_found:                                                                   ; file not found
    stc                                                                       ;
    jmp .end                                                                  ;
.end:                                                                         ; clean up and return
    popa                                                                      ;
    pop es                                                                    ;
    ret                                                                       ;
;=============================================================================;

;================================[ read file ]================================;
; AX => first cluster                                                         ;
;-----------------------------------------------------------------------------;
read_file:                                                                    ; 0x7e52
;jmp $
.start:                                                                       ;
    push ax                                                                   ; save current cluster
    call clusterToLBA                                                         ; convert cluster number to LBA
    xor cx, cx                                                                ;
    mov cl, [bpbSectorsPerCluster]                                            ; convert byte to word
    call read_sectors                                                         ; read first cluster
    pop ax                                                                    ; restore cluster
    call next_cluster                                                         ; obtain next cluster
                                                                              ;
    cmp ax, 0xFF8                                                             ; is this end of the file?
    jge .end                                                                  ;
                                                                              ;
    add bx, 0x200                                                             ;
    jmp .start                                                                ;
                                                                              ;
.end:                                                                         ;
    ret                                                                       ;
;=============================================================================;

;=========================[ convert cluster to LBA ]==========================;
; Params:                                                                     ;
;     AX => cluster                                                           ;
; Return:                                                                     ;
;     AX => LBA                                                               ;
;-----------------------------------------------------------------------------;
; LBA = (cluster - 2) * sectors_per_cluster                                   ;
;-----------------------------------------------------------------------------;
clusterToLBA:                                                                 ;
    sub ax, 2                                                                 ;
    xor cx, cx                                                                ;
    mov cl, BYTE [bpbSectorsPerCluster]                                       ; convert byte to word
    mul cx                                                                    ;
    add ax, WORD [fat12_firstDataSector]                                      ; base data sector
                                                                              ;
    ret                                                                       ;
;=============================================================================;

;====================[ obtain next cluster in the chain ]=====================;
; AX => active_cluster                                                        ;
;-----------------------------------------------------------------------------;
next_cluster:                                                                 ;
    push cx                                                                   ; save registers
    push dx                                                                   ;
    push bx                                                                   ;
    push es                                                                   ;
;-----------------------------------------------------------------------------;
; active_cluster = active_cluster * 1.5                                       ;
;-----------------------------------------------------------------------------;
    mov cx, ax                                                                ; save ax
    mov dx, ax                                                                ;
    shr dx, 1                                                                 ; divide by 2
    add cx, dx                                                                ;
                                                                              ;
    push FAT_SEG                                                              ;
    pop es                                                                    ;
    mov bx, 0                                                                 ;
    add bx, cx                                                                ; index into FAT
    mov dx, WORD [es:bx]                                                      ; read two bytes from FAT
    test ax, 1                                                                ; fix the next cluster number
    jnz .odd_cluster                                                          ;
                                                                              ;
.even_cluster:                                                                ;
    and dx, 0x0FFF                                                            ; take low 12 bits
    jmp .done                                                                 ;
                                                                              ;
.odd_cluster:                                                                 ;
    shr dx, 4                                                                 ; take high 12 bits
                                                                              ;
.done:                                                                        ;
    mov [.temp], WORD dx                                                      ; save dx
    pop es                                                                    ; restore registers
    pop bx                                                                    ;
    pop dx                                                                    ;
    pop cx                                                                    ;
    mov ax, WORD [.temp]                                                      ; restore ax
    ret                                                                       ;
;-----------------------------------------------------------------------------;
.temp dw 0                                                                    ;
;=============================================================================;

;=================================[ padding ]=================================;
times 1024 - ($ - $$) db 0                                                    ; align to 1024 bytes
;=============================================================================;