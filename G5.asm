.model small
.stack 100h
.data
.code
    mov ax, @data
    mov ds, ax
    
    mov ah, 4ch
    int 21h
END