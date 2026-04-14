.model small
.stack 100h
.data
    player1msg  db "Player1's turn: Press Left-Right-Arrow to change color $"
    player1msg2 db "and up down to go to the next or previous tile.$"
    color1      db 70h      ; square 1 color (grey)
    color2      db 70h      ; square 2 color (grey)
    selected    db 01h      ; 1 = square 1 selected, 2 = square 2 selected

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
    ; draw square 1 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, color1
    mov cx, 0704h
    mov dx, 0807h
    int 10h

    ; draw square 2 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, color2
    mov cx, 0a04h
    mov dx, 0b07h
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

    ; hide cursor
    mov ah, 02h
    mov bh, 00h
    mov dh, 24
    mov dl, 0
    int 10h

KEY_LOOP:
    mov ah, 00h
    int 16h

    cmp al, 00h
    jne CHECK_ESC

    cmp ah, 4bh         ; left arrow
    jne CHECK_RIGHT
    jmp COLOR_PREV      ; unconditional JMP can reach farther

CHECK_RIGHT:
    cmp ah, 4dh         ; right arrow
    jne CHECK_UP
    jmp COLOR_NEXT

CHECK_UP:
    cmp ah, 48h         ; up arrow
    jne CHECK_DOWN
    jmp SELECT_UP

CHECK_DOWN:
    cmp ah, 50h         ; down arrow
    jne KEY_LOOP
    jmp SELECT_DOWN

CHECK_ESC:
    cmp al, 1bh
    jne KEY_LOOP
    jmp EXIT
    
SELECT_UP:
    ; move to previous square, wrap 1 -> 2
    cmp selected, 01h
    je  UP_WRAP
    dec selected
    jmp KEY_LOOP
UP_WRAP:
    mov selected, 02h
    jmp KEY_LOOP

SELECT_DOWN:
    ; move to next square, wrap 2 -> 1
    cmp selected, 02h
    je  DOWN_WRAP
    inc selected
    jmp KEY_LOOP
DOWN_WRAP:
    mov selected, 01h
    jmp KEY_LOOP

COLOR_NEXT:
    cmp selected, 01h
    je  NEXT_SQ1

    ; square 2
    mov al, color2
    cmp al, 70h
    je  NEXT_SQ2_WRAP
    add al, 10h
    mov color2, al
    jmp DRAW_SQUARE
NEXT_SQ2_WRAP:
    mov color2, 20h
    jmp DRAW_SQUARE
NEXT_SQ1:
    mov al, color1
    cmp al, 70h
    je  NEXT_SQ1_WRAP
    add al, 10h
    mov color1, al
    jmp DRAW_SQUARE
NEXT_SQ1_WRAP:
    mov color1, 20h
    jmp DRAW_SQUARE

COLOR_PREV:
    cmp selected, 01h
    je  PREV_SQ1

    ; square 2
    mov al, color2
    cmp al, 20h
    je  PREV_SQ2_WRAP
    sub al, 10h
    mov color2, al
    jmp DRAW_SQUARE
PREV_SQ2_WRAP:
    mov color2, 70h
    jmp DRAW_SQUARE
PREV_SQ1:
    mov al, color1
    cmp al, 20h
    je  PREV_SQ1_WRAP
    sub al, 10h
    mov color1, al
    jmp DRAW_SQUARE
PREV_SQ1_WRAP:
    mov color1, 70h
    jmp DRAW_SQUARE

EXIT:
    mov ah, 4ch
    int 21h
END