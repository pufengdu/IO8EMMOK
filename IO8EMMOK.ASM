; Single segment device driver, 386 real mode
.model tiny
.386

npbyte typedef near ptr byte

; For calling DOS services
include dos.inc

; Data structure definition of DOS driver request header
rh      struct          1t
        rh_len          db ?
        rh_unit         db ?
        rh_cmd          db ?
        rh_status       dw ?
        rh_res          db 8 dup(?)
        rh_media        db ?
        rh_xfer         dw ?
        rh_xseg         dw ?
        UNION
                rh_xcount       dw ?    
                rh_conf_offset  dw ?    
        ENDS                            
        rh_config_seg   dw ?             
rh  ends

; .SYS format requirement, begin with offset 0H
.code
org 0

; Device driver header
next_drv        dd      0ffffffffh
attribute       dw      8000h
strategy        dw      strat
interrupt       dw      intrp
dev_name        db      'IO8EMM0$'

; Data area for the driver
vars:
dos_i15h        dd      0
bios_i15h       dd      0
i2fh            dd      0
rh_off          dw      0
rh_seg          dw      0
drv_cut         npbyte  drv_end_addr

strat   proc    far
        mov     word ptr cs:[rh_seg], es
        mov     word ptr cs:[rh_off], bx
        ret
strat   endp

intrp   proc    far
        pusha
        pushf
        push    cs
        pop     ds
        mov     di, rh_off
        mov     dx, rh_seg
        mov     es, dx
        assume  di:ptr rh

        call    findi15ent
        call    seti15h

        mov     ax, drv_cut
        mov     es:[di].rh_xfer, ax
        mov     es:[di].rh_xseg, cs
        mov     ax, 0100h
        popf
        popa
        retf
intrp   endp

i15srv  proc    far                             ;I15H Handler
        cmp     ah, 88h                         ;Hook AH=88H
        jz      AH88H
        cmp     ax, 0E801H                      ;Hook AX=E801
        jz      AXE801H
        cmp     ah, 87h                         ;Hook AH=87H
        jz      AH87H
        jmp     FWRD                            ;Others, make chain call

AXE801H:
        xor     bx, bx

AH88H:
        xor     ax, ax
        sti
        iret

AH87H:
        call    isA20
        jz      DIS_A20_CALL
        call    i15stub                         ;In segment stub for far call
        call    set_a20_on                      ;Force A20 to turn on
        sti
        iret                                    ;This is interrupt handler

DIS_A20_CALL:
        call    i15stub
        call    set_a20_off
        sti
        iret

FWRD:
        call    i15stub
        sti
        iret
i15srv  endp

i15stub proc    near
        cli
        pop     cs:t_rtoff                      ;Temporaty store return IP
        pushf                                   ;Creat a stack for iret
        push    cs
        push    cs:t_rtoff
        pushd   cs:bios_i15h                    ;Prepare for call chain
        retf                                    ;Chain into BIOS I15H handler
        ret
t_rtoff dw      0H
i15stub endp

; A20 KBC handler
isA20   proc    near
        push    ds
        push    es
        push    cx
        push    si
        push    di

        mov     cx, -1
        mov     es, cx
        mov     si, 10h
        inc     cx
        mov     ds, cx
        mov     di, 20h
        mov     cl, 4
repz    cmpsd
        pop     di
        pop     si
        pop     cx
        pop     es
        pop     ds
        ret
isA20   endp

set_a20 proc    near
        push    ax
        cli
        call    wait8042
        mov     al, 0D1H
        out     64H, al
        call    wait8042
        mov     al, 0DDh
        or      al, ah
        out     60H, al
        call    wait8042
        mov     al, 0FFH
        out     64H, al
        call    wait8042
        sti
        pop     ax
        ret
set_a20 endp

wait8042 proc   near
        xor     cx, cx
Waitx:
        in      al, 64H
        and     al, 2
        loopnz  Waitx
        ret
wait8042 endp

set_a20_on proc near
        push    ax
        mov     ah, 2
        call    set_a20
        pop     ax
        ret
set_a20_on endp

set_a20_off proc near
        push    ax
        mov     ah, 0
        call    set_a20
        pop     ax
        ret
set_a20_off endp

findi15ent proc near
        ; This proc uses a trick to extract the BIOS int 15h ivec from
        ; inside private area of IO.SYS 8.0
        ; MS-DOS 8.0 IO.SYS contain XMS driver, which resides in HMA
        ; So, you cannot globally disable A20, or you loose A20 control
        ; It's a A20 control in HMA case.
        ; However, the BIOS Int 15h Ah=87 may alter A20
        ; Therefor, IO.SYS hook 15h AH=87 to hang the system if you call
        ; that in real mode
        ; This is why you cannot load EMM386.EXE in MSDOS 8.0
        ; In protected mode, another M$ XMS driver will fix this issue
        ; For fixing real mode, you need to rehook the INT15H, change
        ; function AH=87/88 and AX=E801
        ; So, a trick is needed to find out BIOS version ivec, not
        ; IO.SYS version.
        push    eax
        push    es
        push    ds
        push    si
        xor     ax, ax
        mov     ds, ax
        mov     si, 2fh
        shl     si, 2h

        ; First, we extract int 2fH handler from the intv table
        mov     eax, ds:[si]
        mov     cs:i2fh, eax

        ; The trick is :
        ; In all MS-DOS 8.0 IO.SYS
        ; The BIOS int 15 vector is stored just before the entrance
        ; of int 2fh. This driver must be the first in config.sys
        ; as other program would overwrite int 2f to change this behavior
        ; never try this after command.com

        ; Reload address of int 2fH ivec into DS:SI
        mov     si, word ptr cs:i2fh
        mov     ax, word ptr cs:i2fh+2
        mov     ds, ax

        ; The location of BIOS Int15H iVec
        ; DS:SI-0cH
        ; We must copy it out, as this original location is in HMA
        ; You loose it, if you disable A20
        sub     si, 0ch
        mov     eax, ds:[si]
        mov     cs:bios_i15h, eax

        ;Load and display for verification
        pop     si
        pop     ds
        pop     es
        pop     eax
        ret
findi15ent endp

; Maybe, we can cutoff from here
xtbl    db      '0123456789ABCDEF'
axchr   db      4       dup(0) , ' $'
axdisp  proc    near
        pusha 
        push    ds
        push    es
        push    cs
        pop     ds
        push    cs
        pop     es
        lea     bx, xtbl
        lea     di, axchr
        mov     dx, 0f000h
        mov     cx, 000ch
mkchar:
        push    ax
        and     ax, dx
        shr     ax, cl
        xlat
        stosb
        sub     cl, 3
        shr     dx, 4
        pop     ax
        loop    mkchar
        push    ax
        and     ax, dx
        xlat
        stosb
        pop     ax
        @ShowStr axchr
        pop     es
        pop     ds
        popa
        ret
axdisp  endp

seti15h proc    near                            ;Install I15H handler
        cli
        push    ds
        push    eax
        xor     eax, eax
        mov     ds, ax
        mov     ax, cs
        shl     eax, 10h
        mov     ax, offset i15srv               ;EAX now is I15H ivec
        xchg    eax, ds:[54h]                   ;Location of I15H ivec
        mov     cs:dos_i15h, eax                ;Preserve old one
        pop     eax
        pop     ds
        sti
        ret
seti15h endp

drv_end_addr    db  0

end

