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
    
    mov ah, 4ch
    int 21h
END