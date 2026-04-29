.model small
.stack 100h
.data
    ; =========================
    ; UI TEXT STRINGS
    ; =========================
    player1msg  db "Player1's turn: $"
    player2msg  db "Player2's turn: $"

    ; Instructions shown to players
    playermsg1 db "Press Left-Right-Arrow to change color $"
    playermsg2 db "and up down to go to the next or previous tile.$"
    playermsg3 db "Press [ENTER] to confirm color code.$"

    ; Game over messages
    uiMsg db "Game Over$"
    player1Win db "Player 1 Wins$"
    player2Win db "Player 2 Wins$"

    continue db "Press [ESC] to quit | Press [SPACE] to play again$"

    ; Player 2 statistics display
    p2Trys db "Try/s: $"
    p2CorrectPlacement db "Exact placement: $"
    p2WrongPlacement db " | Misplaced: $"

    ; =========================
    ; GAME STATE VARIABLES
    ; =========================
    p2TryCount db 0                   ; Number of attempts made by Player 2
    p2CorrectColorCount db 0          ; Number of correct colors guessed
    p2CorrectPlacementCount db 0      ; Number of correct positions guessed
    p2WrongPlacementCount db 0

    gameDone db 00h                   ; 1 if game is finished
    winner db 00h                     ; 1 = Player1, 2 = Player2
    maxTries db 10                    ; Maximum number of attempts allowed

    ; =========================
    ; COLOR STORAGE (ATTRIBUTES)
    ; =========================
    color1      db 70h
    color2      db 70h
    color3      db 70h
    color4      db 70h
    selected db 01h                   ; Currently selected tile (1–4)

    ; Turn tracking (1 = Player1, 2 = Player2)
    turn        db 01h

    ; Player 1's secret color combination
    p1color1    db 70h
    p1color2    db 70h
    p1color3    db 70h
    p1color4    db 70h

    ; Player 2's current guess
    p2color1    db 00h
    p2color2    db 00h
    p2color3    db 00h
    p2color4    db 00h

.code
start:
    ; Initialize data segment
    mov ax, @data
    mov ds, ax

    ; Start the main game loop
    call GAME_MAIN

    ; Exit program
    mov ah, 4ch
    int 21h

; =========================================================
; MAIN GAME CONTROLLER
; Handles full game lifecycle (restart, loop, exit)
; =========================================================
GAME_MAIN PROC
RESTART_GAME:
    call RESET_GAME_STATE      ; Reset all variables
    call INIT_SCREEN           ; Set video mode
    call DRAW_STATIC_LAYOUT    ; Draw background UI
    call DRAW_P2_ALL_BLACK     ; Draw hidden grid for guesses

FRAME_LOOP:
    call DRAW_FRAME            ; Render current frame

    ; Check if game is finished
    cmp gameDone, 01h
    je GAME_OVER_INPUT

    ; Handle gameplay input
    call HANDLE_GAME_KEYS         ; AL: 0=continue, 2=exit
    cmp al, 02h                   ; ESC pressed → exit
    je EXIT_GAME
    jmp FRAME_LOOP

GAME_OVER_INPUT:
    ; Handle input after game ends
    call HANDLE_RESULT_KEYS       ; AL: 0=wait, 1=restart, 2=exit
    cmp al, 01h                   ; ENTER → restart
    je RESTART_GAME
    cmp al, 02h                   ; ESC → exit
    je EXIT_GAME
    jmp FRAME_LOOP

EXIT_GAME:
    call CLEAR_SCREEN
    ret
GAME_MAIN ENDP

; =========================================================
; SCREEN INITIALIZATION
; Sets text mode and enables cursor
; =========================================================
INIT_SCREEN PROC
    ; show cursor
    mov ah, 01h
    mov ch, 06h
    mov cl, 07h
    int 10h

    ; Set video mode 3 (80x25 text)
    mov ah, 00h
    mov al, 03h
    int 10h
    ret
INIT_SCREEN ENDP

; =========================================================
; DRAW_RECT
; Draws a colored rectangle using BIOS scroll function
; Input:
;   BH = color attribute
;   CH,CL = top-left row/col
;   DH,DL = bottom-right row/col
; =========================================================
DRAW_RECT PROC
    ; expects: BH=color attr, CH=row1, CL=col1, DH=row2, DL=col2
    mov ah, 06h
    mov al, 00h
    int 10h
    ret
DRAW_RECT ENDP

; =========================================================
; CALC_P2_COL
; Calculates horizontal position of Player 2 guess column
; Each attempt shifts 5 columns to the right
; =========================================================
CALC_P2_COL PROC
    ; returns BL = 04h + (min(p2TryCount, maxTries-1) * 5)
    mov al, p2TryCount
    cmp al, maxTries
    jb CPC_IN_RANGE
    mov al, maxTries
    dec al
CPC_IN_RANGE:
    mov bl, al
    shl al, 1
    shl al, 1
    add al, bl          ; multiply by 5
    add al, 04h         ; base offset
    mov bl, al
    ret
CALC_P2_COL ENDP

; =========================================================
; DRAW_STATIC_LAYOUT
; Draws the main UI structure (background, grid, panel)
; =========================================================
DRAW_STATIC_LAYOUT PROC
    ; background
    mov bh, 10h
    mov ch, 00h
    mov cl, 00h
    mov dh, 18h
    mov dl, 4fh
    call DRAW_RECT

    ; instruction and feedback box
    mov bh, 30h
    mov ch, 01h
    mov cl, 04h
    mov dh, 17h
    mov dl, 4bh
    call DRAW_RECT

    ; game grid area
    mov bh, 10h
    mov ch, 06h
    mov cl, 04h
    mov dh, 12h
    mov dl, 4bh
    call DRAW_RECT
    ret
DRAW_STATIC_LAYOUT ENDP

; =========================================================
; DRAW_P1_SQUARES
; Displays Player 1's chosen colors (right side)
; =========================================================
DRAW_P1_SQUARES PROC
    ; Draw 4 vertically aligned squares
    mov bh, color1
    mov ch, 07h
    mov cl, 48h
    mov dh, 08h
    mov dl, 4bh
    call DRAW_RECT

    mov bh, color2
    mov ch, 0ah
    mov cl, 48h
    mov dh, 0bh
    mov dl, 4bh
    call DRAW_RECT

    mov bh, color3
    mov ch, 0dh
    mov cl, 48h
    mov dh, 0eh
    mov dl, 4bh
    call DRAW_RECT

    mov bh, color4
    mov ch, 10h
    mov cl, 48h
    mov dh, 11h
    mov dl, 4bh
    call DRAW_RECT
    ret
DRAW_P1_SQUARES ENDP

DRAW_P2_ACTIVE_SQUARES PROC
    call CALC_P2_COL

    mov bh, p2color1
    mov ch, 07h
    mov cl, bl
    mov dh, 08h
    mov dl, bl
    add dl, 03h
    call DRAW_RECT

    mov bh, p2color2
    mov ch, 0ah
    mov cl, bl
    mov dh, 0bh
    mov dl, bl
    add dl, 03h
    call DRAW_RECT

    mov bh, p2color3
    mov ch, 0dh
    mov cl, bl
    mov dh, 0eh
    mov dl, bl
    add dl, 03h
    call DRAW_RECT

    mov bh, p2color4
    mov ch, 10h
    mov cl, bl
    mov dh, 11h
    mov dl, bl
    add dl, 03h
    call DRAW_RECT
    ret
DRAW_P2_ACTIVE_SQUARES ENDP

DRAW_P2_STATS PROC
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
    mov dl, 24
    int 10h

    mov ah, 09h
    lea dx, p2CorrectPlacement
    int 21h
    mov al, p2CorrectPlacementCount
    call PRINT_DECIMAL

    mov ah, 09h
    lea dx, p2WrongPlacement
    int 21h
    mov al, p2WrongPlacementCount
    call PRINT_DECIMAL
    ret
DRAW_P2_STATS ENDP

PRINT_COLORED_STR PROC
    ; input: SI -> $-terminated text, BL = attribute, cursor already positioned
PCS_LOOP:
    mov al, [si]
    cmp al, '$'
    je PCS_DONE

    mov ah, 09h
    mov bh, 00h
    mov cx, 1
    int 10h

    inc dl
    mov ah, 02h
    int 10h

    inc si
    jmp PCS_LOOP
PCS_DONE:
    ret
PRINT_COLORED_STR ENDP

SET_ACTIVE_CURSOR PROC
    cmp turn, 01h
    je CURSOR_P1

    ; Player 2 cursor
    call CALC_P2_COL
    mov dl, bl
    cmp selected, 01h
    jne CURSOR_P2_2
    mov dh, 08h
    jmp CURSOR_SET
CURSOR_P2_2:
    cmp selected, 02h
    jne CURSOR_P2_3
    mov dh, 0bh
    jmp CURSOR_SET
CURSOR_P2_3:
    cmp selected, 03h
    jne CURSOR_P2_4
    mov dh, 0eh
    jmp CURSOR_SET
CURSOR_P2_4:
    mov dh, 11h
    jmp CURSOR_SET

CURSOR_P1:
    mov dl, 48h
    cmp selected, 01h
    jne CURSOR_P1_2
    mov dh, 08h
    jmp CURSOR_SET
CURSOR_P1_2:
    cmp selected, 02h
    jne CURSOR_P1_3
    mov dh, 0bh
    jmp CURSOR_SET
CURSOR_P1_3:
    cmp selected, 03h
    jne CURSOR_P1_4
    mov dh, 0eh
    jmp CURSOR_SET
CURSOR_P1_4:
    mov dh, 11h

CURSOR_SET:
    mov ah, 02h
    mov bh, 00h
    int 10h
    ret
SET_ACTIVE_CURSOR ENDP

DRAW_NORMAL_UI PROC
    ; heading line
    mov ah, 02h
    mov bh, 00h
    mov dh, 02
    mov dl, 12
    int 10h

    cmp turn, 01h
    jne DN_P2
    lea si, player1msg
    mov bl, 34h
    jmp DN_PRINT
DN_P2:
    lea si, player2msg
    mov bl, 35h
DN_PRINT:
    call PRINT_COLORED_STR

    ; instruction 1
    mov ah, 02h
    mov bh, 00h
    mov dh, 02
    int 10h
    mov ah, 09h
    lea dx, playermsg1
    int 21h

    ; instruction 2
    mov ah, 02h
    mov bh, 00h
    mov dh, 03
    mov dl, 16
    int 10h
    mov ah, 09h
    lea dx, playermsg2
    int 21h

    ; instruction 3
    mov ah, 02h
    mov bh, 00h
    mov dh, 04
    mov dl, 22
    int 10h
    mov ah, 09h
    lea dx, playermsg3
    int 21h

    call DRAW_P2_STATS
    call SET_ACTIVE_CURSOR
    ret
DRAW_NORMAL_UI ENDP

DRAW_GAME_OVER_UI PROC
    ; clear instruction area
    mov bh, 30h
    mov ch, 01h
    mov cl, 04h
    mov dh, 04h
    mov dl, 4bh
    call DRAW_RECT

    ; hide cursor
    mov ah, 01h
    mov ch, 20h
    mov cl, 00h
    int 10h

    ; Game Over
    mov ah, 02h
    mov bh, 00h
    mov dh, 02
    mov dl, 35
    int 10h
    mov ah, 09h
    lea dx, uiMsg
    int 21h

    ; winner
    mov ah, 02h
    mov bh, 00h
    mov dh, 03
    mov dl, 33
    int 10h
    cmp winner, 02h
    jne DGO_P1
    mov ah, 09h
    lea dx, player2Win
    int 21h
    jmp DGO_CONT
DGO_P1:
    mov ah, 09h
    lea dx, player1Win
    int 21h

DGO_CONT:
    mov ah, 02h
    mov bh, 00h
    mov dh, 04
    mov dl, 15
    int 10h
    mov ah, 09h
    lea dx, continue
    int 21h

    call DRAW_P2_STATS
    ret
DRAW_GAME_OVER_UI ENDP

DRAW_FRAME PROC
    call DRAW_P1_SQUARES

    cmp gameDone, 01h
    je DF_WIN

    call DRAW_P2_ACTIVE_SQUARES
    call DRAW_NORMAL_UI
    ret

DF_WIN:
    call DRAW_GAME_OVER_UI
    ret
DRAW_FRAME ENDP

HANDLE_RESULT_KEYS PROC
    ; AL: 0 wait, 1 restart, 2 exit
    mov ah, 00h
    int 16h

    cmp al, 1bh
    jne HRK_SPACE
    mov al, 02h
    ret
HRK_SPACE:
    cmp al, 20h
    jne HRK_WAIT
    call BEEP_CONFIRM
    mov al, 01h
    ret
HRK_WAIT:
    xor al, al
    ret
HANDLE_RESULT_KEYS ENDP


; =========================================================
; HANDLE_GAME_KEYS
; Processes keyboard input during gameplay
; Arrow keys → navigation & color change
; ENTER → confirm
; ESC → exit
; =========================================================
HANDLE_GAME_KEYS PROC
    ; AL: 0 continue, 2 exit
    mov ah, 00h
    int 16h

    ; Extended keys (arrows)
    cmp al, 00h
    jne HGK_ASCII

    cmp ah, 4bh
    jne HGK_RIGHT
    call COLOR_PREV       ; Left arrow
    xor al, al
    ret
HGK_RIGHT:
    cmp ah, 4dh
    jne HGK_UP
    call COLOR_NEXT       ; Right arrow
    xor al, al
    ret
HGK_UP:
    cmp ah, 48h
    jne HGK_DOWN
    call SELECT_UP        ; Move selection up
    xor al, al
    ret
HGK_DOWN:
    cmp ah, 50h
    jne HGK_CONT
    call SELECT_DOWN      ; Move selection down
    xor al, al
    ret

; ASCII keys
HGK_ASCII:
    cmp al, 1bh
    jne HGK_ENTER
    mov al, 02h           ; ESC → exit
    ret

HGK_ENTER:
    cmp al, 0dh
    jne HGK_CONT

    ; ENTER → confirm input
    call BEEP_CONFIRM

    cmp turn, 01h
    jne HGK_P2
    call COMMIT_P1_AND_SWITCH
    xor al, al
    ret
HGK_P2:
    call COMMIT_P2_AND_COMPARE
    xor al, al
    ret

HGK_CONT:
    xor al, al
    ret
HANDLE_GAME_KEYS ENDP

; =========================================================
; COMMIT_P1_AND_SWITCH
; Saves Player 1's chosen colors and switches to Player 2
; =========================================================
COMMIT_P1_AND_SWITCH PROC
    ; Copy selected colors into secret code
    mov al, color1
    mov p1color1, al
    mov al, color2
    mov p1color2, al
    mov al, color3
    mov p1color3, al
    mov al, color4
    mov p1color4, al

    ; Clear visible colors (hide solution)
    mov color1, 00h
    mov color2, 00h
    mov color3, 00h
    mov color4, 00h

    ; Initialize Player 2 guess slots
    mov p2color1, 70h
    mov p2color2, 70h
    mov p2color3, 70h
    mov p2color4, 70h

    mov selected, 01h
    mov turn, 02h         ; Switch turn
    ret
COMMIT_P1_AND_SWITCH ENDP

; =========================================================
; COMMIT_P2_AND_COMPARE
; Evaluates Player 2 guess vs Player 1 solution
; Updates stats and determines winner
; =========================================================
COMMIT_P2_AND_COMPARE PROC
    inc p2TryCount

    ; Reset counters
    mov p2CorrectColorCount, 0
    mov p2CorrectPlacementCount, 0
    mov p2WrongPlacementCount, 0

    ; ---- Comparison logic per square ----
    ; Checks exact match (position + color)
    ; Then checks color-only match
    ; (Same logic repeated for 4 slots)
    ; → increments placement and/or color counters

    ; square 1
    mov al, p2color1
    cmp al, p1color1
    jne C2C_S1_COLOR_ONLY
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    jmp C2C_S2
C2C_S1_COLOR_ONLY:
    cmp al, p1color2
    je C2C_S1_HIT
    cmp al, p1color3
    je C2C_S1_HIT
    cmp al, p1color4
    jne C2C_S2
C2C_S1_HIT:
    inc p2CorrectColorCount

C2C_S2:
    mov al, p2color2
    cmp al, p1color2
    jne C2C_S2_COLOR_ONLY
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    jmp C2C_S3
C2C_S2_COLOR_ONLY:
    cmp al, p1color1
    je C2C_S2_HIT
    cmp al, p1color3
    je C2C_S2_HIT
    cmp al, p1color4
    jne C2C_S3
C2C_S2_HIT:
    inc p2CorrectColorCount

C2C_S3:
    mov al, p2color3
    cmp al, p1color3
    jne C2C_S3_COLOR_ONLY
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    jmp C2C_S4
C2C_S3_COLOR_ONLY:
    cmp al, p1color1
    je C2C_S3_HIT
    cmp al, p1color2
    je C2C_S3_HIT
    cmp al, p1color4
    jne C2C_S4
C2C_S3_HIT:
    inc p2CorrectColorCount

C2C_S4:
    mov al, p2color4
    cmp al, p1color4
    jne C2C_S4_COLOR_ONLY
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    jmp C2C_CHECK
C2C_S4_COLOR_ONLY:
    cmp al, p1color1
    je C2C_S4_HIT
    cmp al, p1color2
    je C2C_S4_HIT
    cmp al, p1color3
    jne C2C_CHECK
C2C_S4_HIT:
    inc p2CorrectColorCount

; ---- Win conditions ---- 
C2C_CHECK:
    cmp p2CorrectPlacementCount, 04h
    je C2C_P2_WIN

    mov al, p2CorrectColorCount
    sub al, p2CorrectPlacementCount
    mov p2WrongPlacementCount, al

    mov al, p2TryCount
    cmp al, maxTries
    jae C2C_P1_WIN

    ; Reset guess row if not finished
    mov selected, 01h
    mov p2color1, 70h
    mov p2color2, 70h
    mov p2color3, 70h
    mov p2color4, 70h
    ret

C2C_P2_WIN:
    mov winner, 02h
    call FINISH_GAME_REVEAL
    ret

C2C_P1_WIN:
    mov winner, 01h
    call FINISH_GAME_REVEAL
    ret
COMMIT_P2_AND_COMPARE ENDP

; =========================================================
; FINISH_GAME_REVEAL
; Reveals Player 1's secret combination at end of game
; =========================================================
FINISH_GAME_REVEAL PROC
    mov al, p1color1
    mov color1, al
    mov al, p1color2
    mov color2, al
    mov al, p1color3
    mov color3, al
    mov al, p1color4
    mov color4, al

    mov gameDone, 01h
    ret
FINISH_GAME_REVEAL ENDP

SELECT_UP PROC
    call BEEP_HIGH              ; Play high beep when up arrow pressed
    
    cmp selected, 01h
    jne SU_DEC
    mov selected, 04h
    ret
SU_DEC:
    dec selected
    ret
SELECT_UP ENDP

SELECT_DOWN PROC
    call BEEP_LOW               ; Play low beep when down arrow pressed
    
    cmp selected, 04h
    jne SD_INC
    mov selected, 01h
    ret
SD_INC:
    inc selected
    ret
SELECT_DOWN ENDP

COLOR_NEXT PROC
    call BEEP_HIGH              ; Play high beep when right arrow pressed
    
    cmp turn, 01h
    jne CN_P2

    cmp selected, 01h
    jne CN_P1_2
    mov al, color1
    cmp al, 70h
    je CN_P1_1_WRAP
    add al, 10h
    mov color1, al
    ret
CN_P1_1_WRAP:
    mov color1, 20h
    ret

CN_P1_2:
    cmp selected, 02h
    jne CN_P1_3
    mov al, color2
    cmp al, 70h
    je CN_P1_2_WRAP
    add al, 10h
    mov color2, al
    ret
CN_P1_2_WRAP:
    mov color2, 20h
    ret

CN_P1_3:
    cmp selected, 03h
    jne CN_P1_4
    mov al, color3
    cmp al, 70h
    je CN_P1_3_WRAP
    add al, 10h
    mov color3, al
    ret
CN_P1_3_WRAP:
    mov color3, 20h
    ret

CN_P1_4:
    mov al, color4
    cmp al, 70h
    je CN_P1_4_WRAP
    add al, 10h
    mov color4, al
    ret
CN_P1_4_WRAP:
    mov color4, 20h
    ret

CN_P2:
    cmp selected, 01h
    jne CN_P2_2
    mov al, p2color1
    cmp al, 70h
    je CN_P2_1_WRAP
    add al, 10h
    mov p2color1, al
    ret
CN_P2_1_WRAP:
    mov p2color1, 20h
    ret

CN_P2_2:
    cmp selected, 02h
    jne CN_P2_3
    mov al, p2color2
    cmp al, 70h
    je CN_P2_2_WRAP
    add al, 10h
    mov p2color2, al
    ret
CN_P2_2_WRAP:
    mov p2color2, 20h
    ret

CN_P2_3:
    cmp selected, 03h
    jne CN_P2_4
    mov al, p2color3
    cmp al, 70h
    je CN_P2_3_WRAP
    add al, 10h
    mov p2color3, al
    ret
CN_P2_3_WRAP:
    mov p2color3, 20h
    ret

CN_P2_4:
    mov al, p2color4
    cmp al, 70h
    je CN_P2_4_WRAP
    add al, 10h
    mov p2color4, al
    ret
CN_P2_4_WRAP:
    mov p2color4, 20h
    ret
COLOR_NEXT ENDP

COLOR_PREV PROC
    call BEEP_LOW               ; Play low beep when left arrow pressed
    
    cmp turn, 01h
    jne CP_P2

    cmp selected, 01h
    jne CP_P1_2
    mov al, color1
    cmp al, 20h
    je CP_P1_1_WRAP
    sub al, 10h
    mov color1, al
    ret
CP_P1_1_WRAP:
    mov color1, 70h
    ret

CP_P1_2:
    cmp selected, 02h
    jne CP_P1_3
    mov al, color2
    cmp al, 20h
    je CP_P1_2_WRAP
    sub al, 10h
    mov color2, al
    ret
CP_P1_2_WRAP:
    mov color2, 70h
    ret

CP_P1_3:
    cmp selected, 03h
    jne CP_P1_4
    mov al, color3
    cmp al, 20h
    je CP_P1_3_WRAP
    sub al, 10h
    mov color3, al
    ret
CP_P1_3_WRAP:
    mov color3, 70h
    ret

CP_P1_4:
    mov al, color4
    cmp al, 20h
    je CP_P1_4_WRAP
    sub al, 10h
    mov color4, al
    ret
CP_P1_4_WRAP:
    mov color4, 70h
    ret

CP_P2:
    cmp selected, 01h
    jne CP_P2_2
    mov al, p2color1
    cmp al, 20h
    je CP_P2_1_WRAP
    sub al, 10h
    mov p2color1, al
    ret
CP_P2_1_WRAP:
    mov p2color1, 70h
    ret

CP_P2_2:
    cmp selected, 02h
    jne CP_P2_3
    mov al, p2color2
    cmp al, 20h
    je CP_P2_2_WRAP
    sub al, 10h
    mov p2color2, al
    ret
CP_P2_2_WRAP:
    mov p2color2, 70h
    ret

CP_P2_3:
    cmp selected, 03h
    jne CP_P2_4
    mov al, p2color3
    cmp al, 20h
    je CP_P2_3_WRAP
    sub al, 10h
    mov p2color3, al
    ret
CP_P2_3_WRAP:
    mov p2color3, 70h
    ret

CP_P2_4:
    mov al, p2color4
    cmp al, 20h
    je CP_P2_4_WRAP
    sub al, 10h
    mov p2color4, al
    ret
CP_P2_4_WRAP:
    mov p2color4, 70h
    ret
COLOR_PREV ENDP

PRINT_DECIMAL PROC
    aam
    add ax, 3030h
    cmp ah, '0'
    jne PD_TWO

    mov dl, al
    mov ah, 02h
    int 21h
    ret

PD_TWO:
    mov bl, al
    mov dl, ah
    mov ah, 02h
    int 21h

    mov dl, bl
    mov ah, 02h
    int 21h
    ret
PRINT_DECIMAL ENDP

DRAW_P2_ALL_BLACK PROC
    mov bl, 04h
    mov si, 10
DPAB_COL_LOOP:
    mov bh, 00h
    mov ch, 07h
    mov cl, bl
    mov dh, 08h
    mov dl, bl
    add dl, 03h
    call DRAW_RECT

    mov bh, 00h
    mov ch, 0ah
    mov cl, bl
    mov dh, 0bh
    mov dl, bl
    add dl, 03h
    call DRAW_RECT

    mov bh, 00h
    mov ch, 0dh
    mov cl, bl
    mov dh, 0eh
    mov dl, bl
    add dl, 03h
    call DRAW_RECT

    mov bh, 00h
    mov ch, 10h
    mov cl, bl
    mov dh, 11h
    mov dl, bl
    add dl, 03h
    call DRAW_RECT

    add bl, 05h
    dec si
    jnz DPAB_COL_LOOP
    ret
DRAW_P2_ALL_BLACK ENDP

; =========================================================
; RESET_GAME_STATE
; Initializes all variables for a new game
; =========================================================
RESET_GAME_STATE PROC
    mov p2TryCount, 0
    mov p2CorrectColorCount, 0
    mov p2CorrectPlacementCount, 0
    mov p2WrongPlacementCount, 0

    mov gameDone, 00h
    mov winner, 00h

    mov selected, 01h
    mov turn, 01h

    mov color1, 70h
    mov color2, 70h
    mov color3, 70h
    mov color4, 70h

    mov p1color1, 70h
    mov p1color2, 70h
    mov p1color3, 70h
    mov p1color4, 70h

    mov p2color1, 00h
    mov p2color2, 00h
    mov p2color3, 00h
    mov p2color4, 00h
    ret
RESET_GAME_STATE ENDP

; =========================================================
; CLEAR_SCREEN
; Clears entire screen using BIOS interrupt
; =========================================================
CLEAR_SCREEN PROC
    mov ah, 06h
    mov al, 00h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184fh
    int 10h
    ret
CLEAR_SCREEN ENDP

; =========================================================
; BEEP_HIGH
; Plays a high-pitched beep (for right arrow)
; =========================================================
BEEP_HIGH PROC
    push ax
    push bx
    push cx
    push dx

    ; Program timer chip for high frequency (higher pitch)
    mov al, 0b6h            ; Timer control byte
    out 43h, al
    
    mov ax, 1000            ; Frequency divisor (smaller = higher pitch)
    out 42h, al
    mov al, ah
    out 42h, al

    ; Enable speaker
    in al, 61h
    or al, 03h
    out 61h, al

    ; Delay loop (duration of sound)
    mov cx, 8000
BH_WAIT:
    loop BH_WAIT

    ; Disable speaker
    in al, 61h
    and al, 0fch
    out 61h, al

    pop dx
    pop cx
    pop bx
    pop ax
    ret
BEEP_HIGH ENDP

; =========================================================
; BEEP_LOW
; Plays a low-pitched beep (for left arrow)
; =========================================================
BEEP_LOW PROC
    push ax
    push bx
    push cx
    push dx

    ; Program timer chip for low frequency (lower pitch)
    mov al, 0b6h            ; Timer control byte
    out 43h, al
    
    mov ax, 1500            ; Frequency divisor (larger = lower pitch)
    out 42h, al
    mov al, ah
    out 42h, al

    ; Enable speaker
    in al, 61h
    or al, 03h
    out 61h, al

    ; Delay loop (duration of sound)
    mov cx, 8000
BL_WAIT:
    loop BL_WAIT

    ; Disable speaker
    in al, 61h
    and al, 0fch
    out 61h, al

    pop dx
    pop cx
    pop bx
    pop ax
    ret
BEEP_LOW ENDP

; =========================================================
; BEEP_CONFIRM
; Plays a middle-pitched beep (for confirm/Enter)
; =========================================================
BEEP_CONFIRM PROC
    push ax
    push bx
    push cx
    push dx

    ; Program timer chip for middle frequency
    mov al, 0b6h            ; Timer control byte
    out 43h, al
    
    mov ax, 1200            ; Frequency divisor (middle pitch)
    out 42h, al
    mov al, ah
    out 42h, al

    ; Enable speaker
    in al, 61h
    or al, 03h
    out 61h, al

    ; Delay loop (duration of sound)
    mov cx, 8000
BC_WAIT:
    loop BC_WAIT

    ; Disable speaker
    in al, 61h
    and al, 0fch
    out 61h, al

    pop dx
    pop cx
    pop bx
    pop ax
    ret
BEEP_CONFIRM ENDP

END start