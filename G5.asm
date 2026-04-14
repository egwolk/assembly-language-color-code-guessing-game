.model small
.stack 100h
.data
    player1msg db "Player1's turn: Press Left-Right-Arrow to change color $"
    player1msg2 db "and up down to go to the next or previous tile.$"
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

    mov bh, 10h ;blue bg blue text
    mov cx, 0000h ;start row 0 col 0
    mov dx, 184fh ;end row 24 col 79
    int 10h

    ;instructions and feedback box
    mov bh, 30h ;cyan bg cyan text
    mov cx, 0104h ;start row 1 col 4 
    mov dx, 174bh ;end row 23 col 75
    int 10h

    ;grid area
    mov bh, 10h ;blue bg blue text
    mov cx, 0604h ;start row 5 col 4
    mov dx, 124bh ;end row 19 col 75
    int 10h

    ; ;square 1 try 1
    ; mov bh, 70h ; grey bg grey text
    ; mov cx, 0704h ;start row 6 col 4
    ; mov dx, 0807h ;end row 7 col 9
    ; int 10h


    mov ah, 02h
    mov bh, 00h
    mov dh, 02
    mov dl, 12
    int 10h

    mov ah, 9
    lea dx, player1msg
    int 21h

    mov ah, 02h
    mov bh, 00h
    mov dh, 03
    mov dl, 16
    int 10h

    mov ah, 9
    lea dx, player1msg2
    int 21h

    mov ah, 4ch
    int 21h
END