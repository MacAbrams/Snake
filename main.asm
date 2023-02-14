%macro XSegment 1
struc %1
    .x1:    resb 1
    .y1:    resb 1
    .x2:    resb 1
    .y2:    resb 1
endstruc
%endmacro

struc XPoint
    .x:    resw 1
    .y:    resw 1
    .size:
endstruc

Convex:         equ 2
Nonconvex:      equ 1
Complex:        equ 0
CoordModeOrigin:equ 0
CoordModePrevious:equ 1

keypress:       equ 2
ButtonPress:    equ 4
Expose:         equ 12
DefaultScreen:  equ 0xe0
BlackPixel:     equ 0xe8
ExposureMask:   equ 10000000_00000000b
ButtonPressMask:equ 100b
KeyPressMask:   equ 1
xbutton.x:      equ 0x40
xbutton.y:      equ 0x44
xexpose.count:  equ 56



SQUARESIZE:     equ 40
SPEED:          equ 1

section .bss
    Ox:     resd 1
    Oy:     resd 1
    null:   resq 1
    dis:    resq 1             ;pointer
    screen: resq 1
    gc:     resq 1

    black:  resq 1
    white:  resq 1
    red:    resq 1
    blue:   resq 1
    win:    resq 0xd0
    event:  resb 0x60
    pX: resd 20
    ; player.y: resd 20


section .data
    _0.5: dq 0.5
    xorShiftState: dq 123
    width:      dd 600
    height:     dd 600
    length:     dq 1
    player.x:   times 100 dd 0
    player.y:   times 100 dd 0
    direction:  times 100 db 0

    apple.x:    dd 0
    apple.y:    dd 0

    testing: dq 0
    progress: dq 0

    score:      dq 0


section .text
extern  printf, exit, usleep
extern  XOpenDisplay, XCreateSimpleWindow, XSetStandardProperties, XSelectInput, XCreateGC, XSetBackground, XSetForeground, XClearWindow, XMapRaised, XFreeGC, XDestroyWindow, XCloseDisplay, XNextEvent, XLookupString, XDrawRectangle, XFillRectangle, XPeekEvent, XMaskEvent, XCheckMaskEvent, XPutBackEvent, XAutoRepeatOff, XBell, DisplayHeight, XPending, XFillArc, XDrawLine, XFillPolygon, XDrawString

global main
main:
    push    rbp
    mov     rbp, rsp


    call    pullScore


    call    init



    mov     rdi, [dis]
    call    XAutoRepeatOff
    mov     rdi, [dis]
    lea     rsi, [event]
    call    XNextEvent
    jmp    menu

    .running:

    call    setup
    .loop:

        mov     rdi, [dis]
        call    XPending
        cmp     rax, 0
        jna     .noEvent
        mov     rdi, [dis]
        lea     rsi, [event]
        call    XNextEvent

        call    keypressHandler
        .noEvent:
        call    gameLoop

        mov     rdi, 2500
        call    usleep

        jmp     .loop


    call    closeWin

    mov     rsp, rbp
    pop     rbp
    ret

setup:
    push    rbp
    mov     rbp, rsp

    mov     rax, 201
    mov     rdi, xorShiftState
    syscall


    mov     dword [apple.x], SQUARESIZE*11+SQUARESIZE/2
    mov     dword [apple.y], SQUARESIZE*7+SQUARESIZE/2

    mov     qword [length], 1
    mov     rdx, SQUARESIZE/2
    mov     rcx, [length]
    .loop:
        push    rcx


        mov     dword [player.x+rcx*4-4], edx
        mov     dword [player.y+rcx*4-4], 7*SQUARESIZE+SQUARESIZE/2
        mov     byte [direction+rcx-1], 0
        add     rdx, SQUARESIZE

        pop     rcx
        loop    .loop



    mov     rsp, rbp
    pop     rbp
    ret
gameLoop:
    push    rbp
    mov     rbp, rsp

    
    mov     rdi, [dis]
    mov     rsi, [win]
    call    XClearWindow


    ;=================================== background ===================================
    mov     rdi, [dis]
    mov     rsi, [gc]
    mov     rdx, 0x537d33
    call    XSetForeground
    mov     rdi, [dis]
    mov     rsi, [win]
    mov     rdx, [gc]
    mov     ecx, 0
    mov     r8d, 0
    mov     r9, [width]
    mov     rax, [height]
    push    rax
    call    XFillRectangle
    add     rsp, 8


    sub     rsp, 16
    mov     dword [rbp], 0
    .loop1:
        
        mov     dword [rbp-4], 0
        .loop2:
            mov     rdi, [dis]
            mov     rsi, [gc]
            mov     rdx, 0x116b29
            call    XSetForeground
            mov     rdi, [dis]
            mov     rsi, [win]
            mov     r9, SQUARESIZE
            mov     rax, SQUARESIZE
            push    rax

            mov     eax, [rbp]
            mov     r8d, SQUARESIZE
            mul     r8d

            mov     ecx, eax

            mov     eax, [rbp-4]
            mov     r8d, SQUARESIZE*2
            mul     r8d
            
            mov     r8d, eax

            mov     eax, [rbp]
            xor     rdx, rdx
            mov     r10d, 2
            div     r10d
            mov     eax, edx
            mov     r10d, SQUARESIZE
            mul     r10d
            sub     r8d, eax

            mov     rdx, [gc]
            call    XFillRectangle
            add     rsp, 8

            add     dword [rbp-4], 1
            mov     eax, [rbp-4]
            cmp     eax, 7
            jna     .loop2

        add     dword [rbp], 1
        mov     eax, [rbp]
        cmp     eax, 14
        jna     .loop1

    ;=================================== apple ===================================

    mov     rdi, [dis]
    mov     rsi, [gc]
    mov     rdx, 0xff0000
    call    XSetForeground

    mov     rdi, [dis]
    mov     rsi, [win]
    mov     rdx, [gc]
    mov     ecx, [apple.x]
    mov     r8d, [apple.y]
    sub     ecx, SQUARESIZE/2-4
    sub     r8d, SQUARESIZE/2-4
    mov     r9, SQUARESIZE-8
    mov     rax, SQUARESIZE-8
    push    rax
    call    XFillRectangle
    add     rsp, 0x8
    
    ;=================================== player ===================================

    mov     rcx, [length]
    jmp     .drawloop
    .head:
        mov     rdi, [dis]
        mov     rsi, [gc]
        mov     rdx, 0xff8fff
        call    XSetForeground
        xor     rdx, rdx
        xor     r8, r8

        mov     rdi, [dis]
        mov     rsi, [win]
        add     r8d, [player.y+rcx*4-4]
        mov     ecx, [player.x+rcx*4-4]
        sub     ecx, SQUARESIZE/2-4
        sub     r8d, SQUARESIZE/2-4
        mov     r9, SQUARESIZE-8
        mov     rax, SQUARESIZE-8
        push    rax
        mov     rdx, [gc]

        call    XFillRectangle
        add     rsp, 0x8
        jmp     .cont
    .body:
        mov     rdi, [dis]
        mov     rsi, [gc]
        mov     rdx, 0x5f8fff
        call    XSetForeground
        xor     rdx, rdx
        xor     r8, r8

        mov     rdi, [dis]
        mov     rsi, [win]
        add     r8d, [player.y+rcx*4-4]
        mov     ecx, [player.x+rcx*4-4]
        sub     ecx, SQUARESIZE/2-4
        sub     r8d, SQUARESIZE/2-4
        mov     r9, SQUARESIZE-8
        mov     rax, SQUARESIZE-8
        push    rax

        mov     rdx, [gc]

        call    XFillRectangle
        add     rsp, 0x8
        jmp     .cont
    .tail:
        mov     rdi, [dis]
        mov     rsi, [gc]
        mov     rdx, 0x5f8fff
        call    XSetForeground
        xor     rdx, rdx
        xor     r8, r8

        
       


   
        push    rcx



        ; Xpoint has 2 words
        sub     rsp, 4*3

        xor     edx, edx
        xor     esi, esi
        mov     r8d, SQUARESIZE/2
        mov     al, [direction+rcx-1]
        cmp     al, 11b
        cmove  edx, r8d
        cmp     al, 01b
        cmove  esi, r8d
        neg     r8d
        cmp     al, 10b
        cmove  edx, r8d
        cmp     al, 00b
        cmove  esi, r8d
        ; stays the same
        mov     eax, [player.y+rcx*4-4]
        add     eax, edx
        mov     word [rsp+10], ax
        mov     eax, [player.x+rcx*4-4]
        add     eax, esi
        mov     word [rsp+8], ax


        mov     edx, SQUARESIZE/2-4
        mov     esi, SQUARESIZE/2-4
        mov     r8d, SQUARESIZE/2-4
        neg     r8d
        mov     al, [direction+rcx-1]
        cmp     al,11b
        cmove   edx, r8d
        cmp     al, 01b
        cmove   esi, r8d

        ; if up or down
        mov     eax, [player.y+rcx*4-4]
        add     eax, edx
        mov     word [rsp+6], ax
        mov     eax, [player.x+rcx*4-4]
        add     eax, esi
        mov     word [rsp+4], ax

        mov     edx, SQUARESIZE/2-4
        mov     esi, SQUARESIZE/2-4
        mov     r8d, SQUARESIZE/2-4
        neg     r8d
        mov     al, [direction+rcx-1]
        cmp     al,10b
        cmove   edx, r8d
        cmp     al, 00b
        cmove   esi, r8d

        mov     eax, [player.y+rcx*4-4]
        sub     eax, edx
        mov     word [rsp+2], ax
        mov     eax, [player.x+rcx*4-4]
        sub     eax, esi
        mov     word [rsp+0], ax

        



        mov     rcx, rsp
        add     rcx, 0
        mov     rdi, [dis]
        mov     rsi, [win]
        mov     rdx, [gc]
        mov     r8, 3
        mov     r9, Complex
        mov     rax, CoordModeOrigin
        push    rax
        call    XFillPolygon
        add     rsp, 20
        pop     rcx

        jmp     .cont

    .drawloop:


        push    rcx

        cmp     rcx, 1
        je      .head
        mov     rax, [length]
        cmp     rcx, rax
        je      .tail
        jmp     .body
        .cont:

        pop     rcx
        dec     rcx
        cmp     rcx,0
        jne     .drawloop

    xor     dl, dl
    mov     al, [progress]
    inc     al
    cmp     al, SQUARESIZE
    cmovnb   ax, dx
    mov     [progress], al
    jb      .end


    mov     al, [direction]
    mov     rdi, 0
    mov     rsi, 0

    mov     rdx, SQUARESIZE
    cmp     al, 10b
    cmove   rsi, rdx
    cmp     al, 0b
    cmove   rdi, rdx

    neg     rdx
    cmp     al, 11b
    cmove   rsi, rdx
    cmp     al, 1b
    cmove   rdi, rdx

    call    movePlayer


    mov     rcx, [length]
    .checkLoop:
        dec     rcx
        cmp     rcx, 0
        je      .outCheck


        mov     eax, [player.x+rcx*4]
        mov     edx, [player.x]
        cmp     eax, edx
        jne     .checkLoop
        mov     eax, [player.y+rcx*4]
        mov     edx, [player.y]
        cmp     eax, edx
        jne     .checkLoop
        jmp    die

    .outCheck:


    .end:




    mov     rsp, rbp
    pop     rbp
    ret

xorShift:
    push    rsi
    mov     rax, [xorShiftState]

    mov     rdx, rax
    shr     rdx, 12
    xor     rax, rdx
    mov     rdx, rax
    shl     rdx, 25
    xor     rax, rdx
    mov     rdx, rax
    shr     rdx, 27
    xor     rax, rdx
    mov     [xorShiftState], rax

    xor     rdx, rdx
    mov     rsi, 0x2545F4914F6CDD1D
    mul     rsi

    shr     rax, 32

    pop     rsi
    ret
xorShiftFloat:
    call    xorShift

    shr     eax, 9
    mov     edx, 0x3f800000
    or      rax, rdx
    push    rax
    movss   xmm0, [rsp]
    cvtss2sd    xmm0, xmm0
    mov         rax, 1
    cvtsi2sd    xmm1, rax
    subsd       xmm0, xmm1

    pop     rax

    
    ret

eat:
    add     qword [length], 1
    ; move the segment to where it should be
    call    xorShiftFloat
    mov     rax, 14
    cvtsi2sd    xmm1, rax
    mulsd       xmm0, xmm1
    cvtsd2si    rax, xmm0
    xor     rdx, rdx
    mov     r8, SQUARESIZE
    mul     r8
    add     rax, SQUARESIZE/2
    

   
    mov     [apple.x], eax
    call    xorShiftFloat
    mov     rax, 14
    cvtsi2sd    xmm1, rax
    mulsd       xmm0, xmm1
    cvtsd2si    rax, xmm0
    xor     rdx, rdx
    mov     r8, SQUARESIZE
    mul     r8
    add     rax, SQUARESIZE/2
    

   
    mov     [apple.y], eax

    ret

; on death move all segments to -1
die:
    
    mov     rax, [length]
    mov     rdx, [score]
    cmp     rdx, rax
    cmovna   rdx, rax
    mov     [score], rdx

    call    saveScore

    jmp    menu
    

menu:

    ;=========== blue square ==============

        mov     rdi, [dis]
        mov     rsi, [gc]
        mov     rdx, 0x00ffff
        call    XSetForeground

        xor     edx, edx
        mov     eax, [width]
        mov     r8d, 4
        div     r8d

        mov     ecx, eax

        xor     edx, edx
        mov     eax, [height]
        mov     r8d, 4
        div     r8d
        mov     r8d, eax

        xor     edx, edx
        mov     eax, [height]
        mov     r9d, 2
        div     r9d

        push    rax

        xor     edx, edx
        mov     eax, [height]
        mov     r9d, 2
        div     r9d
        mov     r9d, eax

        mov     rdi, [dis]
        mov     rsi, [win]
        mov     rdx, [gc]
        call    XFillRectangle
        add     rsp, 8

    mov     rdi, [dis]
    mov     rsi, [gc]
    mov     rdx, 0x0f0000
    call    XSetForeground


    
    mov     rdi, [dis]
    mov     rsi, [win]
    mov     rdx, [gc]
    mov     ecx, 300-50
    mov     r8d, 200
    sub     rsp, 0x28
    mov     dword [rsp],        "Pres"
    mov     dword [rsp+4],      "s an"
    mov     dword [rsp+8],      "y ke"
    mov     dword [rsp+12],     "y to"
    mov     dword [rsp+16],     " pla"
    mov     dword [rsp+20],     "y!"

    mov     r9, rsp
    push    22

    call    XDrawString
    add     rsp, 0x10



    
    ;20 bytes

    sub     rsp, 0x30
    mov     dword [rsp],        "High"
    mov     dword [rsp+4],      " sco"
    mov     dword [rsp+8],      "re: "
    mov     dword [rsp+12],     0x20202020
    mov     dword [rsp+16],     0x20202020
    mov     dword [rsp+20],     0x20202020
    mov     dword [rsp+24],     0x20202020
    mov     dword [rsp+28],     0x20202020
    mov     dword [rsp+32],     0x20202020
    mov     dword [rsp+36],     0x20202020
    


    mov     rax, [score]
    mov     rsi, 10
    mov     rcx, rsp
    add     rcx, 20
    add     rcx, 11
    .convloop:
        xor     rdx, rdx
        div     rsi
        sub     rcx, 1
        add     dl, 48
        mov     [rcx], dl 

        cmp     rax, 0 
        jne     .convloop


    

    mov     rdi, [dis]
    mov     rsi, [win]
    mov     rdx, [gc]
    mov     ecx, 300-100
    mov     r8d, 300

    mov     r9, rsp
    

    push    38


    call    XDrawString
    mov     rsp, rbp



    .loop:
        mov     rdi, [dis]
        lea     rsi, [event]
        call    XNextEvent

        mov     eax, [event]
        cmp     eax, keypress
        jne     .notkey

        lea     rdi, [event]
        lea     rsi, [rbp]
        mov     rdx, 255
        mov     rcx, 0
        call    XLookupString
        cmp     rax, 1
        jne     .end

        mov     al, [rbp]
        cmp     al, "q"
        je     .exit
         
        jmp   .end

        .notkey:

       
        jmp     .loop
    .exit:
        call    closeWin
    .end:

    jmp     main.running

init:
    push    rbp
    mov     rbp, rsp

    mov     dword [Ox], 100
    mov     dword [Oy], 100
    mov     qword [black], 0x000000
    mov     qword [white], 0xffffff
    mov     qword [red], 0xff0000
    mov     qword [blue], 0x0000ff

    mov     rdi, 0
    call    XOpenDisplay
    mov     qword [dis], rax

    mov     rax, [dis+DefaultScreen]
    mov     qword [screen], rax


    mov     rax, [dis]
    mov     rdx, [rax +0xe8]
    mov     rax, [dis]
    mov     eax, [rax + 0xe0]
    cdqe
    shl     rax, 7
    add     rax, rdx
    mov     rax, [rax + 0x10]
    
    mov     rdi, [dis]
    mov     rsi, rax
    mov     rdx, 300
    mov     rcx, 300
    mov     r8, [width]
    mov     r9, [height]
    

    mov     rax, [black]
    push    rax
    mov     rax, [white]
    push    rax
    mov     rax, 5
    push    rax
    call    XCreateSimpleWindow
    mov     [win], rax    
    add     rsp, 24



    mov     rdi, [dis]
    mov     rsi, [win]
    mov     rax, "Snake"
    push    rax
    mov     rax, "Hi"
    push    rax
    lea     rdx, [rbp-8]
    lea     rcx, [rbp-16]
    mov     r8, 0
    mov     r9, 0x0
    push    r8
    push    r9
    call    XSetStandardProperties
    add     rsp, 0x20


    mov     rdi, [dis]
    mov     rsi, [win]
    mov     rdx, ExposureMask
    mov     rax, ButtonPressMask
    or      rdx, rax
    mov     rax, KeyPressMask
    or      rdx, rax
    call    XSelectInput

    mov     rdi, [dis]
    mov     rsi, [win]
    xor     rdx, rdx
    xor     rcx, rcx
    call    XCreateGC
    mov     [gc], rax

    mov     rdi, [dis]
    mov     rsi, [gc]
    mov     rdx, [white]
    call    XSetBackground

    mov     rdi, [dis]
    mov     rsi, [gc]
    mov     rdx, [black]
    call    XSetForeground

    mov     rdi, [dis]
    mov     rsi, [win]
    call    XClearWindow

    mov     rdi, [dis]
    mov     rsi, [win]
    call    XMapRaised


    mov     rsp, rbp
    pop     rbp
    ret

;rdi holds x-dir
;rsi holds y-dir
movePlayer:
    push    rbp
    mov     rbp, rsp


    


    mov     eax, [player.x]
    add     eax, edi
    mov     edx, [apple.x]
    cmp     eax, edx
    jne     .noApple
    mov     eax, [player.y]
    add     eax, esi

    mov     edx, [apple.y]
    cmp     eax, edx
    jne     .noApple

    push    rax
    push    rcx
    call    eat
    pop     rcx
    pop     rax

    .noApple:


    mov     rcx, [length]
    dec     rcx
    cmp     rcx, 0
    jz      .noLoop
    .loop:

        mov     eax, [player.x+rcx*4-4]
        mov     [player.x+rcx*4], eax 
        mov     eax, [player.y+rcx*4-4]
        mov     [player.y+rcx*4], eax 

        mov     al, [direction+rcx-1]
        mov     [direction+rcx], al 

        dec     rcx
        cmp     rcx, 0
        jne     .loop
    .noLoop:
    

    add     [player.x], edi
    add     [player.y], esi
    mov     eax, [player.x]
    mov     edx, [width]
    cmp     eax, edx
    ja      die
    cmp     eax, 0
    jb      die
    mov     eax, [player.y]
    mov     edx, [height]
    cmp     eax, edx
    ja      die
    cmp     eax, 0
    jb      die




    mov     rsp, rbp
    pop     rbp
    ret


keypressHandler:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 256 ;space for text

    mov     rax, [event] ;get pointer
    cmp     rax, keypress
    jne     .end


    lea     rdi, [event]
    lea     rsi, [rbp]
    mov     rdx, 255
    mov     rcx, 0
    call    XLookupString
    cmp     rax, 1
    jne     .end

    mov     al, [rbp]
    cmp     al, "q"
    je     .exit

    

    mov     al, [direction]
    BT      rax, 2
    jc      .end


        mov     al, [rbp]
        cmp     al, "w"
        je      .up
        cmp     al, "a"
        je      .left
        cmp     al, "s"
        je      .down
        cmp     al, "d"
        je      .right
        


        jmp     .end
        .up:
            mov     al, [direction]
            BT     rax, 1
            jc      .end

            mov     byte [direction], 11b
            
            jmp     .end
        .down:
            mov     al, [direction]
            BT     rax, 1
            jc      .end
            mov     byte [direction], 10b

           
            jmp     .end
        .right:
            mov     al, [direction]
            BT     rax, 1
            jnc      .end
            mov     byte [direction], 0b

            
            jmp     .end
        .left:        
            mov     al, [direction]
            BT     rax, 1
            jnc      .end
            mov     byte [direction], 1b




    jmp     .end
    .exit:
        call    closeWin
    .end:
    add     rsp, 256
    mov     rsp, rbp
    pop     rbp
    ret

draw:

    mov     rax, [event]
    cmp     rax, Expose
    jne     .end
    mov     rax, [event+xexpose.count]
    cmp     rax, 0
    jne     .end

    mov     rdi, [dis]
    mov     rsi, [win]
    call    XClearWindow

    .end:
    ret

closeWin:
    push    rbp
    mov     rbp, rsp

    mov     rdi, [dis]
    mov     rsi, [gc]
    call    XFreeGC

    mov     rdi, [dis]
    mov     rsi, [win]
    call    XDestroyWindow

    mov     rdi, [dis]
    call    XCloseDisplay

    xor     rdi, rdi
    call    exit

    mov     rsp, rbp
    pop     rbp
    ret

pullScore:
    ; sys open
    push    rbp
    mov     rbp, rsp




    sub     rsp, 0x8
    mov     dword [rsp], "s.tx"
    mov     dword [rsp+4], 0x00000074
    mov     rdi, rsp

    mov rdi, rsp
    mov rsi, 0102o     ;O_CREAT, man open
    mov rdx, 0666o     ;umode_t
    mov rax, 2
    syscall
    add     rsp, 0x8

    push    rax
    sub     rsp, 8
    

    mov     rdx, 8        ;message length
    mov     rsi, rsp        ;buffer
    mov     rdi, rax        ;file descriptor
    mov     rax, 0          ;read
    syscall

    mov     rax, [rsp]
    
    mov     [score], rax 




    add     rsp, 8

    pop     rax
    mov     rdi, rax        ;filepath
    mov     rax, 3          ;sys_close
    syscall


    mov     rsp, rbp
    pop     rbp
    ret


saveScore:
    ; sys open
    push    rbp
    mov     rbp, rsp




    sub     rsp, 0x8
    mov     dword [rsp], "s.tx"
    mov     dword [rsp+4], 0x00000074
    mov     rdi, rsp

    mov rdi, rsp
    mov rsi, 0102o     ;O_CREAT, man open
    mov rdx, 0666o     ;umode_t
    mov rax, 2
    syscall
    add     rsp, 0x8

    push    rax
    


    mov     rdx, 8        ;message length
    mov     rsi, score        ;buffer
    mov     rdi, rax        ;file descriptor
    mov     rax, 1          ;read
    syscall

    





    pop     rax
    mov     rdi, rax        ;filepath
    mov     rax, 3          ;sys_close
    syscall


    mov     rsp, rbp
    pop     rbp
    ret
