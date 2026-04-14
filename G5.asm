.model small
.stack 100h
.data
    msg db "test$"
.code
    mov ax, @data
    mov ds, ax
    
    ;set video mode
    mov ah, 00h
    mov al, 3 
    int 10h

    ;outer most bg
    mov ah, 6 ;scroll up
    mov al, 00h

    mov bh, 11h ;blue bg blue text
    mov cx, 0000h ;row 1 col 1
    mov dx, 184fh ;row 25 col 80
    int 10h

    ;instructions and feedback box
    mov bh, 33h ;cyan bg cyan text
    mov cx, 0104h ;row 1 col 1
    mov dx, 174ah ;row 25 col 80
    int 10h

    mov ah, 9
    lea dx, msg
    int 21h

    mov ah, 4ch
    int 21h
END