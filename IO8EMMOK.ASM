;======================================================
; IO8EMMOK - A driver for fixing EMM386.EXE loading in
; MS-DOS 8.0. (a.k.a. Windows ME Real-Mode DOS)
;
; Copyright(C) 2022 Pu-Feng Du, Ph. D.
;
; LICENSE:
;  IO8EMMOK is free software: you can redistribute it
;  and/or modify it under the terms of the GNU General
;  Public License as published by the Free Software
;  Foundation, either version 2 of the License, or (at
;  your option) any later version.
;  This program is distributed in the hope that it will
;  be useful, but WITHOUT ANY WARRANTY; without even the
;  implied warranty of MERCHANTABILITY or FITNESS FOR A
;  PARTICULAR PURPOSE. See the GNU General Public License
;  for more details.
;  You should have received a copy of the GNU General
;  Public License along with this program. If not, see
;  <https://www.gnu.org/licenses/>.
;
; Compile:
;     This program can be assembled using MASM 6.15,
;     with the following command.
;
;     ML /AT /FeIO8EMMOK.SYS IO8EMMOK.ASM
;
; Install:
;     The IO8EMMOK.SYS must be installed before any
;  other drivers or TSRs override INT 15H / 2FH handler
;  of MS-DOS 8.00 kernel, the IO.SYS.
;     It is recommended to load IO8EMMOK.SYS in your
;  CONFIG.SYS as the first line! Put IO8EMMOK.SYS in your
;  DOS directory. The following line should be the first
;  line in your CONFIG.SYS.
;
;     DEVICE=C:\DOS\IO8EMMOK.SYS
;
;  After this line, you can load EMM386.EXE as normal,
;  with only one exception: the ALTBOOT option MUST be
;  appended to your EMM386.EXE device directive to allow
;  quickboot broadcasting.
;
;  Note:
;  1. IO8EMMOK.SYS is known to be compatible with the
;     UMBPCI.SYS. So, you may load UMBPCI.SYS first,
;     then use devicehigh to load IO8EMMOK.SYS to UMB.
;  2. Loading IO8EMMOK.SYS will cost 352 bytes memory.
;  3. Loading Windows 3.xx in enhanced mode still rely 
;     on the W3XStart patch, which can be found online.
;     If this search is not feasible, IO8EMMOK is packed
;     with a "hotfix" version of W3XStart patch. This
;     version does not patch any files. It only modify
;     memory. It is a simple batch file depending on the
;     standard DOS unitility DEBUG and FIND.
;  4. There is no need to decompress IO.SYS. Just patch
;     it to start the Real-Mode DOS.
;======================================================

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
        union
                rh_xcount       dw ?    
                rh_conf_offset  dw ?    
        ends                            
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
dev_name        db      'IO8EMMX$'

; Data area for the driver
vars:
bios_i15h       dd      0
i2fh            dd      0
xms_off         dw      0
xms_seg         dw      0
rh_off          dw      0
rh_seg          dw      0

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

        ; Driver init and hooks installations
        ; All init procs can be removed from memory 
        call    findi15ent
        call    xmsentr
        call    seti15h
        call    seti2fh

        ; Set memory cut point, return to system
        mov     ax, offset drv_end_addr
        mov     es:[di].rh_xfer, ax
        mov     es:[di].rh_xseg, cs
        mov     ax, 0100h
        popf
        popa
        retf
intrp   endp

; This proc alone allows the loading of EMM386.EXE
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
t_rtoff dw      0H
i15stub endp

;These procs for XMS drivers allow your to run Windows 3.xx in enhanced mode.
i2fsrv  proc    far
        cmp     ax, 4310h                       ;Trap AX=4310H
        jz      xms_handle

i2ffwd:
        pushd   cs:i2fh                         ;Not in trap, creat stack and
        retf                                    ;forward.

xms_handle:
        push    ax                              ;Return our own driver 
        mov     ax, cs
        mov     es, ax
        mov     bx, offset xmsdrv
        pop     ax
        iret
i2fsrv  endp


xmsdrv  proc    far                             ;Our wrapping XMS driver
        jmp     drvbegin                        ;Following XMS 3.0 Standard
        nop
        nop
        nop
drvbegin:                                       ;Check A20 before forwarding
        pushf
        call    isA20
        jz      xms_a20_off                     
        popf
        call    xmsstub                         ;A20 is on, just forward
        jmp     xmsexit                         ;and return with all status

xms_a20_off:                                    ;When A20 is off,
        call    set_a20_on                      ;we stealthly turn on A20
        popf
        call    xmsstub                         ;forward to HMA driver
        call    set_a20_off                     ;and switch A20 off
xmsexit:
        retf                                    ;as nothing happened
xmsdrv  endp

xmsstub proc    near
        pop     cs:xms_r                        ;Creat far return stack
        push    cs
        push    cs:xms_r                        ;for the HMA driver function
        push    cs:xms_seg                      ;Creat stack for
        push    cs:xms_off
        retf                                    ;a far call.
xms_r   dw      0h
xmsstub endp

; A20 KBC handler, codes for A20 control are mostly copied from HIMEMX source
; code, which is open source and in public domain.
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
        pushf
        cli
        call    waitkbc
        mov     al, 0D1H
        out     64H, al
        call    waitkbc
        mov     al, 0DDh
        or      al, ah
        out     60H, al
        call    waitkbc
        mov     al, 0FFH
        out     64H, al
        call    waitkbc
        popf
        pop     ax
        ret
set_a20 endp

waitkbc proc   near
        push    cx
        push    ax
        pushf
        xor     cx, cx
Waitx:
        in      al, 64H
        and     al, 2
        loopnz  Waitx
        popf
        pop     ax
        pop     cx
        ret
waitkbc endp

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

drv_end_addr    db  0                           ;Cutoff point after init

; We can cutoff from here
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
        ; never try this after loading command.com

        ; Reload address of int 2fH ivec into DS:SI
        mov     si, ax
        shr     eax, 10h
        mov     ds, ax

        ; The location of BIOS Int15H iVec
        ; DS:SI-0cH
        ; We must copy it out, as this original location is in HMA
        ; You loose it, if you disable A20
        sub     si, 0ch
        mov     eax, ds:[si]
        mov     cs:bios_i15h, eax

        ;Recover and return
        pop     si
        pop     ds
        pop     es
        pop     eax
        ret
findi15ent endp

;This proc finds the XMS driver function entrance and save it
xmsentr proc    near
        push    ds
        push    es
        push    ax
        push    bx
        mov     ax, 4310h                       ;Call Int 2FH AX=4310 
        int     2fh
        mov     cs:xms_seg, es                  ;to get HMA driver address
        mov     cs:xms_off, bx                  ;in ES:BX for store
        pop     bx
        pop     ax
        pop     es
        pop     ds
        ret
xmsentr endp

;A proc for debugging purpose
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

seti15h proc    near                            ;Install 15H handler
        cli
        push    ds
        push    eax
        xor     eax, eax
        mov     ds, ax
        mov     ax, cs
        shl     eax, 10h
        mov     ax, offset i15srv               ;EAX now is I15H ivec
        xchg    eax, ds:[54h]                   ;Location of I15H ivec
        pop     eax
        pop     ds
        sti
        ret
seti15h endp

seti2fh proc    near                            ;Install 2FH handler
        cli
        push    ds
        push    eax
        xor     eax, eax
        mov     ds, ax
        mov     ax, cs
        shl     eax, 10h
        mov     ax, offset i2fsrv
        xchg    eax, ds:[0BCh]
        pop     eax
        pop     ds
        sti
        ret
seti2fh endp
end                                             ;All program end here.

