org 0x7c00;设置起始地址
BaseOfstack equ 0x7c00  ;等同于变量定义
BaseOfLoader equ 0x1000 ;起始物理地址
OffsetOfLoader equ 0x00

RootDirSectors equ 14   ;根目录占用扇区数
SectorNumOfRootDirStart equ 19  ;根目录起始扇区号
SectorNumOfFAT1Start equ 1  ;FAT1表起始扇区号
SectorBalance equ 17

    jmp short Label_Start
    nop
    BS_OEMName db 'MINEboot'    ;盘符
    BPB_BytesPerSec dw 512
    BPB_SecPerClus db 1
    BPB_RsvdSecCnt dw 1
    BPB_NumFATs db 2
    BPB_RootEntCnt dw 224
    BPB_TotSec16 dw 2880
    BPB_Media db 0xf0
    BPB_FATSz16 dw 9
    BPB_SecPerTrk dw 18
    BPB_NumHeads dw 2
    BPB_hiddSec dd 0
    BPB_TotSec32 dd 0
    BS_DrvNum db 0
    BS_Reservedl db 0
    BS_BootSig db 29h
    BS_VolID dd 0
    BS_VolLab db 'boot loader'
    BS_FileSysType db 'FAT12'

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

;=======目标文件搜索==========
    mov word [SectorNo],SectorNumOfFAT1Start   ;保存根目录起始扇区
Lable_Search_In_Root_Dir_Begin:
    cmp word [RootDirSizeForLoop],0 ;RootDirSizeForLoop 根目录占用扇区数
    jz Label_No_LoaderBin
    dec word [RootDirSizeForLoop]   ;dec 操作数-1
    mov ax,00h
    mov es,ax
    mov bx,8000h
    mov ax,[SectorNo]   
    mov cl,1
    call Func_ReadOneSector ;读入一个扇区
    mov si,LoaderFileName
    mov di,8000h
    cld
    mov dx,10h

Label_Search_For_LoaderBin:
    cmp dx,0
    jz Label_Goto_Next_Sector_In_Root_Dir
    dec dx
    mov cx,11

Label_Cmp_FileName:
    cmp cx,0
    jz Label_FileName_Found
    dec cx
    lodsb
    cmp al,byte [es:di]
    jz Label_Go_On
    jmp Label_Different

Label_Go_On:
    inc di
    jmp Label_Cmp_FileName

Label_Different:
    and di,0ffe9h
    add di,20h
    mov si,LoaderFileName
    jmp Label_Search_For_LoaderBin

Label_Goto_Next_Sector_In_Root_Dir:
    add word [SectorNo],1
    jmp Lable_Search_In_Root_Dir_Begin


;=======无loader.bin===========

Label_No_LoaderBin:
    mov ax,1301h
    mov bx,008ch
    mov dx,0100h
    mov cx,21
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,NoLoaderMessage
    int 10h
    jmp $


;=======	found loader.bin name in root director struct

Label_FileName_Found:

	mov	ax,	RootDirSectors
	and	di,	0ffe0h
	add	di,	01ah
	mov	cx,	word	[es:di]
	push	cx
	add	cx,	ax
	add	cx,	SectorBalance
	mov	ax,	BaseOfLoader
	mov	es,	ax
	mov	bx,	OffsetOfLoader
	mov	ax,	cx

Label_Go_On_Loading_File:
	push	ax
	push	bx
	mov	ah,	0eh
	mov	al,	'.'
	mov	bl,	0fh
	int	10h
	pop	bx
	pop	ax

	mov	cl,	1
	call	Func_ReadOneSector
	pop	ax
	call	Func_GetFATEntry
	cmp	ax,	0fffh
	jz	Label_File_Loaded
	push	ax
	mov	dx,	RootDirSectors
	add	ax,	dx
	add	ax,	SectorBalance
	add	bx,	[BPB_BytesPerSec]
	jmp	Label_Go_On_Loading_File

Label_File_Loaded:
	
	jmp	$

    
;=======	读入一个扇区

Func_ReadOneSector:
	
	push	bp
	mov	bp,	sp
	sub	esp,	2
	mov	byte	[bp - 2],	cl
	push	bx
	mov	bl,	[BPB_SecPerTrk]
	div	bl
	inc	ah
	mov	cl,	ah
	mov	dh,	al
	shr	al,	1
	mov	ch,	al
	and	dh,	1
	pop	bx
	mov	dl,	[BS_DrvNum]
Label_Go_On_Reading:
	mov	ah,	2
	mov	al,	byte	[bp - 2]
	int	13h
	jc	Label_Go_On_Reading
	add	esp,	2
	pop	bp
	ret
;=======	get FAT Entry

Func_GetFATEntry:

	push	es
	push	bx
	push	ax
	mov	ax,	00
	mov	es,	ax
	pop	ax
	mov	byte	[Odd],	0
	mov	bx,	3
	mul	bx
	mov	bx,	2
	div	bx
	cmp	dx,	0
	jz	Label_Even
	mov	byte	[Odd],	1

Label_Even:

	xor	dx,	dx
	mov	bx,	[BPB_BytesPerSec]
	div	bx
	push	dx
	mov	bx,	8000h
	add	ax,	SectorNumOfFAT1Start
	mov	cl,	2
	call	Func_ReadOneSector
	
	pop	dx
	add	bx,	dx
	mov	ax,	[es:bx]
	cmp	byte	[Odd],	1
	jnz	Label_Even_2
	shr	ax,	4

Label_Even_2:
	and	ax,	0fffh
	pop	bx
	pop	es
	ret

;=======	tmp variable

RootDirSizeForLoop	dw	RootDirSectors
SectorNo		dw	0
Odd			db	0

;=======	display messages

StartBootMessage:	db	"Start Boot"
NoLoaderMessage:	db	"ERROR:No LOADER Found"
LoaderFileName:		db	"LOADER  BIN",0

;=======	fill zero until whole sector

	times	510 - ($ - $$)	db	0
	dw	0xaa55

