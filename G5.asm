.model small
.stack 100h
.data
.code
    mov ax, @data
    mov ds, ax

    ;set video mode
    mov ah, 00h
    mov al, 3 
    int 10h

    ;bg
    mov ah, 6 
    mov al, 00h
    mov bh, 0010h
    mov cx, 0000h ;row 1 col 1
    mov dx, 184fh ;row 25 col 80
    int 10h
    
    mov ah, 4ch
    int 21h
END