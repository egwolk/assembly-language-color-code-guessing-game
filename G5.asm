.model small
.stack 100h
.data
    player1msg  db "Player1's turn: $"
    player2msg  db "Player2's turn: $"

    playermsg1 db "Press Left-Right-Arrow to change color $"
    playermsg2 db "and up down to go to the next or previous tile.$"
    playermsg3 db "Press [ENTER] to confirm color code.$"
    
    color1      db 70h      ; square 1 color (grey)
    color2      db 70h      ; square 2 color (grey)
    color3      db 70h      ; square 3 color (grey)
    color4      db 70h      ; square 4 color (grey)
    selected    db 01h      ; 1 = square 1 selected, 2 = square 2 selected

        turn        db 01h      ; 1 = player1 editing, 2 = player2 editing
    p1color1    db 70h
    p1color2    db 70h
    p1color3    db 70h
    p1color4    db 70h

    p2color1    db 70h
    p2color2    db 70h
    p2color3    db 70h
    p2color4    db 70h

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
    ;player 1 squares
    ; draw square 1 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, color1
    mov cx, 0748h
    mov dx, 084bh
    int 10h

    ; draw square 2 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, color2
    mov cx, 0a48h
    mov dx, 0b4bh
    int 10h

    ; draw square 3 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, color3
    mov cx, 0d48h
    mov dx, 0e4bh
    int 10h

    ; draw square 4 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, color4
    mov cx, 1048h
    mov dx, 114bh
    int 10h

    ;player 2 squares
    ; draw square 1 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, p2color1
    mov cx, 0704h
    mov dx, 0807h
    int 10h

    ; draw square 2 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, p2color2
    mov cx, 0a04h
    mov dx, 0b07h
    int 10h

    ; draw square 3 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, p2color3
    mov cx, 0d04h
    mov dx, 0e07h
    int 10h

    ; draw square 4 with its own color
    mov ah, 6
    mov al, 00h
    mov bh, p2color4
    mov cx, 1004h
    mov dx, 1107h
    int 10h

    

    ; draw instruction text
    mov ah, 02h
    mov bh, 00h
    mov dh, 02
    mov dl, 12
    int 10h

    cmp turn, 01h
    jne SHOW_P2_MSG

    ; print player1msg in RED (34h)
    lea si, player1msg
    mov bl, 34h      ; red foreground
    jmp PRINT_COLORED

SHOW_P2_MSG:
    ; print player2msg in PURPLE (35h)
    lea si, player2msg
    mov bl, 35h      ; purple foreground

PRINT_COLORED:
    mov al, [si]
    cmp al, '$'
    je PRINT_DONE
    
    mov ah, 09h
    mov bh, 00h
    mov cx, 1        ; write 1 character
    int 10h
    
    inc dl           ; move cursor right
    mov ah, 02h
    int 10h
    
    inc si
    jmp PRINT_COLORED

PRINT_DONE:
    ; now position and print playermsg1 in WHITE (after player1/2msg)
    mov ah, 02h
    mov bh, 00h
    mov dh, 02
    int 10h

    mov ah, 9
    lea dx, playermsg1
    int 21h

    ; print playermsg2
    mov ah, 02h
    mov bh, 00h
    mov dh, 03
    mov dl, 16
    int 10h

    mov ah, 9
    lea dx, playermsg2
    int 21h

    ; print playermsg3
    mov ah, 02h
    mov bh, 00h
    mov dh, 04
    mov dl, 22
    int 10h

    mov ah, 9
    lea dx, playermsg3
    int 21h

    cmp turn, 01h
    je  P1_CURSOR
    
P2_CURSOR:
cmp selected, 01h
jne P2_CHK2
mov dh, 08
mov dl, 04
jmp SET_CURSOR

P2_CHK2:
cmp selected, 02h
jne P2_CHK3
mov dh, 0Bh
mov dl, 04
jmp SET_CURSOR

P2_CHK3:
cmp selected, 03h
jne P2_SQ4
mov dh, 0Eh
mov dl, 04
jmp SET_CURSOR

P2_SQ4:
mov dh, 11h
mov dl, 04
jmp SET_CURSOR

P1_CURSOR:
cmp selected, 01h
jne P1_CHK2
mov dh, 08
mov dl, 48h
jmp SET_CURSOR

P1_CHK2:
cmp selected, 02h
jne P1_CHK3
mov dh, 0Bh
mov dl, 48h
jmp SET_CURSOR

P1_CHK3:
cmp selected, 03h
jne P1_SQ4
mov dh, 0Eh
mov dl, 48h
jmp SET_CURSOR

P1_SQ4:
mov dh, 11h
mov dl, 48h

SET_CURSOR:
mov ah, 02h
mov bh, 00h
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
    jne CHECK_ENTER
    jmp EXIT

CHECK_ENTER:
    cmp al, 0Dh
    jne KEY_LOOP
    jmp COMMIT_P1_AND_SWITCH

COMMIT_P1_AND_SWITCH:
    ; do this only once, when player1 confirms
    cmp turn, 01h
    jne KEY_LOOP

    mov al, color1
    mov p1color1, al
    mov al, color2
    mov p1color2, al
    mov al, color3
    mov p1color3, al
    mov al, color4
    mov p1color4, al

    mov color1, 70h
    mov color2, 70h
    mov color3, 70h
    mov color4, 70h

    mov p2color1, 70h
    mov p2color2, 70h
    mov p2color3, 70h
    mov p2color4, 70h
    
    mov selected, 01h
    mov turn, 02h

    jmp DRAW_SQUARE
    
SELECT_UP:
    cmp selected, 01h
    jne UP_DEC
    mov selected, 04h
    jmp DRAW_SQUARE

UP_DEC:
    dec selected
    jmp DRAW_SQUARE

SELECT_DOWN:
    cmp selected, 04h
    jne DOWN_INC
    mov selected, 01h
    jmp DRAW_SQUARE

DOWN_INC:
    inc selected
    jmp DRAW_SQUARE

COLOR_NEXT:
    cmp turn, 01h
    je  NEXT_P1
    jmp NEXT_P2

NEXT_P1:
    cmp selected, 01h
    jne NEXT_P1_CHK2
    mov al, color1
    cmp al, 70h
    je  NEXT_P1_1_WRAP
    add al, 10h
    mov color1, al
    jmp DRAW_SQUARE
NEXT_P1_1_WRAP:
    mov color1, 20h
    jmp DRAW_SQUARE

NEXT_P1_CHK2:
    cmp selected, 02h
    jne NEXT_P1_CHK3
    mov al, color2
    cmp al, 70h
    je  NEXT_P1_2_WRAP
    add al, 10h
    mov color2, al
    jmp DRAW_SQUARE
NEXT_P1_2_WRAP:
    mov color2, 20h
    jmp DRAW_SQUARE

NEXT_P1_CHK3:
    cmp selected, 03h
    jne NEXT_P1_4
    mov al, color3
    cmp al, 70h
    je  NEXT_P1_3_WRAP
    add al, 10h
    mov color3, al
    jmp DRAW_SQUARE
NEXT_P1_3_WRAP:
    mov color3, 20h
    jmp DRAW_SQUARE

NEXT_P1_4:
    mov al, color4
    cmp al, 70h
    je  NEXT_P1_4_WRAP
    add al, 10h
    mov color4, al
    jmp DRAW_SQUARE
NEXT_P1_4_WRAP:
    mov color4, 20h
    jmp DRAW_SQUARE

NEXT_P2:
    cmp selected, 01h
    jne NEXT_P2_CHK2
    mov al, p2color1
    cmp al, 70h
    je  NEXT_P2_1_WRAP
    add al, 10h
    mov p2color1, al
    jmp DRAW_SQUARE
NEXT_P2_1_WRAP:
    mov p2color1, 20h
    jmp DRAW_SQUARE

NEXT_P2_CHK2:
    cmp selected, 02h
    jne NEXT_P2_CHK3
    mov al, p2color2
    cmp al, 70h
    je  NEXT_P2_2_WRAP
    add al, 10h
    mov p2color2, al
    jmp DRAW_SQUARE
NEXT_P2_2_WRAP:
    mov p2color2, 20h
    jmp DRAW_SQUARE

NEXT_P2_CHK3:
    cmp selected, 03h
    jne NEXT_P2_4
    mov al, p2color3
    cmp al, 70h
    je  NEXT_P2_3_WRAP
    add al, 10h
    mov p2color3, al
    jmp DRAW_SQUARE
NEXT_P2_3_WRAP:
    mov p2color3, 20h
    jmp DRAW_SQUARE

NEXT_P2_4:
    mov al, p2color4
    cmp al, 70h
    je  NEXT_P2_4_WRAP
    add al, 10h
    mov p2color4, al
    jmp DRAW_SQUARE
NEXT_P2_4_WRAP:
    mov p2color4, 20h
    jmp DRAW_SQUARE


COLOR_PREV:
    cmp turn, 01h
    je  PREV_P1
    jmp PREV_P2

PREV_P1:
    cmp selected, 01h
    jne PREV_P1_CHK2
    mov al, color1
    cmp al, 20h
    je  PREV_P1_1_WRAP
    sub al, 10h
    mov color1, al
    jmp DRAW_SQUARE
PREV_P1_1_WRAP:
    mov color1, 70h
    jmp DRAW_SQUARE

PREV_P1_CHK2:
    cmp selected, 02h
    jne PREV_P1_CHK3
    mov al, color2
    cmp al, 20h
    je  PREV_P1_2_WRAP
    sub al, 10h
    mov color2, al
    jmp DRAW_SQUARE
PREV_P1_2_WRAP:
    mov color2, 70h
    jmp DRAW_SQUARE

PREV_P1_CHK3:
    cmp selected, 03h
    jne PREV_P1_4
    mov al, color3
    cmp al, 20h
    je  PREV_P1_3_WRAP
    sub al, 10h
    mov color3, al
    jmp DRAW_SQUARE
PREV_P1_3_WRAP:
    mov color3, 70h
    jmp DRAW_SQUARE

PREV_P1_4:
    mov al, color4
    cmp al, 20h
    je  PREV_P1_4_WRAP
    sub al, 10h
    mov color4, al
    jmp DRAW_SQUARE
PREV_P1_4_WRAP:
    mov color4, 70h
    jmp DRAW_SQUARE

PREV_P2:
    cmp selected, 01h
    jne PREV_P2_CHK2
    mov al, p2color1
    cmp al, 20h
    je  PREV_P2_1_WRAP
    sub al, 10h
    mov p2color1, al
    jmp DRAW_SQUARE
PREV_P2_1_WRAP:
    mov p2color1, 70h
    jmp DRAW_SQUARE

PREV_P2_CHK2:
    cmp selected, 02h
    jne PREV_P2_CHK3
    mov al, p2color2
    cmp al, 20h
    je  PREV_P2_2_WRAP
    sub al, 10h
    mov p2color2, al
    jmp DRAW_SQUARE
PREV_P2_2_WRAP:
    mov p2color2, 70h
    jmp DRAW_SQUARE

PREV_P2_CHK3:
    cmp selected, 03h
    jne PREV_P2_4
    mov al, p2color3
    cmp al, 20h
    je  PREV_P2_3_WRAP
    sub al, 10h
    mov p2color3, al
    jmp DRAW_SQUARE
PREV_P2_3_WRAP:
    mov p2color3, 70h
    jmp DRAW_SQUARE

PREV_P2_4:
    mov al, p2color4
    cmp al, 20h
    je  PREV_P2_4_WRAP
    sub al, 10h
    mov p2color4, al
    jmp DRAW_SQUARE
PREV_P2_4_WRAP:
    mov p2color4, 70h
    jmp DRAW_SQUARE

EXIT:
    mov ah, 4ch
    int 21h
END