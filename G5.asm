.model small
.stack 100h
.data
    player1msg  db "Player1's turn: Press Left-Right-Arrow to change color $"
    player1msg2 db "and up down to go to the next or previous tile.$"
    color       db 70h      ; starting color (grey)

.code
    mov ax, @data
    mov ds, ax

    ; set video mode
    mov ah, 00h
    mov al, 3
    int 10h

    ; outermost bg
    mov ah, 6
    mov al, 00h
    mov bh, 10h
    mov cx, 0000h
    mov dx, 184fh
    int 10h

    ; instructions and feedback box
    mov bh, 30h
    mov cx, 0104h
    mov dx, 174bh
    int 10h

    ; grid area
    mov bh, 10h
    mov cx, 0604h
    mov dx, 124bh
    int 10h

DRAW_SQUARE:
    ; draw square with current color
    mov ah, 6
    mov al, 00h
    mov bh, color       ; use current color variable
    mov cx, 0704h
    mov dx, 0807h
    int 10h

    ; draw instruction text
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

    ; hide cursor off-screen so it doesn't show on the square
    mov ah, 02h
    mov bh, 00h
    mov dh, 24
    mov dl, 0
    int 10h

KEY_LOOP:
    ; wait for keypress
    mov ah, 00h
    int 16h             ; AL = ASCII, AH = scan code

    ; check if extended key (arrow keys have AL = 0)
    cmp al, 00h
    jne CHECK_ESC

    ; left arrow = cycle color backward
    cmp ah, 4bh
    je  COLOR_PREV

    ; right arrow = cycle color forward
    cmp ah, 4dh
    je  COLOR_NEXT

    jmp KEY_LOOP

CHECK_ESC:
    cmp al, 1bh         ; ESC to exit
    je  EXIT
    jmp KEY_LOOP

COLOR_NEXT:
    ; add 10h to go to next background color
    mov al, color
    cmp al, 70h         ; if already at 7 (grey)...
    je  WRAP_TO_GREEN   ; ...wrap to green
    add al, 10h
    and al, 0f0h        ; keep only the high nibble (bg color bits)
    mov color, al
    jmp DRAW_SQUARE

    WRAP_TO_GREEN:
    mov color, 20h      ; reset to green
    jmp DRAW_SQUARE

COLOR_PREV:
    ; subtract 10h to go to previous background color
    mov al, color
    cmp al, 20h         ; if at green (2)...
    je  WRAP_TO_GREY    ; ...wrap to grey
    sub al, 10h
    mov color, al
    jmp DRAW_SQUARE

WRAP_TO_GREY:
    mov color, 70h      ; reset to grey
    jmp DRAW_SQUARE

EXIT:
    mov ah, 4ch
    int 21h
END