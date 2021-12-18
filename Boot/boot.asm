org 0x7c00;设置起始地址
BaseOfstack equ 0x7c00;等同于变量定义
Label_Start:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,BaseOfstack

;====== in10h ,ah 06h ,屏幕上卷，等同清屏 ========
    mov ah,06h
    mov bh,07h
    mov cx,0
    mov dx,0184fh
    int 10h

;====== int 10h ,ah 02h ,设置光标位置=====
    mov ah,02h
    mov bh,0    ;页号
    mov dx,0    ;行，列位置
    int 10h

;====== int 10h ,ah 13h ,打印字符串=====
    mov ah,13h
    mov al,01h    ;光标跟随移动
    mov bx,000fh  ;字符串设置
    mov dx,0    ;起始行列
    mov cx,10h  ;字符串长度
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,StartBootMessage
    int 10h

;====== reset floppy 重置磁盘驱动器，=====
    xor ah,ah
    xor dl,dl
    int 13h

    jmp $

    StartBootMessage:   db  "Start Boot";等同一维字符串
    times 510-($-$$) db 0   ;填充0
    dw 0xaa55

