.model small
.stack 100h
.data
    player1msg  db "Player1's turn: $"
    player2msg  db "Player2's turn: $"

    playermsg1 db "Press Left-Right-Arrow to change color $"
    playermsg2 db "and up down to go to the next or previous tile.$"
    playermsg3 db "Press [ENTER] to confirm color code.$"

    uiMsg db "Game Over$"
    player1Win db "Player 1 Wins$"
    player2Win db "Player 2 Wins$"

    continue db "Press [ESC] to quit | Press [ENTER] to play again$"

    p2Trys db "Try/s: $"
    p2CorrectColor db "Correct Color/s: $"
    p2CorrectPlacement db " | Correct Placement/s: $"

    p2TryCount db 0
    p2CorrectColorCount db 0
    p2CorrectPlacementCount db 0

    gameDone db 00h
    winner db 00h    ; 1 = p1, 2 = p2
    maxTries db 10
    
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

    ;player 2 squares try col 2
    ; draw square 1 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0709h
    mov dx, 080ch
    int 10h

    ; draw square 2 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0a09h
    mov dx, 0b0ch
    int 10h

    ; draw square 3 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0d09h
    mov dx, 0e0ch
    int 10h

    ; draw square 4 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 1009h
    mov dx, 110ch
    int 10h

    ;player 2 squares try col 3
    ; draw square 1 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 070eh
    mov dx, 0811h
    int 10h

    ; draw square 2 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0a0eh
    mov dx, 0b11h
    int 10h

    ; draw square 3 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0d0eh
    mov dx, 0e11h
    int 10h

    ; draw square 4 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 100eh
    mov dx, 1111h
    int 10h

    ;player 2 squares try col 4
    ; draw square 1 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0713h
    mov dx, 0816h
    int 10h

    ; draw square 2 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0a13h
    mov dx, 0b16h
    int 10h

    ; draw square 3 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0d13h
    mov dx, 0e16h
    int 10h

    ; draw square 4 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 1013h
    mov dx, 1116h
    int 10h

    ;player 2 squares try col 5
    ; draw square 1 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0718h
    mov dx, 081bh
    int 10h

    ; draw square 2 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0a18h
    mov dx, 0b1bh
    int 10h

    ; draw square 3 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0d18h
    mov dx, 0e1bh
    int 10h

    ; draw square 4 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 1018h
    mov dx, 111bh
    int 10h

    ;player 2 squares try col 6
    ; draw square 1 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 071dh
    mov dx, 0820h
    int 10h

    ; draw square 2 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0a1dh
    mov dx, 0b20h
    int 10h

    ; draw square 3 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0d1dh
    mov dx, 0e20h
    int 10h

    ; draw square 4 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 101dh
    mov dx, 1120h
    int 10h

    ;player 2 squares try col 7
    ; draw square 1 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0722h
    mov dx, 0825h
    int 10h

    ; draw square 2 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0a22h
    mov dx, 0b25h
    int 10h

    ; draw square 3 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0d22h
    mov dx, 0e25h
    int 10h

    ; draw square 4 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 1022h
    mov dx, 1125h
    int 10h

    ;player 2 squares try col 8
    ; draw square 1 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0727h
    mov dx, 082ah
    int 10h

    ; draw square 2 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0a27h
    mov dx, 0b2ah
    int 10h

    ; draw square 3 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0d27h
    mov dx, 0e2ah
    int 10h

    ; draw square 4 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 1027h
    mov dx, 112ah
    int 10h

    ;player 2 squares try col 9
    ; draw square 1 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 072ch
    mov dx, 082fh
    int 10h

    ; draw square 2 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0a2ch
    mov dx, 0b2fh
    int 10h

    ; draw square 3 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0d2ch
    mov dx, 0e2fh
    int 10h

    ; draw square 4 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 102ch
    mov dx, 112fh
    int 10h

    ;player 2 squares try col 10
    ; draw square 1 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0731h
    mov dx, 0834h
    int 10h

    ; draw square 2 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0a31h
    mov dx, 0b34h
    int 10h

    ; draw square 3 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 0d31h
    mov dx, 0e34h
    int 10h

    ; draw square 4 
    mov ah, 6
    mov al, 00h
    mov bh, 70h
    mov cx, 1031h
    mov dx, 1134h
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

    ; player 2 active try column = 04h + (p2TryCount * 5)
    mov al, p2TryCount
    mov bl, al
    shl al, 1
    shl al, 1
    add al, bl
    add al, 04h
    mov bl, al ; BL = left column

    ; draw square 1
    mov ah, 06h
    mov al, 00h
    mov bh, p2color1
    mov ch, 07h
    mov cl, bl
    mov dh, 08h
    mov dl, bl
    add dl, 03h
    int 10h

    ; draw square 2
    mov ah, 06h
    mov al, 00h
    mov bh, p2color2
    mov ch, 0Ah
    mov cl, bl
    mov dh, 0Bh
    mov dl, bl
    add dl, 03h
    int 10h

    ; draw square 3
    mov ah, 06h
    mov al, 00h
    mov bh, p2color3
    mov ch, 0Dh
    mov cl, bl
    mov dh, 0Eh
    mov dl, bl
    add dl, 03h
    int 10h

    ; draw square 4
    mov ah, 06h
    mov al, 00h
    mov bh, p2color4
    mov ch, 10h
    mov cl, bl
    mov dh, 11h
    mov dl, bl
    add dl, 03h
    int 10h

    cmp gameDone, 01h
    je  SHOW_WIN_ONLY
    jmp NORMAL_UI

DRAW_P2_STATS:
    mov ah, 02h
    mov bh, 00h
    mov dh, 20
    mov dl, 36
    int 10h
    mov ah, 09h
    lea dx, p2Trys
    int 21h
    mov al, p2TryCount
    call PRINT_DECIMAL

    mov ah, 02h
    mov bh, 00h
    mov dh, 22
    mov dl, 20
    int 10h
    mov ah, 09h
    lea dx, p2CorrectColor
    int 21h
    mov al, p2CorrectColorCount
    call PRINT_DECIMAL

    mov ah, 09h
    lea dx, p2CorrectPlacement
    int 21h
    mov al, p2CorrectPlacementCount
    call PRINT_DECIMAL
    ret

SHOW_WIN_ONLY:
    ; clear instruction area (rows 1..4, cols 4..75)
    mov ah, 06h
    mov al, 00h
    mov bh, 30h
    mov cx, 0104h
    mov dx, 044Bh
    int 10h

    ; hide text cursor on game-over screen
    mov ah, 01h
    mov ch, 20h
    mov cl, 00h
    int 10h

    ; print "Game Over"
    mov ah, 02h
    mov bh, 00h
    mov dh, 02
    mov dl, 35
    int 10h

    mov ah, 09h
    lea dx, uiMsg
    int 21h

    ; print winner under Game Over
    mov ah, 02h
    mov bh, 00h
    mov dh, 03
    mov dl, 33
    int 10h

    cmp winner, 02h
    jne SHOW_P1_WIN
    mov ah, 09h
    lea dx, player2Win
    int 21h
    jmp SHOW_CONTINUE

SHOW_P1_WIN:
    mov ah, 09h
    lea dx, player1Win
    int 21h

SHOW_CONTINUE:
    ; print "Continue"
    mov ah, 02h
    mov bh, 00h
    mov dh, 04
    mov dl, 15
    int 10h

    mov ah, 09h
    lea dx, continue
    int 21h

SHOW_STATS:
    call DRAW_P2_STATS
    jmp RESULT_LOOP

NORMAL_UI:
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

    call DRAW_P2_STATS

    cmp turn, 01h
    je  P1_CURSOR
    
P2_CURSOR:
    ; cursor column = 04h + (p2TryCount * 5)
    mov al, p2TryCount
    mov bl, al
    shl al, 1
    shl al, 1
    add al, bl
    add al, 04h
    mov dl, al

    cmp selected, 01h
    jne P2_CHK2
    mov dh, 08h
    jmp SET_CURSOR

P2_CHK2:
    cmp selected, 02h
    jne P2_CHK3
    mov dh, 0Bh
    jmp SET_CURSOR

P2_CHK3:
    cmp selected, 03h
    jne P2_SQ4
    mov dh, 0Eh
    jmp SET_CURSOR

P2_SQ4:
    mov dh, 11h
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

    cmp gameDone, 01h
    je  RESULT_LOOP
    jmp KEY_LOOP

RESULT_LOOP:
    mov ah, 00h
    int 16h
    cmp al, 1Bh
    jne RESULT_LOOP
    jmp EXIT

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
    jmp CLEAR_SCREEN

CHECK_ENTER:
    cmp al, 0Dh
    jne KEY_LOOP
    cmp turn, 01h
    je COMMIT_P1_AND_SWITCH
    jmp COMMIT_P2_AND_COMPARE

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

    mov color1, 00h
    mov color2, 00h
    mov color3, 00h
    mov color4, 00h

    mov p2color1, 70h
    mov p2color2, 70h
    mov p2color3, 70h
    mov p2color4, 70h
    
    mov selected, 01h
    mov turn, 02h

    jmp DRAW_SQUARE

COMMIT_P2_AND_COMPARE:
    ; record stats
    inc p2TryCount
    mov p2CorrectColorCount, 0
    mov p2CorrectPlacementCount, 0
    
    ; square 1: exact first
    mov al, p2color1
    cmp al, p1color1
    jne P2_S1_CHK_COLOR
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    jmp P2_S2

P2_S1_CHK_COLOR:
    cmp al, p1color2
    je  P2_S1_COLOR
    cmp al, p1color3
    je  P2_S1_COLOR
    cmp al, p1color4
    je  P2_S1_COLOR
    jmp P2_S2

P2_S1_COLOR:
    inc p2CorrectColorCount

P2_S2:
    mov al, p2color2
    cmp al, p1color2
    jne P2_S2_CHK_COLOR
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    jmp P2_S3

P2_S2_CHK_COLOR:
    cmp al, p1color1
    je  P2_S2_COLOR
    cmp al, p1color3
    je  P2_S2_COLOR
    cmp al, p1color4
    je  P2_S2_COLOR
    jmp P2_S3

P2_S2_COLOR:
    inc p2CorrectColorCount

P2_S3:
    mov al, p2color3
    cmp al, p1color3
    jne P2_S3_CHK_COLOR
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    jmp P2_S4

P2_S3_CHK_COLOR:
    cmp al, p1color1
    je  P2_S3_COLOR
    cmp al, p1color2
    je  P2_S3_COLOR
    cmp al, p1color4
    je  P2_S3_COLOR
    jmp P2_S4

P2_S3_COLOR:
    inc p2CorrectColorCount

P2_S4:
    mov al, p2color4
    cmp al, p1color4
    jne P2_S4_CHK_COLOR
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    jmp CHECK_P2_WIN

P2_S4_CHK_COLOR:
    cmp al, p1color1
    je  P2_S4_COLOR
    cmp al, p1color2
    je  P2_S4_COLOR
    cmp al, p1color3
    je  P2_S4_COLOR
    jmp CHECK_P2_WIN

P2_S4_COLOR:
    inc p2CorrectColorCount

CHECK_P2_WIN:
    cmp p2CorrectPlacementCount, 04h
    je  P2_WINS_NOW

    ; not exact match: check if out of tries
    mov al, p2TryCount
    cmp al, maxTries
    jae P1_WINS_TRIES

    ; still has tries left -> continue game on next column
    mov selected, 01h
    mov p2color1, 70h
    mov p2color2, 70h
    mov p2color3, 70h
    mov p2color4, 70h
    jmp DRAW_SQUARE
    
P2_WINS_NOW:
    mov winner, 02h
    jmp FINISH_GAME_REVEAL

P1_WINS_TRIES:
    mov winner, 01h
    jmp FINISH_GAME_REVEAL

FINISH_GAME_REVEAL:
    ; reveal saved player1 code only now
    mov al, p1color1
    mov color1, al
    mov al, p1color2
    mov color2, al
    mov al, p1color3
    mov color3, al
    mov al, p1color4
    mov color4, al

    mov gameDone, 01h
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

PRINT_DECIMAL:
    aam
    add ax, 3030h
    cmp ah, '0'
    jne PRINT_TWO_DIGITS

    mov dl, al
    mov ah, 02h
    int 21h
    ret

PRINT_TWO_DIGITS:
    mov bl, al        ; save ones digit
    mov dl, ah        ; tens digit
    mov ah, 02h
    int 21h

    mov dl, bl        ; restore ones digit
    mov ah, 02h
    int 21h
    ret

CLEAR_SCREEN:
    ; scroll entire screen up (clear it)
    mov ah, 06h
    mov al, 00h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184fh
    int 10h
    jmp EXIT

EXIT:
    mov ah, 4ch
    int 21h
END