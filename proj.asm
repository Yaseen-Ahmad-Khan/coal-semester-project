[org 0x100]
mov ax, 0013h
int 10h
mov ax, 0A000h
mov es, ax

; Red Car position (centered between lane markers)
mov word [car_x], 148       ; Center X position
mov word [car_y], 120       ; Y position (lower part of screen)

; Blue Car position (in right lane, ahead of red car)
call get_random_0_to_2
    cmp bx, 0
    je lane1_initial
    cmp bx, 1
    je lane2_initial
    mov word [blue_car_x], 203
    jmp initialize_y
lane1_initial:
    mov word [blue_car_x], 90
    jmp initialize_y
lane2_initial:
    mov word [blue_car_x], 148
initialize_y:
    mov word [blue_car_y], 10   ; Higher up (ahead)
mov ax, [blue_car_x]
mov [blue_car_x_old], ax
mov word [blue_car_y_old], 10 ; Store last-drawn Y

; --- COIN INITIALIZATION  ---
call get_random_0_to_2
    cmp bx, 0
    je coin_lane1_initial
    cmp bx, 1
    je coin_lane2_initial
    mov word [coin_x], 215  ; Lane 3
    jmp coin_initialize_y
coin_lane1_initial:
    mov word [coin_x], 105   ; Lane 1
    jmp coin_initialize_y
coin_lane2_initial:
    mov word [coin_x], 160 ; Lane 2
coin_initialize_y:
    mov word [coin_y], 80   ; Y position (different from car)
mov ax, [coin_x]
mov [coin_x_old], ax
mov word [coin_y_old], 80
; ---------------------------------

; Initialize lane marker offset
mov word [lane_offset], 0

; --- DRAW ALL STATIC ELEMENTS ONCE ---
call draw_static_background
call draw_car               ; Red car is static, draw it once
call draw_fuel_text         ; NEW: Draw the "FUEL: " text
call draw_fuel_tanks        ; NEW: Draw the 3 fuel tanks
; --- END OF STATIC DRAW ---


; Main animation loop
animation_loop:
    ; Small delay for smoother animation
    mov cx, 0x0001
    mov dx, 0x0000
    mov ah, 86h
    int 15h
   
    ; --- REDRAW DYNAMIC PARTS ---
    call draw_scrolling_grass
    call draw_lane_markers
   
    ; --- ERASE, UPDATE, and REDRAW THE BLUE CAR ---
    call erase_blue_car         ; Erase car at its *old* position
   
    ; Save current pos for next frame's erase
    mov ax, [blue_car_y]
    mov [blue_car_y_old], ax
    mov ax, [blue_car_x]        ; NEW: Save old X
    mov [blue_car_x_old], ax
   
    ; Update Y position
    mov ax, [blue_car_y]
    add ax, 4                   ; Move car down
    mov [blue_car_y], ax
   
    cmp ax, 200
    jb bnao
    mov word [blue_car_y], 10
    call get_random_0_to_2
    cmp bx, 0
    je lane1
    cmp bx, 1
    je lane2
    mov word [blue_car_x], 203
    jmp bnao
lane1:
    mov word [blue_car_x], 90
    jmp bnao
lane2:
    mov word [blue_car_x], 148
   
bnao:
    call draw_blue_car          ; Redraw car at its *new* position

    ; --- ERASE, UPDATE, and REDRAW THE COIN  ---
    call erase_coin
   
    ; Save current pos for next frame's erase
    mov ax, [coin_y]
    mov [coin_y_old], ax
    mov ax, [coin_x]
    mov [coin_x_old], ax
   
    ; Update Y position (same speed as car)
    mov ax, [coin_y]
    add ax, 4
    mov [coin_y], ax
   
    ; Check if coin is off-screen (Y > 200)
    cmp ax, 200
    jb cnao
    mov word [coin_y], 10       ; Reset to top
   
    ; NEW: Random lane selection for coin
    call get_random_0_to_2
    cmp bx, 0
    je coin_lane1
    cmp bx, 1
    je coin_lane2
    mov word [coin_x], 215     ; Lane 3
    jmp cnao
coin_lane1:
    mov word [coin_x], 105      ; Lane 1
    jmp cnao
coin_lane2:
    mov word [coin_x], 160     ; Lane 2
   
cnao:
    call draw_coin              ; Redraw coin at its *new* position
    ; ----------------------------------------------------

    ; Update lane offset for scrolling effect (down direction)
    mov ax, [lane_offset]
    add ax, 9           ; Scroll speed (increase for faster)
    cmp ax, 75          ; Wrap around at pattern length
    jl no_wrap
    sub ax, 75
no_wrap:
    mov [lane_offset], ax
   
    ; Check for key press (non-blocking)
    mov ah, 01h
    int 16h
    jz animation_loop   ; No key pressed, continue loop (REVERTED)
   
    ; Key pressed, read it to clear buffer
    mov ah, 0
    int 16h
   
    ; Return to text mode 03h
    mov ax, 0003h
    int 10h
   
    ; Exit properly
    mov ax, 4C00h
    int 21h


; --- ERASE FUNCTION ---
; Erases the blue car by drawing a solid gray box at its OLD position
erase_blue_car:
    push ax
    push bx
    push cx
    push si
    push di
   
    mov al, 8           ; Road Gray color
   
    mov si, [blue_car_y_old]    ; Get car's last Y
    mov di, [blue_car_x_old]    ; ***FIXED: Get car's LAST X***
    sub di, 2                   ; Start at leftmost pixel of sprite
   
    mov cx, 40          ; Car sprite is approx 40 pixels high
erase_row:
    push cx
   
    cmp si, 200                 ; CLIP CHECK
    jge erase_skip_row          ; Don't erase rows off-screen
   
    mov bx, si
    imul bx, 320                ; Get row offset
    add bx, di                  ; Add col offset
   
    mov cx, 28                  ; Car sprite is approx 28 pixels wide
erase_col:
    mov [es:bx], al
    inc bx
    loop erase_col
   
erase_skip_row:
    inc si
    pop cx
    loop erase_row

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

; --- ERASE COIN FUNCTION ---
erase_coin:
    push ax
    push bx
    push cx
    push si
    push di
   
    mov al, 8                   ; Road Gray color
   
    mov si, [coin_y_old]        ; Get coin's last Y
    mov di, [coin_x_old]        ; Get coin's LAST X
    sub di, 4                   ; Start at leftmost pixel of sprite (Coin is 8px wide)
   
    mov cx, 10                  ; Coin sprite is 10 pixels high
coin_erase_row:
    push cx
   
    cmp si, 200                 ; CLIP CHECK
    jge coin_erase_skip_row     ; Don't erase rows off-screen
   
    mov bx, si
    imul bx, 320                ; Get row offset
    add bx, di                  ; Add col offset
   
    mov cx, 8                   ; Width is 8 pixels
coin_erase_col:
    mov [es:bx], al
    inc bx
    loop coin_erase_col
   
coin_erase_skip_row:
    inc si
    pop cx
    loop coin_erase_row

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
; ----------------------------------------------------


draw_static_background:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
   
    xor si, si      ; row counter (0-199)
   
bg_row:
    xor di, di      ; column counter (0-319)
    mov bx, si
    imul bx, 320    ; BX = row offset
   
bg_col:
    mov al, 8       ; default road gray
   
    ; Check for outermost black borders
    cmp di, 50
    jl bg_set_black_border
    cmp di, 270
    jge bg_set_black_border
   
    ; Check for black lines (2 pixels wide)
    cmp di, 79
    je bg_set_black
    cmp di, 80
    je bg_set_black
    cmp di, 240
    je bg_set_black
    cmp di, 241
    je bg_set_black
   
    ; Check for white border lines next to black (3 pixels wide)
    cmp di, 81
    je bg_set_white_border
    cmp di, 82
    je bg_set_white_border
    cmp di, 83
    je bg_set_white_border
    cmp di, 237
    je bg_set_white_border
    cmp di, 238
    je bg_set_white_border
    cmp di, 239
    je bg_set_white_border
   
    ; Check if we're in grass area
    cmp di, 80
    jb bg_set_grass
    cmp di, 240
    ja bg_set_grass
    jmp bg_write_pixel

bg_set_black_border:
    mov al, 0       ; Force black border
    jmp bg_write_pixel
   
bg_set_black:
    mov al, 0       ; black border
    jmp bg_write_pixel
   
bg_set_grass:
    ; --- STATIC GRASS  ---
    
    mov ax, si
    shr ax, 3
    test ax, 1
    jz bg_light_green
    mov al, 10
    jmp bg_write_pixel
bg_light_green:
    mov al, 2
    jmp bg_write_pixel

bg_set_white_border:
    mov al, 15      ; white border
    jmp bg_write_pixel
   
bg_write_pixel:
    mov byte [es:bx+di], al
   
    inc di
    cmp di, 320
    jl bg_col
   
    inc si
    cmp si, 200
    jl bg_row
   
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; Redraws ONLY the grass columns, using the scroll offset
draw_scrolling_grass:
    push ax
    push bx
    push cx
    push si
    push di
   
    xor si, si      ; row counter (0-199)

grass_row_loop:
    ; Calculate the scrolling pattern coordinate
    mov cx, si
    sub cx, [lane_offset]
   
grass_pattern_check:
    cmp cx, 0
    jge grass_pattern_pos
    add cx, 75
    jmp grass_pattern_check
grass_pattern_pos:
    cmp cx, 75
    jl grass_pattern_ok
    sub cx, 75
    jmp grass_pattern_pos
grass_pattern_ok:
   
    ; Use pattern to set color
    mov al, 2       ; Light green
    shr cx, 3
    test cx, 1
    jz draw_grass_cols
    mov al, 10      ; Dark green
   
draw_grass_cols:
    ; Get row offset
    mov bx, si
    imul bx, 320
   
    ; Draw Left Grass Area (Cols 50-78)
    mov di, 50
draw_left_grass:
    mov [es:bx+di], al
    inc di
    cmp di, 79 ; Stop before black border
    jl draw_left_grass

    ; Draw Right Grass Area (Cols 242-269)
    mov di, 242
draw_right_grass:
    mov [es:bx+di], al
    inc di
    cmp di, 270 ; Stop at edge of screen
    jl draw_right_grass
   
    inc si
    cmp si, 200
    jl grass_row_loop

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret


draw_lane_markers:
    push ax
    push bx
    push cx
    push si
    push di
   
    xor si, si      ; row counter
   
lane_row:
    ; Add offset for scrolling and create repeating pattern
    mov cx, si
    sub cx, [lane_offset]   ; Subtract offset for downward movement
   
check_pattern:
    cmp cx, 0
    jge check_pattern_pos
    add cx, 75          ; Wrap negative values
    jmp check_pattern
   
check_pattern_pos:
    cmp cx, 75
    jl check_in_segment
    sub cx, 75
    jmp check_pattern
   
check_in_segment:
    ; If CX < 50, draw white line
    cmp cx, 50
    jge skip_lane_draw
   
    ; Draw on left lane (128-132)
    mov bx, si
    imul bx, 320
    mov di, 128
draw_left_marker:
    mov byte [es:bx+di], 15 ; White
    inc di
    cmp di, 133
    jl draw_left_marker
   
    ; Draw on right lane (188-192)
    mov di, 188
draw_right_marker:
    mov byte [es:bx+di], 15 ; White
    inc di
    cmp di, 193
    jl draw_right_marker
    jmp lane_continue
   
skip_lane_draw:
    ; Draw gray road instead of white
    mov bx, si
    imul bx, 320
    mov di, 128
erase_left_marker:
    mov byte [es:bx+di], 8 ; Gray road
    inc di
    cmp di, 133
    jl erase_left_marker
   
    mov di, 188
erase_right_marker:
    mov byte [es:bx+di], 8 ; Gray road
    inc di
    cmp di, 193
    jl erase_right_marker

lane_continue:
    inc si
    cmp si, 200
    jl lane_row
   
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

; ---  DRAW COIN SUBROUTINE ---
draw_coin:
    push ax
    push bx
    push cx
    push si
    push di
    push bp

    mov si, [coin_y]    ; Start Y position
    mov di, [coin_x]    ; Start X position
    sub di, 4           ; Adjust X to center the coin (8 pixels wide)

    ; Color definitions: 0=Black, 6=Brown (Dark Gold), 14=Yellow (Main Gold), 15=White (Highlight)

    ; Row 0: 4px wide, Dark Gold (6) - Top edge shading
    cmp si, 200
    jge dc1_skip
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2           ; X+2
    mov cx, 4
dc1:
    mov byte [es:bx], 6 ; Dark Gold/Brown
    inc bx
    loop dc1
dc1_skip:
    inc si

    ; Rows 1-2: 8px wide body - Includes top-left highlight
    mov ax, 2
dc_highlight_body:
    cmp si, 200
    jge dc_hb_skip
    mov bx, si
    imul bx, 320
    add bx, di
   
    ; Left Edge (Dark Gold)
    mov byte [es:bx], 6
   
    ; Highlight (White)
    mov byte [es:bx+1], 15
    mov byte [es:bx+2], 14 ; Main Gold
   
    ; Center Hole (Black)
    mov byte [es:bx+3], 0
   
    ; Main Gold Fill
    mov byte [es:bx+4], 14
    mov byte [es:bx+5], 14
   
    ; Right Edge (Dark Gold/Shading)
    mov byte [es:bx+6], 6
    mov byte [es:bx+7], 6
   
dc_hb_skip:
    inc si
    dec ax
    jnz dc_highlight_body

    ; Rows 3-6: 8px wide body - Main Gold (14) with shaded edges (6)
    mov ax, 4
dc_main_body:
    cmp si, 200
    jge dc_mb_skip
    mov bx, si
    imul bx, 320
    add bx, di
   
    ; Edges (Dark Gold)
    mov byte [es:bx], 6
    mov byte [es:bx+7], 6
   
    ; Main Gold Fill (X+1 to X+6)
    mov cx, 6
    mov bp, bx ; Use bp to iterate
    add bp, 1
dc_fill_loop:
    mov byte [es:bp], 14
    inc bp
    loop dc_fill_loop
   
    ; Center Hole (Black) - drawn over the fill
    mov byte [es:bx+3], 0
   
dc_mb_skip:
    inc si
    dec ax
    jnz dc_main_body

    ; Rows 7-8: 8px wide body - Bottom edge shading
    mov ax, 2
dc_shade_body:
    cmp si, 200
    jge dc_sb_skip
    mov bx, si
    imul bx, 320
    add bx, di
   
    ; Edges (Dark Gold)
    mov byte [es:bx], 6
    mov byte [es:bx+7], 6

    ; Inner Shading (Dark Gold) (X+1 to X+6)
    mov cx, 6
    mov bp, bx
    add bp, 1
dc_shade_fill_loop:
    mov byte [es:bp], 6
    inc bp
    loop dc_shade_fill_loop
   
    ; Center Hole (Black) - drawn over the shade
    mov byte [es:bx+3], 0
   
dc_sb_skip:
    inc si
    dec ax
    jnz dc_shade_body

    ; Row 9: 4px wide, Dark Gold (6) - Bottom edge taper
    cmp si, 200
    jge dc9_skip
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2           ; X+2
    mov cx, 4
dc9:
    mov byte [es:bx], 6 ; Dark Gold/Brown
    inc bx
    loop dc9
dc9_skip:

    pop bp
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
; ------------------------------------------

 
; ---  DRAW "FUEL: " TEXT ---
draw_fuel_text:
    push ax
    push bp
    push cx
    push dx
    push es
   
    ; --- THIS IS THE FIX ---
    ; ES must point to the Data Segment (DS), not the Video Segment (0A000h)
    push ds
    pop es
    ; --- END OF FIX ---
   
    mov ah, 0x13        ; Function: Write String
    mov al, 0x01        ; Mode: Write string, move cursor
    mov bh, 0           ; Video Page 0
    mov bl, 14        ; Attribute (Color 4 = Red)
    mov cx, 6           ; Length of string ("FUEL: ")
    mov dh, 21          ; Row (Y / 8) -> 176 / 8 = 22
    mov dl, 34          ; Column (X / 8) -> 272 / 8 = 34
    mov bp, fuel_msg    ; ES:BP points to string
   
    int 0x10
   
    pop es
    pop dx
    pop cx
    pop bp
    pop ax
    ret
; ---------------------------------



; --- DRAW FUEL TANKS SUBROUTINE (10x12 jerrycan) ---
draw_fuel_tanks:
    push ax
    push bx
    push cx
    push si
    push di
    push bp

    mov cx, 3           ; 3 tanks
    mov di, 273         ; Start X (Moved to black border)
tank_loop:
    push cx             ; Save outer loop counter
   
    mov si, 180         ; Y position (top)
   
    ; Row 0: ...BB... (Black cap, 4px)
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 3           ; Start at X+3
    mov byte [es:bx], 0
    mov byte [es:bx+1], 0
    mov byte [es:bx+2], 0
    mov byte [es:bx+3], 0
    inc si

    ; Row 1: ..BBBB.. (Black cap, 6px)
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2           ; Start at X+2
    mov cx, 6
tc1_pix:
    mov byte [es:bx], 0 ; Black
    inc bx
    loop tc1_pix
    inc si

    ; Row 2: .B.RRRR.B. (Handle + Body)
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0 ; Handle
    mov byte [es:bx+3], 4 ; Body
    mov byte [es:bx+4], 4
    mov byte [es:bx+5], 4
    mov byte [es:bx+6], 4
    mov byte [es:bx+8], 0 ; Handle
    inc si
   
    ; Row 3: .BRRRRRR.B. (Handle + Body)
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0 ; Handle
    mov cx, 6
    mov bp, bx
    add bp, 2 ; Start at X+2
tc3_fill:
    mov byte [es:bp], 4 ; Red
    inc bp
    loop tc3_fill
    mov byte [es:bx+8], 0 ; Handle
    inc si

    ; Row 4: .BRWRRRR.B. (Highlight)
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0 ; Black edge
    mov byte [es:bx+2], 4 ; Red
    mov byte [es:bx+3], 15 ; White
    mov byte [es:bx+4], 4 ; Red
    mov byte [es:bx+5], 4 ; Red
    mov byte [es:bx+6], 4 ; Red
    mov byte [es:bx+7], 4 ; Red
    mov byte [es:bx+8], 0 ; Black edge
    inc si

    ; Rows 5-9 (5 rows of .BRRRRRRR.B.)
    mov cx, 5 ; 5 rows
tc_main_loop:
    push cx
    mov bx, si
    imul bx, 320
    add bx, di
   
    mov byte [es:bx+1], 0 ; Black edge
    mov cx, 7
    mov bp, bx
    add bp, 2
tc_main_fill:
    mov byte [es:bp], 4 ; Red
    inc bp
    loop tc_main_fill
    mov byte [es:bx+8], 0 ; Black edge
   
    inc si
    pop cx
    loop tc_main_loop
   
    ; Row 10: ..BBBBBB.. (Bottom)
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2
    mov cx, 6
tc10_pix:
    mov byte [es:bx], 0 ; Black
    inc bx
    loop tc10_pix
    inc si

    ; Row 11: ...BB... (Feet)
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 3
    mov byte [es:bx], 0
    mov byte [es:bx+1], 0
    mov byte [es:bx+2], 0
    mov byte [es:bx+3], 0

    add di, 14          ; Move X right for next tank (10px width + 4px gap)
   
    pop cx              ; Restore the outer loop counter (3, 2, 1)
    dec cx              ; Manually decrement
    jnz tank_loop       ; Use a NEAR jump instead of LOOP

    pop bp
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
; ---------------------------------------



; -------------------------------------------------------------------
; RED CAR (DARK RED) - NOW WITH CLIPPING
; -------------------------------------------------------------------

draw_car:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
   
    mov si, [car_y]     ; Start Y position
    mov di, [car_x]     ; Start X position
   
    ; Draw each section
    call draw_front
    call draw_hood
    call draw_windshield_f
    call draw_roof
    call draw_body
    call draw_windshield_r
    call draw_trunk
    call draw_rear_bumper
    call draw_rear_taper
   
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Red Car Front (Bumper, Grille, Headlights) ---
draw_front:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, si
    ; Row 0: narrow (10px) - Black Edge (0)
    cmp dx, 200         ; CLIP CHECK
    jge df1_skip        ; CLIP CHECK
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
df1:
    mov byte [es:bx], 0 ; Black
    inc bx
    loop df1
df1_skip:
    inc dx
   
    ; Row 1: wider (16px) + Headlights
    cmp dx, 200         ; CLIP CHECK
    jge df2_skip        ; CLIP CHECK
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 4
    mov byte [es:bx], 15      ; White Headlight
    mov byte [es:bx+1], 15    ; White Headlight
    mov byte [es:bx+14], 15   ; White Headlight
    mov byte [es:bx+15], 15   ; White Headlight
    mov cx, 12 ; Fill between lights
df2:
    mov byte [es:bx+2], 4 ; Dark Red Fill
    inc bx
    loop df2
df2_skip:
    inc dx
   
    ; Row 2: full (20px) + Grille
    cmp dx, 200         ; CLIP CHECK
    jge df3_skip        ; CLIP CHECK
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 2
    mov byte [es:bx], 0       ; Black Edge
    mov byte [es:bx+1], 4     ; Dark Red Fill
    mov byte [es:bx+2], 4     ; Dark Red Fill
    mov byte [es:bx+3], 4     ; Dark Red Fill
    mov byte [es:bx+16], 4    ; Dark Red Fill
    mov byte [es:bx+17], 4    ; Dark Red Fill
    mov byte [es:bx+18], 4    ; Dark Red Fill
    mov byte [es:bx+19], 0    ; Black Edge
    mov cx, 12 ; Grille
df3:
    mov byte [es:bx+4], 0     ; Black Grille
    inc bx
    loop df3
df3_skip:
   
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Red Car Hood (Bonnet) with definition lines ---
draw_hood:
    push ax
    push bx
    push cx
    push dx
    push si
    mov ax, 3   ; 3 rows high
dh1:
    cmp si, 200         ; CLIP CHECK
    jge dh_skip_row     ; CLIP CHECK

    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
   
    mov byte [es:bx], 0       ; Black edge
    mov byte [es:bx+21], 0    ; Black edge
   
    mov cx, 19 ; Fill main hood
dh2:
    mov byte [es:bx+1], 4 ; Dark Red Fill
    inc bx
    loop dh2
   
    ; Add definition lines
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 0  ; Black line
    mov byte [es:bx+14], 0 ; Black line
   
dh_skip_row:
    inc si
    dec ax
    jnz dh1
   
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Red Car Front Windshield (Tapered) + Side Mirrors ---
draw_windshield_f:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 0 (Y): 24px wide + Mirrors
    cmp si, 200         ; CLIP CHECK
    jge dwf1_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx-2], 0     ; Left Mirror (Black)
    mov byte [es:bx-1], 0     ; Left Mirror (Black)
    mov byte [es:bx], 0       ; Black Pillar
    mov byte [es:bx+23], 0    ; Black Pillar
    mov byte [es:bx+24], 0    ; Right Mirror (Black)
    mov byte [es:bx+25], 0    ; Right Mirror (Black)
    mov cx, 22
dwf1:
    mov byte [es:bx+1], 0 ; Black Glass
    inc bx
    loop dwf1
dwf1_skip:
    inc si
   
    ; Row 1 (Y+1): 22px wide + Mirrors
    cmp si, 200         ; CLIP CHECK
    jge dwf2_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx-1], 0     ; Left Mirror
    mov byte [es:bx+1], 0     ; Black Pillar
    mov byte [es:bx+22], 0    ; Black Pillar
    mov byte [es:bx+23], 0    ; Right Mirror
    mov cx, 20
dwf2:
    mov byte [es:bx+2], 0 ; Black Glass
    inc bx
    loop dwf2
dwf2_skip:
    inc si
   
    ; Row 2 (Y+2): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge dwf3_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black Pillar
    mov byte [es:bx+21], 0    ; Black Pillar
    mov cx, 18
dwf3:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop dwf3
dwf3_skip:
    inc si

    ; Row 3 (Y+3): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge dwf4_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black Pillar
    mov byte [es:bx+21], 0    ; Black Pillar
    mov cx, 18
dwf4:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop dwf4
dwf4_skip:
    inc si
   
    ; Row 4 (Y+4): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge dwf5_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black Pillar
    mov byte [es:bx+21], 0    ; Black Pillar
    mov cx, 18
dwf5:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop dwf5
dwf5_skip:
   
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Red Car Roof (narrowed) + Sunroof ---
draw_roof:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 2
    mov ax, si          ; Save starting SI for sunroof
dr1_:
    cmp si, 200         ; CLIP CHECK
    jge dr_skip_row     ; CLIP CHECK

    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2           ; Start at x+2
    mov cx, 20          ; 20px wide
dr2_:
    mov byte [es:bx], 4 ; Dark Red Fill
    inc bx
    loop dr2_
   
    ; Redraw borders (using black for maximum darkness)
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black Pillar
    mov byte [es:bx+21], 0    ; Black Pillar
   
dr_skip_row:
    inc si
    dec dx
    jnz dr1_
   
    ; Sunroof (8x1 - 1 row)
    cmp ax, 200         ; CLIP CHECK
    jge dr_skip_sunroof ; CLIP CHECK
    mov bx, ax          ; Use saved starting SI (first row of roof)
    imul bx, 320
    add bx, di
    add bx, 8           ; Center position (offset 8 from left edge)
    mov cx, 8           ; Sunroof width
sunroof_r:
    mov byte [es:bx], 0   ; Black
    inc bx
    loop sunroof_r
dr_skip_sunroof:
   
    pop si
    add si, 2
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Red Car Body + Highlights ---
draw_body:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 10
db1:
    cmp si, 200         ; CLIP CHECK
    jge db_skip_row     ; CLIP CHECK
   
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0 ; Black edge
    mov byte [es:bx+23], 0 ; Black edge
   
    add bx, 1
    mov cx, 22
db2:
    mov byte [es:bx], 4 ; Dark Red Fill
    inc bx
    loop db2
   
    ; Add highlights
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+5], 15  ; White shine
    mov byte [es:bx+18], 15 ; White shine
   
db_skip_row:
    inc si
    dec dx
    jnz db1
    pop si
    add si, 10
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Red Car Rear Windshield (Tapered) ---
draw_windshield_r:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 0 (Y): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge dwr1_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black Pillar
    mov byte [es:bx+21], 0    ; Black Pillar
    mov cx, 18
dwr1:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop dwr1
dwr1_skip:
    inc si
   
    ; Row 1 (Y+1): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge dwr2_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black Pillar
    mov byte [es:bx+21], 0    ; Black Pillar
    mov cx, 18
dwr2:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop dwr2
dwr2_skip:
    inc si
   
    ; Row 2 (Y+2): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge dwr3_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black Pillar
    mov byte [es:bx+21], 0    ; Black Pillar
    mov cx, 18
dwr3:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop dwr3
dwr3_skip:
    inc si
   
    ; Row 3 (Y+3): 22px wide
    cmp si, 200         ; CLIP CHECK
    jge dwr4_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0     ; Black Pillar
    mov byte [es:bx+22], 0    ; Black Pillar
    mov cx, 20
dwr4:
    mov byte [es:bx+2], 0 ; Black Glass
    inc bx
    loop dwr4
dwr4_skip:
    inc si
   
    ; Row 4 (Y+4): 24px wide
    cmp si, 200         ; CLIP CHECK
    jge dwr5_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0       ; Black Pillar
    mov byte [es:bx+23], 0    ; Black Pillar
    mov cx, 22
dwr5:
    mov byte [es:bx+1], 0 ; Black Glass
    inc bx
    loop dwr5
dwr5_skip:
   
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Red Car Trunk (Tapered) + Definition Lines ---
draw_trunk:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 0 (Y): 24px wide
    cmp si, 200         ; CLIP CHECK
    jge dt1_skip        ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0       ; Black
    mov byte [es:bx+23], 0    ; Black
    mov cx, 22
dt1:
    mov byte [es:bx+1], 4 ; Dark Red Fill
    inc bx
    loop dt1
dt1_skip:
    inc si
   
    ; Row 1 (Y+1): 24px wide + Lines
    cmp si, 200         ; CLIP CHECK
    jge dt2_skip        ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0       ; Black
    mov byte [es:bx+23], 0    ; Black
    mov cx, 22
dt2:
    mov byte [es:bx+1], 4 ; Dark Red Fill
    inc bx
    loop dt2
    mov bx, si          ; Reset BX for lines
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 0     ; Black Trunk Line
    mov byte [es:bx+15], 0    ; Black Trunk Line
dt2_skip:
    inc si
   
    ; Row 2 (Y+2): 24px wide + Lines
    cmp si, 200         ; CLIP CHECK
    jge dt3_skip        ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0       ; Black
    mov byte [es:bx+23], 0    ; Black
    mov cx, 22
dt3:
    mov byte [es:bx+1], 4 ; Dark Red Fill
    inc bx
    loop dt3
    mov bx, si          ; Reset BX for lines
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 0     ; Black Trunk Line
    mov byte [es:bx+15], 0    ; Black Trunk Line
dt3_skip:
    inc si
   
    ; Row 3 (Y+3): 22px wide
    cmp si, 200         ; CLIP CHECK
    jge dt4_skip        ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0     ; Black
    mov byte [es:bx+22], 0    ; Black
    mov cx, 20
dt4:
    mov byte [es:bx+2], 4 ; Dark Red Fill
    inc bx
    loop dt4
dt4_skip:
    inc si
   
    ; Row 4 (Y+4): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge dt5_skip        ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black
    mov byte [es:bx+21], 0    ; Black
    mov cx, 18
dt5:
    mov byte [es:bx+3], 4 ; Dark Red Fill
    inc bx
    loop dt5
dt5_skip:
   
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Red Car Rear Bumper + Taillights ---
draw_rear_bumper:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 0 (Y): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge drb1_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black
    mov byte [es:bx+21], 0    ; Black
    mov cx, 18
drb1:
    mov byte [es:bx+3], 4 ; Dark Red Fill
    inc bx
    loop drb1
drb1_skip:
    inc si
   
    ; Row 1 (Y+1): 20px wide + Taillights
    cmp si, 200         ; CLIP CHECK
    jge drb2_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0     ; Black Edge
    mov byte [es:bx+3], 4     ; Taillight
    mov byte [es:bx+4], 4     ; Taillight
    mov byte [es:bx+19], 4    ; Taillight
    mov byte [es:bx+20], 4    ; Taillight
    mov byte [es:bx+21], 0    ; Black Edge
    mov cx, 14 ; Bumper
drb2:
    mov byte [es:bx+5], 8 ; Gray Bumper
    inc bx
    loop drb2
drb2_skip:
    inc si
   
    ; Row 2 (Y+2): 18px wide
    cmp si, 200         ; CLIP CHECK
    jge drb3_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+3], 0     ; Black
    mov byte [es:bx+20], 0    ; Black
    mov cx, 16
drb3:
    mov byte [es:bx+4], 8 ; Gray Bumper
    inc bx
    loop drb3
drb3_skip:
   
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Red Car Rear Taper (Underside) ---
draw_rear_taper:
    push ax
    push bx
    push cx
    push si
   
    ; Row 1: 16px
    cmp si, 200         ; CLIP CHECK
    jge drt1_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 4
    mov cx, 16
drt1:
    mov byte [es:bx], 0 ; Black
    inc bx
    loop drt1
drt1_skip:
    inc si
   
    ; Row 2: 10px
    cmp si, 200         ; CLIP CHECK
    jge drt2_skip       ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
drt2:
    mov byte [es:bx], 0 ; Black
    inc bx
    loop drt2
drt2_skip:
   
    pop si
    pop cx
    pop bx
    pop ax
    ret

; -------------------------------------------------------------------
; BLUE CAR - NOW WITH CLIPPING
; -------------------------------------------------------------------

draw_blue_car:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
   
    mov si, [blue_car_y]    ; Start Y position
    mov di, [blue_car_x]    ; Start X position
   
    ; Draw each section
    call draw_blue_front
    call draw_blue_hood
    call draw_blue_windshield_f
    call draw_blue_roof
    call draw_blue_body
    call draw_blue_windshield_r
    call draw_blue_trunk
    call draw_blue_rear_bumper
    call draw_blue_rear_taper
   
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Blue Car Front (Bumper, Grille, Headlights) ---
draw_blue_front:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, si
    ; Row 0: narrow (10px) - Dark Blue
    cmp dx, 200         ; CLIP CHECK
    jge b_df1_skip      ; CLIP CHECK
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
b_df1:
    mov byte [es:bx], 1 ; Dark Blue
    inc bx
    loop b_df1
b_df1_skip:
    inc dx
   
    ; Row 1: wider (16px) + Headlights
    cmp dx, 200         ; CLIP CHECK
    jge b_df2_skip      ; CLIP CHECK
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 4
    mov byte [es:bx], 15      ; White Headlight
    mov byte [es:bx+1], 15    ; White Headlight
    mov byte [es:bx+14], 15   ; White Headlight
    mov byte [es:bx+15], 15   ; White Headlight
    mov cx, 12 ; Fill between lights
b_df2:
    mov byte [es:bx+2], 9 ; Light Blue
    inc bx
    loop b_df2
b_df2_skip:
    inc dx
   
    ; Row 2: full (20px) + Grille
    cmp dx, 200         ; CLIP CHECK
    jge b_df3_skip      ; CLIP CHECK
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 2
    mov byte [es:bx], 1       ; Dark Blue
    mov byte [es:bx+1], 9     ; Light Blue
    mov byte [es:bx+2], 9     ; Light Blue
    mov byte [es:bx+3], 9     ; Light Blue
    mov byte [es:bx+16], 9    ; Light Blue
    mov byte [es:bx+17], 9    ; Light Blue
    mov byte [es:bx+18], 9    ; Light Blue
    mov byte [es:bx+19], 1    ; Dark Blue
    mov cx, 12 ; Grille
b_df3:
    mov byte [es:bx+4], 0     ; Black Grille
    inc bx
    loop b_df3
b_df3_skip:
   
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Blue Car Hood (Bonnet) with definition lines ---
draw_blue_hood:
    push ax
    push bx
    push cx
    push dx
    push si
    mov ax, 3   ; 3 rows high
b_dh1:
    cmp si, 200         ; CLIP CHECK
    jge b_dh_skip_row   ; CLIP CHECK
   
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
   
    mov byte [es:bx], 1       ; Dark Blue edge
    mov byte [es:bx+21], 1    ; Dark Blue edge
   
    mov cx, 19 ; Fill main hood
b_dh2:
    mov byte [es:bx+1], 1 ; Light Blue
    inc bx
    loop b_dh2
   
    ; Add definition lines
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 1  ; Dark Blue line
    mov byte [es:bx+14], 1 ; Dark Blue line
   
b_dh_skip_row:
    inc si
    dec ax
    jnz b_dh1
   
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Blue Car Front Windshield (Tapered) + Side Mirrors ---
draw_blue_windshield_f:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 0 (Y): 24px wide + Mirrors
    cmp si, 200         ; CLIP CHECK
    jge b_dwf1_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx-2], 1     ; Left Mirror
    mov byte [es:bx-1], 1     ; Left Mirror
    mov byte [es:bx], 1       ; Blue Pillar
    mov byte [es:bx+23], 1    ; Blue Pillar
    mov byte [es:bx+24], 1    ; Right Mirror
    mov byte [es:bx+25], 1    ; Right Mirror
    mov cx, 22
b_dwf1:
    mov byte [es:bx+1], 0 ; Black Glass
    inc bx
    loop b_dwf1
b_dwf1_skip:
    inc si
   
    ; Row 1 (Y+1): 22px wide + Mirrors
    cmp si, 200         ; CLIP CHECK
    jge b_dwf2_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx-1], 1     ; Left Mirror
    mov byte [es:bx+1], 1     ; Blue Pillar
    mov byte [es:bx+22], 1    ; Blue Pillar
    mov byte [es:bx+23], 1    ; Right Mirror
    mov cx, 20
b_dwf2:
    mov byte [es:bx+2], 0 ; Black Glass
    inc bx
    loop b_dwf2
b_dwf2_skip:
    inc si
   
    ; Row 2 (Y+2): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dwf3_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Blue Pillar
    mov byte [es:bx+21], 1    ; Blue Pillar
    mov cx, 18
b_dwf3:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop b_dwf3
b_dwf3_skip:
    inc si

    ; Row 3 (Y+3): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dwf4_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Blue Pillar
    mov byte [es:bx+21], 1    ; Blue Pillar
    mov cx, 18
b_dwf4:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop b_dwf4
b_dwf4_skip:
    inc si
   
    ; Row 4 (Y+4): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dwf5_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Blue Pillar
    mov byte [es:bx+21], 1    ; Blue Pillar
    mov cx, 18
b_dwf5:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop b_dwf5
b_dwf5_skip:
   
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Blue Car Roof (narrowed) + Sunroof ---
draw_blue_roof:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 2
    mov ax, si          ; Save starting SI for sunroof
b_dr1_:
    cmp si, 200         ; CLIP CHECK
    jge b_dr_skip_row   ; CLIP CHECK
   
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2           ; Start at x+2
    mov cx, 20          ; 20px wide
b_dr2_:
    mov byte [es:bx], 1 ; Light Blue
    inc bx
    loop b_dr2_
   
    ; Redraw borders
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Dark Blue Pillar
    mov byte [es:bx+21], 1    ; Dark Blue Pillar
   
b_dr_skip_row:
    inc si
    dec dx
    jnz b_dr1_
   
    ; Sunroof (8x1 - 1 row)
    cmp ax, 200         ; CLIP CHECK
    jge b_dr_skip_sunroof ; CLIP CHECK
    mov bx, ax          ; Use saved starting SI (first row of roof)
    imul bx, 320
    add bx, di
    add bx, 8           ; Center position
    mov cx, 8           ; Sunroof width
b_sunroof_r:
    mov byte [es:bx], 0   ; Black
    inc bx
    loop b_sunroof_r
b_dr_skip_sunroof:
   
    pop si
    add si, 2
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Blue Car Body + Highlights ---
draw_blue_body:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 10
b_db1:
    cmp si, 200         ; CLIP CHECK
    jge b_db_skip_row   ; CLIP CHECK
   
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1 ; Dark Blue edge
    mov byte [es:bx+23], 1 ; Dark Blue edge
   
    add bx, 1
    mov cx, 22
b_db2:
    mov byte [es:bx], 1 ; Light Blue
    inc bx
    loop b_db2
   
    ; Add highlights
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+5], 15  ; White shine
    mov byte [es:bx+18], 15 ; White shine
   
b_db_skip_row:
    inc si
    dec dx
    jnz b_db1
    pop si
    add si, 10
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Blue Car Rear Windshield (Tapered) ---
draw_blue_windshield_r:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 0 (Y): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dwr1_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Blue Pillar
    mov byte [es:bx+21], 1    ; Blue Pillar
    mov cx, 18
b_dwr1:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop b_dwr1
b_dwr1_skip:
    inc si
   
    ; Row 1 (Y+1): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dwr2_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Blue Pillar
    mov byte [es:bx+21], 1    ; Blue Pillar
    mov cx, 18
b_dwr2:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop b_dwr2
b_dwr2_skip:
    inc si
   
    ; Row 2 (Y+2): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dwr3_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Blue Pillar
    mov byte [es:bx+21], 1    ; Blue Pillar
    mov cx, 18
b_dwr3:
    mov byte [es:bx+3], 0 ; Black Glass
    inc bx
    loop b_dwr3
b_dwr3_skip:
    inc si
   
    ; Row 3 (Y+3): 22px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dwr4_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 1     ; Blue Pillar
    mov byte [es:bx+22], 1    ; Blue Pillar
    mov cx, 20
b_dwr4:
    mov byte [es:bx+2], 0 ; Black Glass
    inc bx
    loop b_dwr4
b_dwr4_skip:
    inc si
   
    ; Row 4 (Y+4): 24px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dwr5_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1       ; Blue Pillar
    mov byte [es:bx+23], 1    ; Blue Pillar
    mov cx, 22
b_dwr5:
    mov byte [es:bx+1], 0 ; Black Glass
    inc bx
    loop b_dwr5
b_dwr5_skip:
   
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Blue Car Trunk (Tapered) + Definition Lines ---
draw_blue_trunk:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 0 (Y): 24px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dt1_skip      ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1       ; Dark Blue
    mov byte [es:bx+23], 1    ; Dark Blue
    mov cx, 22
b_dt1:
    mov byte [es:bx+1], 1 ; Light Blue
    inc bx
    loop b_dt1
b_dt1_skip:
    inc si
   
    ; Row 1 (Y+1): 24px wide + Lines
    cmp si, 200         ; CLIP CHECK
    jge b_dt2_skip      ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1       ; Dark Blue
    mov byte [es:bx+23], 1    ; Dark Blue
    mov cx, 22
b_dt2:
    mov byte [es:bx+1], 1 ; Light Blue
    inc bx
    loop b_dt2
    mov bx, si          ; Reset BX for lines
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 1     ; Trunk Line
    mov byte [es:bx+15], 1    ; Trunk Line
b_dt2_skip:
    inc si
   
    ; Row 2 (Y+2): 24px wide + Lines
    cmp si, 200         ; CLIP CHECK
    jge b_dt3_skip      ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1       ; Dark Blue
    mov byte [es:bx+23], 1    ; Dark Blue
    mov cx, 22
b_dt3:
    mov byte [es:bx+1], 1 ; Light Blue
    inc bx
    loop b_dt3
    mov bx, si          ; Reset BX for lines
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 1     ; Trunk Line
    mov byte [es:bx+15], 1    ; Trunk Line
b_dt3_skip:
    inc si
   
    ; Row 3 (Y+3): 22px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dt4_skip      ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 1     ; Dark Blue
    mov byte [es:bx+22], 1    ; Dark Blue
    mov cx, 20
b_dt4:
    mov byte [es:bx+2], 1 ; Light Blue
    inc bx
    loop b_dt4
b_dt4_skip:
    inc si
   
    ; Row 4 (Y+4): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge b_dt5_skip      ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Dark Blue
    mov byte [es:bx+21], 1    ; Dark Blue
    mov cx, 18
b_dt5:
    mov byte [es:bx+3], 1 ; Light Blue
    inc bx
    loop b_dt5
b_dt5_skip:
   
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Blue Car Rear Bumper + Taillights ---
draw_blue_rear_bumper:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 0 (Y): 20px wide
    cmp si, 200         ; CLIP CHECK
    jge b_drb1_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Dark Blue
    mov byte [es:bx+21], 1    ; Dark Blue
    mov cx, 18
b_drb1:
    mov byte [es:bx+3], 1 ; Light Blue
    inc bx
    loop b_drb1
b_drb1_skip:
    inc si
   
    ; Row 1 (Y+1): 20px wide + Taillights
    cmp si, 200         ; CLIP CHECK
    jge b_drb2_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1     ; Dark Blue Edge
    mov byte [es:bx+3], 4     ; Taillight (Red)
    mov byte [es:bx+4], 4     ; Taillight (Red)
    mov byte [es:bx+19], 4    ; Taillight (Red)
    mov byte [es:bx+20], 4    ; Taillight (Red)
    mov byte [es:bx+21], 1    ; Dark Blue Edge
    mov cx, 14 ; Bumper
b_drb2:
    mov byte [es:bx+5], 8 ; Gray Bumper
    inc bx
    loop b_drb2
b_drb2_skip:
    inc si
   
    ; Row 2 (Y+2): 18px wide
    cmp si, 200         ; CLIP CHECK
    jge b_drb3_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+3], 1     ; Dark Blue
    mov byte [es:bx+20], 1    ; Dark Blue
    mov cx, 16
b_drb3:
    mov byte [es:bx+4], 8 ; Gray Bumper
    inc bx
    loop b_drb3
b_drb3_skip:
   
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--- Blue Car Rear Taper (Underside) ---
draw_blue_rear_taper:
    push ax
    push bx
    push cx
    push si
    ; Row 1: 16px
    cmp si, 200         ; CLIP CHECK
    jge b_drt1_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 4
    mov cx, 16
b_drt1:
    mov byte [es:bx], 1 ; Dark Blue
    inc bx
    loop b_drt1
b_drt1_skip:
    inc si
   
    ; Row 2: 10px
    cmp si, 200         ; CLIP CHECK
    jge b_drt2_skip     ; CLIP CHECK
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
b_drt2:
    mov byte [es:bx], 1 ; Dark Blue
    inc bx
    loop b_drt2
b_drt2_skip:
   
    pop si
    pop cx
    pop bx
    pop ax
    ret


car_x dw 0
car_y dw 0
blue_car_x dw 0
blue_car_y dw 0
blue_car_x_old dw 0 ; Stores last-drawn X position
blue_car_y_old dw 0 ; Stores last-drawn Y position
lane_offset dw 0
coin_x dw 0         ;  Coin X position
coin_y dw 0         ; Coin Y position
coin_x_old dw 0     ; Coin last X position
coin_y_old dw 0     ; Coin last Y position

; ------------------------------------------------------------------
; Subroutine: get_random_0_to_2
; Description: Uses the RTC's "current second" to generate a
;              pseudo-random number.
; Returns: A random number (0, 1, or 2) in the BX register.
; Clobbers: AX, CX, DX (but restores them before returning)
; ------------------------------------------------------------------
get_random_0_to_2:
    push ax         ; Save registers we are about to use
    push cx
    push dx

    ; 1. Get current second from RTC (in BCD format)
    mov al, 0       ; Command 00h = Get current second
    out 0x70, al    ; Send command to RTC
    jmp short rtc_delay ; Waste time (as per hint)
rtc_delay:
    in al, 0x71     ; ***FIXED: Added 'in' instruction***

    ; 2. Convert BCD (in AL) to Binary (in AX)
    mov ah, al      ; Copy BCD to AH (AX = 0x5959)
    shr ah, 4       ; Isolate high nibble (tens): AH = 0x05
    and al, 0x0F    ; Isolate low nibble (ones): AL = 0x09
   
    push ax         ; Save the 'ones' digit (AL) on the stack
    mov al, ah      ; Move the 'tens' digit (AH) to AL
    xor ah, ah      ; Clear AH, so AX = 0x0005
   
    mov cx, 10
    mul cx          ; AX = AL * CX (e.g., 5 * 10 = 50)
   
    pop dx          ; Get the 'ones' digit back (it's in DL)
    xor dh, dh      ; Clear DH, so DX = 0x0009
   
    add ax, dx      ; AX = 50 + 9 = 59. AX now holds the binary value.

    ; 3. Get remainder of (seconds / 3) to get 0, 1, or 2
    mov cx, 3      
    xor dx, dx      ; Clear DX register, required before 16-bit DIV
    div cx          ; Divide AX by CX. Quotient in AX, Remainder in DX.
   
    ; 4. Move the remainder (our random number) into BX
    mov bx, dx

    ; 5. Restore registers and return
    pop dx
    pop cx
    pop ax
    ret
; ------------------------------------------------------------------

fuel_msg db 'FUEL: ', 0  ; NEW: The string to be printed
