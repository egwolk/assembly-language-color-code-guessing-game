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
    player1Win db "Player1 Wins$"
    player2Win db "Player2 Wins$"

    continue db "Press [ESC] to quit | Press [SPACE] to play again$"

    ; =========================
    ; PLAYER 1 WIN SCREEN STRINGS (from p1win.asm)
    ; =========================
    p1winMsg  db 'Player1 Wins!$'
    p1winMsg2 db 'Like a true Master Mind$'
    p1winMsg3 db '[SPACE] RESTART$'
    p1winMsg4 db '[ESC]      QUIT$'
    p1winStat1 db 'Tries: $'
    p1winStat2 db 'Exact: $'
    p1winStat3 db 'Mispl: $'

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

    ; Temporary match flags used while scoring Player 2's guess
    p1slotUsed1 db 0
    p1slotUsed2 db 0
    p1slotUsed3 db 0
    p1slotUsed4 db 0
    p2slotUsed1 db 0
    p2slotUsed2 db 0
    p2slotUsed3 db 0
    p2slotUsed4 db 0

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

    ; Disable blink so all 16 colors work as backgrounds
    mov ax, 1003h
    mov bx, 0000h
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
    mov bh, 010h
    mov ch, 00h
    mov cl, 00h
    mov dh, 18h
    mov dl, 4fh
    call DRAW_RECT

    ; instruction and feedback box
    mov bh, 030h
    mov ch, 01h
    mov cl, 04h
    mov dh, 17h
    mov dl, 4bh
    call DRAW_RECT

    ; game grid area
    mov bh, 010h
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

    lea si, p2CorrectPlacement
    mov bl, 32h
    call PRINT_COLORED_STR
    mov al, p2CorrectPlacementCount
    mov bl, 32h
    call PRINT_DECIMAL_COLORED

    mov ah, 02h
    mov bh, 00h
    mov dh, 22
    mov dl, 42
    int 10h

    lea si, p2WrongPlacement
    mov bl, 36h
    call PRINT_COLORED_STR
    mov al, p2WrongPlacementCount
    mov bl, 36h
    call PRINT_DECIMAL_COLORED
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
    ; If Player 1 wins, show the full win splash screen instead
    cmp winner, 01h
    jne DGO_NOT_P1WIN
    call DRAW_P1_WIN_SCREEN
    ret
DGO_NOT_P1WIN:

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
    lea si, player2Win
    mov bl, 35h
    call PRINT_COLORED_STR
    jmp DGO_CONT
DGO_P1:
    lea si, player1Win
    mov bl, 34h
    call PRINT_COLORED_STR

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

    ; Clear temporary match flags
    mov p1slotUsed1, 00h
    mov p1slotUsed2, 00h
    mov p1slotUsed3, 00h
    mov p1slotUsed4, 00h
    mov p2slotUsed1, 00h
    mov p2slotUsed2, 00h
    mov p2slotUsed3, 00h
    mov p2slotUsed4, 00h

    ; First pass: exact placement matches
    mov al, p2color1
    cmp al, p1color1
    jne C2C_EXACT_2
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed1, 01h
    mov p2slotUsed1, 01h
C2C_EXACT_2:
    mov al, p2color2
    cmp al, p1color2
    jne C2C_EXACT_3
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed2, 01h
    mov p2slotUsed2, 01h
C2C_EXACT_3:
    mov al, p2color3
    cmp al, p1color3
    jne C2C_EXACT_4
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed3, 01h
    mov p2slotUsed3, 01h
C2C_EXACT_4:
    mov al, p2color4
    cmp al, p1color4
    jne C2C_MISPLACED_1
    inc p2CorrectPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed4, 01h
    mov p2slotUsed4, 01h

    ; Second pass: misplaced matches only use remaining unmatched slots
C2C_MISPLACED_1:
    cmp p2slotUsed1, 01h
    je C2C_MISPLACED_2
    mov al, p2color1

    cmp p1slotUsed1, 01h
    je C2C_G1_S2
    cmp al, p1color1
    jne C2C_G1_S2
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed1, 01h
    jmp C2C_MISPLACED_2
C2C_G1_S2:
    cmp p1slotUsed2, 01h
    je C2C_G1_S3
    cmp al, p1color2
    jne C2C_G1_S3
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed2, 01h
    jmp C2C_MISPLACED_2
C2C_G1_S3:
    cmp p1slotUsed3, 01h
    je C2C_G1_S4
    cmp al, p1color3
    jne C2C_G1_S4
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed3, 01h
    jmp C2C_MISPLACED_2
C2C_G1_S4:
    cmp p1slotUsed4, 01h
    je C2C_MISPLACED_2
    cmp al, p1color4
    jne C2C_MISPLACED_2
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed4, 01h

C2C_MISPLACED_2:
    cmp p2slotUsed2, 01h
    je C2C_MISPLACED_3
    mov al, p2color2

    cmp p1slotUsed1, 01h
    je C2C_G2_S2
    cmp al, p1color1
    jne C2C_G2_S2
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed1, 01h
    jmp C2C_MISPLACED_3
C2C_G2_S2:
    cmp p1slotUsed2, 01h
    je C2C_G2_S3
    cmp al, p1color2
    jne C2C_G2_S3
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed2, 01h
    jmp C2C_MISPLACED_3
C2C_G2_S3:
    cmp p1slotUsed3, 01h
    je C2C_G2_S4
    cmp al, p1color3
    jne C2C_G2_S4
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed3, 01h
    jmp C2C_MISPLACED_3
C2C_G2_S4:
    cmp p1slotUsed4, 01h
    je C2C_MISPLACED_3
    cmp al, p1color4
    jne C2C_MISPLACED_3
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed4, 01h

C2C_MISPLACED_3:
    cmp p2slotUsed3, 01h
    je C2C_MISPLACED_4
    mov al, p2color3

    cmp p1slotUsed1, 01h
    je C2C_G3_S2
    cmp al, p1color1
    jne C2C_G3_S2
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed1, 01h
    jmp C2C_MISPLACED_4
C2C_G3_S2:
    cmp p1slotUsed2, 01h
    je C2C_G3_S3
    cmp al, p1color2
    jne C2C_G3_S3
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed2, 01h
    jmp C2C_MISPLACED_4
C2C_G3_S3:
    cmp p1slotUsed3, 01h
    je C2C_G3_S4
    cmp al, p1color3
    jne C2C_G3_S4
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed3, 01h
    jmp C2C_MISPLACED_4
C2C_G3_S4:
    cmp p1slotUsed4, 01h
    je C2C_MISPLACED_4
    cmp al, p1color4
    jne C2C_MISPLACED_4
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed4, 01h

C2C_MISPLACED_4:
    cmp p2slotUsed4, 01h
    je C2C_CHECK
    mov al, p2color4

    cmp p1slotUsed1, 01h
    je C2C_G4_S2
    cmp al, p1color1
    jne C2C_G4_S2
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed1, 01h
    jmp C2C_CHECK
C2C_G4_S2:
    cmp p1slotUsed2, 01h
    je C2C_G4_S3
    cmp al, p1color2
    jne C2C_G4_S3
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed2, 01h
    jmp C2C_CHECK
C2C_G4_S3:
    cmp p1slotUsed3, 01h
    je C2C_G4_S4
    cmp al, p1color3
    jne C2C_G4_S4
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed3, 01h
    jmp C2C_CHECK
C2C_G4_S4:
    cmp p1slotUsed4, 01h
    je C2C_CHECK
    cmp al, p1color4
    jne C2C_CHECK
    inc p2WrongPlacementCount
    inc p2CorrectColorCount
    mov p1slotUsed4, 01h

; ---- Win conditions ---- 
C2C_CHECK:
    cmp p2CorrectPlacementCount, 04h
    je C2C_P2_WIN

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

PRINT_DECIMAL_COLORED PROC
    ; Input: AL = number (0-255), BL = color attribute
    ; Prints decimal number with specified color
    ; Assumes cursor is positioned
    push ax
    aam                 ; Convert AL to BCD: AH = tens, AL = ones
    add ax, 3030h       ; Convert to ASCII
    
    cmp ah, '0'
    jne PDC_TWO_DIGIT
    
    ; Single digit (only ones place)
    mov dl, al
    mov ah, 09h
    mov bh, 00h
    mov cx, 1
    int 10h
    inc dl
    mov ah, 02h
    int 10h
    pop ax
    ret
    
PDC_TWO_DIGIT:
    ; Two digits (tens and ones)
    mov cl, al          ; Save ones digit (ASCII)
    mov dl, ah          ; dl = tens digit (ASCII)
    mov ah, 09h
    mov bh, 00h
    mov cx, 1
    int 10h             ; Write tens digit
    
    inc dl
    mov ah, 02h
    int 10h             ; Move cursor
    
    mov dl, cl          ; dl = ones digit (ASCII)
    mov ah, 09h
    mov bh, 00h
    mov cx, 1
    int 10h             ; Write ones digit
    
    inc dl
    mov ah, 02h
    int 10h             ; Move cursor
    
    pop ax
    ret
PRINT_DECIMAL_COLORED ENDP

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

; =========================================================
; DRAW_P1_WIN_SCREEN
; Draws the full Player 1 win splash screen (from p1win.asm)
; Replaces the game-over UI when Player 1 wins
; =========================================================
DRAW_P1_WIN_SCREEN PROC
    ; Set video mode 3 (80x25 color text)
    mov ah, 00h
    mov al, 03h
    int 10h

    ; Disable blink so all 16 colors work as backgrounds
    mov ax, 1003h
    mov bx, 0000h
    int 10h

    ; Hide cursor
    mov ah, 01h
    mov ch, 20h
    mov cl, 00h
    int 10h

    ; --- Pixel data (one INT 10h per color run) ---
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00000h
    mov dx, 0004Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00100h
    mov dx, 0010Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00110h
    mov dx, 00115h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00116h
    mov dx, 00127h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00128h
    mov dx, 0012Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0012Eh
    mov dx, 0014Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00200h
    mov dx, 0020Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0020Eh
    mov dx, 0020Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00210h
    mov dx, 00215h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00216h
    mov dx, 00217h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00218h
    mov dx, 00225h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00226h
    mov dx, 00227h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00228h
    mov dx, 0022Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0022Eh
    mov dx, 0022Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00230h
    mov dx, 0024Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00300h
    mov dx, 0030Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0030Ch
    mov dx, 0030Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0030Eh
    mov dx, 00317h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00318h
    mov dx, 00319h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0031Ah
    mov dx, 00323h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00324h
    mov dx, 00325h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00326h
    mov dx, 0032Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00330h
    mov dx, 00331h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00332h
    mov dx, 0034Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00400h
    mov dx, 00409h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0040Ah
    mov dx, 0040Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0040Ch
    mov dx, 00419h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0041Ah
    mov dx, 00423h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00424h
    mov dx, 00431h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00432h
    mov dx, 00433h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00434h
    mov dx, 0044Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00500h
    mov dx, 00509h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0050Ah
    mov dx, 0050Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0050Ch
    mov dx, 00519h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 070h
    mov cx, 0051Ah
    mov dx, 0051Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0051Ch
    mov dx, 0051Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 070h
    mov cx, 0051Eh
    mov dx, 0051Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00520h
    mov dx, 00521h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 070h
    mov cx, 00522h
    mov dx, 00523h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00524h
    mov dx, 00531h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00532h
    mov dx, 00533h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00534h
    mov dx, 0054Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00600h
    mov dx, 00609h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0060Ah
    mov dx, 0060Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0060Ch
    mov dx, 00619h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 070h
    mov cx, 0061Ah
    mov dx, 0061Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0061Ch
    mov dx, 0061Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 070h
    mov cx, 0061Eh
    mov dx, 0061Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00620h
    mov dx, 00621h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 070h
    mov cx, 00622h
    mov dx, 00623h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00624h
    mov dx, 00631h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00632h
    mov dx, 00633h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00634h
    mov dx, 0064Fh
    int 10h

    ; row=7
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00700h
    mov dx, 00707h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00708h
    mov dx, 00715h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00716h
    mov dx, 00725h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00726h
    mov dx, 00731h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00732h
    mov dx, 0074Fh
    int 10h

    ; row=8
    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00800h
    mov dx, 00803h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00804h
    mov dx, 00805h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00806h
    mov dx, 00807h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00808h
    mov dx, 00815h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00816h
    mov dx, 00817h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00818h
    mov dx, 00823h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00824h
    mov dx, 00825h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00826h
    mov dx, 00831h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00832h
    mov dx, 00833h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00834h
    mov dx, 00835h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00836h
    mov dx, 00839h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0083Ah
    mov dx, 0084Fh
    int 10h

    ; row=9
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00900h
    mov dx, 00903h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00904h
    mov dx, 00907h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00908h
    mov dx, 00915h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00916h
    mov dx, 00917h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00918h
    mov dx, 00923h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00924h
    mov dx, 00925h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00926h
    mov dx, 00931h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00932h
    mov dx, 00935h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00936h
    mov dx, 0094Fh
    int 10h

    ; row=10
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00A00h
    mov dx, 00A05h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00A06h
    mov dx, 00A07h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00A08h
    mov dx, 00A15h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00A16h
    mov dx, 00A25h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00A26h
    mov dx, 00A31h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00A32h
    mov dx, 00A33h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00A34h
    mov dx, 00A4Fh
    int 10h

    ; row=11
    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00B00h
    mov dx, 00B07h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00B08h
    mov dx, 00B0Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00B0Ch
    mov dx, 00B0Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00B0Eh
    mov dx, 00B15h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00B16h
    mov dx, 00B17h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00B18h
    mov dx, 00B23h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00B24h
    mov dx, 00B25h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00B26h
    mov dx, 00B2Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00B2Eh
    mov dx, 00B2Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00B30h
    mov dx, 00B31h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00B32h
    mov dx, 00B39h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00B3Ah
    mov dx, 00B4Fh
    int 10h

    ; row=12
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00C00h
    mov dx, 00C05h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00C06h
    mov dx, 00C07h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00C08h
    mov dx, 00C15h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00C16h
    mov dx, 00C17h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00C18h
    mov dx, 00C23h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00C24h
    mov dx, 00C25h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00C26h
    mov dx, 00C31h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00C32h
    mov dx, 00C33h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00C34h
    mov dx, 00C4Fh
    int 10h

    ; row=13
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00D00h
    mov dx, 00D07h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00D08h
    mov dx, 00D09h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 00D0Ah
    mov dx, 00D0Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00D10h
    mov dx, 00D15h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00D16h
    mov dx, 00D25h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00D26h
    mov dx, 00D33h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00D34h
    mov dx, 00D4Fh
    int 10h

    ; row=14
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00E00h
    mov dx, 00E09h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 00E0Ah
    mov dx, 00E0Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0E0h
    mov cx, 00E0Ch
    mov dx, 00E0Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 00E0Eh
    mov dx, 00E0Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00E10h
    mov dx, 00E17h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00E18h
    mov dx, 00E23h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00E24h
    mov dx, 00E31h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00E32h
    mov dx, 00E33h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00E34h
    mov dx, 00E4Fh
    int 10h

    ; row=15
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00F00h
    mov dx, 00F03h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 00F04h
    mov dx, 00F0Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0E0h
    mov cx, 00F0Ch
    mov dx, 00F0Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 00F0Eh
    mov dx, 00F0Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00F10h
    mov dx, 00F11h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00F12h
    mov dx, 00F19h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00F1Ah
    mov dx, 00F1Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00F1Ch
    mov dx, 00F1Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00F1Eh
    mov dx, 00F1Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00F20h
    mov dx, 00F21h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00F22h
    mov dx, 00F23h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00F24h
    mov dx, 00F2Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 00F30h
    mov dx, 00F31h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 00F32h
    mov dx, 00F4Fh
    int 10h

    ; row=16
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01000h
    mov dx, 01001h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01002h
    mov dx, 01003h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0E0h
    mov cx, 01004h
    mov dx, 01007h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01008h
    mov dx, 0100Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0E0h
    mov cx, 0100Ch
    mov dx, 0100Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01010h
    mov dx, 01011h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01012h
    mov dx, 01015h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01016h
    mov dx, 01019h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0101Ah
    mov dx, 01023h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01024h
    mov dx, 0102Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0102Ch
    mov dx, 01033h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01034h
    mov dx, 0104Fh
    int 10h

    ; row=17
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01100h
    mov dx, 01101h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01102h
    mov dx, 01105h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0E0h
    mov cx, 01106h
    mov dx, 01109h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 0110Ah
    mov dx, 0110Bh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0E0h
    mov cx, 0110Ch
    mov dx, 0110Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01110h
    mov dx, 01111h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01112h
    mov dx, 01131h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01132h
    mov dx, 01133h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01134h
    mov dx, 0114Fh
    int 10h

    ; row=18
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01200h
    mov dx, 01201h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01202h
    mov dx, 01203h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0E0h
    mov cx, 01204h
    mov dx, 01205h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01206h
    mov dx, 01209h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0E0h
    mov cx, 0120Ah
    mov dx, 0120Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01210h
    mov dx, 01211h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01212h
    mov dx, 0122Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01230h
    mov dx, 01231h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01232h
    mov dx, 0124Fh
    int 10h

    ; row=19
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01300h
    mov dx, 01303h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01304h
    mov dx, 01305h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0E0h
    mov cx, 01306h
    mov dx, 0130Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 0130Eh
    mov dx, 0130Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01310h
    mov dx, 01311h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01312h
    mov dx, 0132Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0132Eh
    mov dx, 0132Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01330h
    mov dx, 0134Fh
    int 10h

    ; row=20
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01400h
    mov dx, 01405h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 060h
    mov cx, 01406h
    mov dx, 0140Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0140Eh
    mov dx, 0140Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01410h
    mov dx, 01411h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01412h
    mov dx, 0142Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0142Eh
    mov dx, 0142Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01430h
    mov dx, 0144Fh
    int 10h

    ; row=21
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01500h
    mov dx, 0150Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01510h
    mov dx, 01511h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01512h
    mov dx, 01517h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01518h
    mov dx, 01527h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01528h
    mov dx, 0152Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0152Eh
    mov dx, 0152Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01530h
    mov dx, 0154Fh
    int 10h

    ; row=22
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01600h
    mov dx, 0160Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01610h
    mov dx, 01611h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01612h
    mov dx, 01615h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01616h
    mov dx, 01617h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01618h
    mov dx, 01627h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01628h
    mov dx, 01629h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0162Ah
    mov dx, 0162Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0162Eh
    mov dx, 0162Fh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01630h
    mov dx, 0164Fh
    int 10h

    ; row=23
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01700h
    mov dx, 01711h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 01712h
    mov dx, 01715h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01716h
    mov dx, 01729h
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 000h
    mov cx, 0172Ah
    mov dx, 0172Dh
    int 10h

    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 0172Eh
    mov dx, 0174Fh
    int 10h

    ; row=24
    mov ah, 06h
    mov al, 00h
    mov bh, 0F0h
    mov cx, 01800h
    mov dx, 0184Fh
    int 10h

    ;secret color code
    ;square1
    mov ah, 06h
    mov al, 00h
    mov bh, p1color1
    mov cx, 0034Ah
    mov dx, 0044Dh
    int 10h

    ;square2
    mov ah, 06h
    mov al, 00h
    mov bh, p1color2
    mov cx, 0064Ah
    mov dx, 0074Dh
    int 10h

    ;square3
    mov ah, 06h
    mov al, 00h
    mov bh, p1color3
    mov cx, 0094Ah
    mov dx, 00A4Dh
    int 10h

    ;square4
    mov ah, 06h
    mov al, 00h
    mov bh, p1color4
    mov cx, 00C4Ah
    mov dx, 00D4Dh
    int 10h

    ; --- Print stats labels ---
    mov ah, 02h
    mov bh, 00h
    mov dh, 06h
    mov dl, 3Ch
    int 10h
    mov ah, 09h
    lea dx, p1winStat1
    int 21h

    mov ah, 02h
    mov bh, 00h
    mov dh, 08h
    mov dl, 3Ch
    int 10h
    mov ah, 09h
    lea dx, p1winStat2
    int 21h

    mov ah, 02h
    mov bh, 00h
    mov dh, 0Ah
    mov dl, 3Ch
    int 10h
    mov ah, 09h
    lea dx, p1winStat3
    int 21h

    ; --- Print p1win messages ---
    mov ah, 02h
    mov bh, 00h
    mov dh, 0Fh
    mov dl, 3Bh
    int 10h
    mov ah, 09h
    lea dx, p1winMsg
    int 21h

    mov ah, 02h
    mov bh, 00h
    mov dh, 10h
    mov dl, 36h
    int 10h
    mov ah, 09h
    lea dx, p1winMsg2
    int 21h

    mov ah, 02h
    mov bh, 00h
    mov dh, 12h
    mov dl, 3Ah
    int 10h
    mov ah, 09h
    lea dx, p1winMsg3
    int 21h

    mov ah, 02h
    mov bh, 00h
    mov dh, 13h
    mov dl, 3Ah
    int 10h
    mov ah, 09h
    lea dx, p1winMsg4
    int 21h

    ; --- Print live stats values ---
    mov ah, 02h
    mov bh, 00h
    mov dh, 06h
    mov dl, 43h
    int 10h
    mov al, p2TryCount
    call PRINT_DECIMAL

    mov ah, 02h
    mov bh, 00h
    mov dh, 08h
    mov dl, 43h
    int 10h
    mov al, p2CorrectPlacementCount
    call PRINT_DECIMAL

    mov ah, 02h
    mov bh, 00h
    mov dh, 0Ah
    mov dl, 43h
    int 10h
    mov al, p2WrongPlacementCount
    call PRINT_DECIMAL

    ret
DRAW_P1_WIN_SCREEN ENDP

END start