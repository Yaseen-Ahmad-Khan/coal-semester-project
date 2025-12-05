[org 0x100]


mov ax, 0013h
int 10h


mov ax, 0A000h
mov es, ax

; Red Car position (centered between lane markers)
mov word [car_x], 148       ; Center X position
mov word [car_y], 120       ; Y position (lower part of screen)

; Blue Car position (in right lane, ahead of red car)
mov word [blue_car_x], 200  ; Right lane position
mov word [blue_car_y], 30   ; Higher up (ahead)


call draw_static_background
call draw_lane_markers
call draw_trees
call draw_blue_car
call draw_car


wait_for_key:
    mov ah, 0
    int 16h
    
    ; Return to text mode 03h
    mov ax, 0003h
    int 10h
    
    ; Exit properly
    mov ax, 4C00h
    int 21h


draw_static_background:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    xor si, si       ; row counter (0-199)
    
bg_row:
    xor di, di       ; column counter (0-319)
    mov bx, si
    imul bx, 320     ; BX = row offset
    
bg_col:
    mov al, 8        ; default road gray
    
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
    cmp di, 79
    je bg_set_black
    cmp di, 83
    je bg_set_black
    cmp di, 237
    je bg_set_black
    cmp di, 238
    je bg_set_black
    
    ; Check if we're in grass area
    cmp di, 80
    jb bg_set_grass
    cmp di, 240
    ja bg_set_grass
    jmp bg_write_pixel


bg_set_black:
    mov al, 0        ; black border
    jmp bg_write_pixel
    
bg_set_grass:
    ; Alternate between light green (2) and dark green (10) in 8-pixel horizontal boxes
    mov ax, si       ; Use row counter instead of column
    shr ax, 3        ; Divide by 8 to get box number
    test ax, 1       ; Check if odd or even
    jz bg_light_green
    mov al, 10       ; medium-dark green
    jmp bg_write_pixel
bg_light_green:
    mov al, 2        ; light green
    jmp bg_write_pixel

bg_set_white_border:
    mov al, 15       ; white border
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


draw_lane_markers:
    push ax
    push bx
    push cx
    push si
    push di
    
    xor si, si       ; row counter
    
lane_row:
    ; Create repeating pattern every 75 pixels
    mov cx, si
    
check_pattern:
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
    mov byte [es:bx+di], 15  ; White
    inc di
    cmp di, 133
    jl draw_left_marker
    
    ; Draw on right lane (188-192)
    mov di, 188
draw_right_marker:
    mov byte [es:bx+di], 15  ; White
    inc di
    cmp di, 193
    jl draw_right_marker
    
skip_lane_draw:
    inc si
    cmp si, 200
    jl lane_row
    
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret


draw_trees:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Tree 1 - left side
    ; Trunk
    mov si, 45           ; Y position
    mov di, 58           ; X position
    mov dx, 6            ; Trunk height
tree1_trunk_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 3            ; Trunk width
tree1_trunk_col:
    mov byte [es:bx], 6  ; Brown
    inc bx
    loop tree1_trunk_col
    inc si
    pop dx
    dec dx
    jnz tree1_trunk_row
    
    ; Foliage (top)
    mov si, 38           ; Y position
    mov di, 56           ; X position (centered over trunk)
    mov dx, 7            ; Foliage height
tree1_foliage_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 7            ; Foliage width
tree1_foliage_col:
    mov al, 2            ; Light green
    cmp cx, 4
    jg tree1_dark
    mov al, 10           ; Dark green
tree1_dark:
    mov byte [es:bx], al
    inc bx
    loop tree1_foliage_col
    inc si
    pop dx
    dec dx
    jnz tree1_foliage_row
    
    ; Tree 2 - left side
    ; Trunk
    mov si, 95           ; Y position
    mov di, 60           ; X position
    mov dx, 7            ; Trunk height
tree2_trunk_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 3            ; Trunk width
tree2_trunk_col:
    mov byte [es:bx], 6  ; Brown
    inc bx
    loop tree2_trunk_col
    inc si
    pop dx
    dec dx
    jnz tree2_trunk_row
    
    ; Foliage
    mov si, 87           ; Y position
    mov di, 57           ; X position
    mov dx, 8            ; Foliage height
tree2_foliage_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 9            ; Foliage width
tree2_foliage_col:
    mov al, 10           ; Dark green
    cmp cx, 5
    jg tree2_light
    mov al, 2            ; Light green
tree2_light:
    mov byte [es:bx], al
    inc bx
    loop tree2_foliage_col
    inc si
    pop dx
    dec dx
    jnz tree2_foliage_row
    
    ; Tree 3 - left side
    ; Trunk
    mov si, 155          ; Y position
    mov di, 57           ; X position
    mov dx, 8            ; Trunk height
tree3_trunk_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 4            ; Trunk width
tree3_trunk_col:
    mov byte [es:bx], 6  ; Brown
    inc bx
    loop tree3_trunk_col
    inc si
    pop dx
    dec dx
    jnz tree3_trunk_row
    
    ; Foliage
    mov si, 146          ; Y position
    mov di, 54           ; X position
    mov dx, 9            ; Foliage height
tree3_foliage_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 10           ; Foliage width
tree3_foliage_col:
    mov al, 2            ; Light green
    cmp cx, 5
    jl tree3_dark
    mov al, 10           ; Dark green
tree3_dark:
    mov byte [es:bx], al
    inc bx
    loop tree3_foliage_col
    inc si
    pop dx
    dec dx
    jnz tree3_foliage_row
    
    ; Tree 4 - right side
    ; Trunk
    mov si, 52           ; Y position
    mov di, 261          ; X position
    mov dx, 6            ; Trunk height
tree4_trunk_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 3            ; Trunk width
tree4_trunk_col:
    mov byte [es:bx], 6  ; Brown
    inc bx
    loop tree4_trunk_col
    inc si
    pop dx
    dec dx
    jnz tree4_trunk_row
    
    ; Foliage
    mov si, 45           ; Y position
    mov di, 258          ; X position
    mov dx, 7            ; Foliage height
tree4_foliage_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 9            ; Foliage width
tree4_foliage_col:
    mov al, 10           ; Dark green
    cmp cx, 5
    jg tree4_light
    mov al, 2            ; Light green
tree4_light:
    mov byte [es:bx], al
    inc bx
    loop tree4_foliage_col
    inc si
    pop dx
    dec dx
    jnz tree4_foliage_row
    
    ; Tree 5 - right side
    ; Trunk
    mov si, 115          ; Y position
    mov di, 259          ; X position
    mov dx, 7            ; Trunk height
tree5_trunk_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 4            ; Trunk width
tree5_trunk_col:
    mov byte [es:bx], 6  ; Brown
    inc bx
    loop tree5_trunk_col
    inc si
    pop dx
    dec dx
    jnz tree5_trunk_row
    
    ; Foliage
    mov si, 106          ; Y position
    mov di, 256          ; X position
    mov cx, 10           ; Foliage width
    mov dx, 9            ; Foliage height
tree5_foliage_row:
    push dx
    push cx
    mov bx, si
    imul bx, 320
    add bx, di
tree5_foliage_col:
    mov al, 2            ; Light green
    cmp cx, 6
    jg tree5_dark
    mov al, 10           ; Dark green
tree5_dark:
    mov byte [es:bx], al
    inc bx
    loop tree5_foliage_col
    inc si
    pop cx
    pop dx
    dec dx
    jnz tree5_foliage_row
    
    ; Tree 6 - right side
    ; Trunk
    mov si, 170          ; Y position
    mov di, 260          ; X position
    mov dx, 8            ; Trunk height
tree6_trunk_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 3            ; Trunk width
tree6_trunk_col:
    mov byte [es:bx], 6  ; Brown
    inc bx
    loop tree6_trunk_col
    inc si
    pop dx
    dec dx
    jnz tree6_trunk_row
    
    ; Foliage
    mov si, 162          ; Y position
    mov di, 257          ; X position
    mov dx, 8            ; Foliage height
tree6_foliage_row:
    push dx
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 9            ; Foliage width
tree6_foliage_col:
    mov al, 10           ; Dark green
    cmp cx, 5
    jl tree6_light
    mov al, 2            ; Light green
tree6_light:
    mov byte [es:bx], al
    inc bx
    loop tree6_foliage_col
    inc si
    pop dx
    dec dx
    jnz tree6_foliage_row
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret






draw_car:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov si, [car_y]     ; Start Y position
    mov di, [car_x]     ; Start X position
    
    
    
    ; Draw shadow first
        
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



draw_front:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, si
    ; Row 0: narrow (10px)
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
df1:
    mov byte [es:bx], 4 ; Dark Red
    inc bx
    dec cx
    jnz df1
    inc dx
    ; Row 1: wider (16px)
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 4
    mov cx, 16
df2:
    mov byte [es:bx], 12 ; Light Red
    inc bx
    dec cx
    jnz df2
    inc dx
    ; Row 2: full (20px)
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 2
    mov cx, 20
df3:
    mov byte [es:bx], 12 ; Light Red
    inc bx
    dec cx
    jnz df3
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_hood:
    push ax
    push bx
    push cx
    push dx
    push si
    mov ax, 3
dh1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 4 ; Dark Red
    mov byte [es:bx+11], 4 ; Dark Red
    mov byte [es:bx+22], 4 ; Dark Red
    add bx, 1
    mov cx, 10
dh2:
    mov byte [es:bx], 12 ; Light Red
    inc bx
    dec cx
    jnz dh2
    inc bx
    mov cx, 10
dh3:
    mov byte [es:bx], 12 ; Light Red
    inc bx
    dec cx
    jnz dh3
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

draw_windshield_f:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 5
dwf1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 4 ; Dark Red
    mov byte [es:bx+1], 0
    mov byte [es:bx+2], 0
    mov byte [es:bx+3], 0
    mov byte [es:bx+4], 0
    mov byte [es:bx+5], 0
    mov byte [es:bx+6], 0
    mov byte [es:bx+7], 0
    mov byte [es:bx+8], 0
    mov byte [es:bx+9], 0
    mov byte [es:bx+10], 0
    mov byte [es:bx+11], 0
    mov byte [es:bx+12], 0
    mov byte [es:bx+13], 0
    mov byte [es:bx+14], 0
    mov byte [es:bx+15], 0
    mov byte [es:bx+16], 0
    mov byte [es:bx+17], 0
    mov byte [es:bx+18], 0
    mov byte [es:bx+19], 0
    mov byte [es:bx+20], 0
    mov byte [es:bx+21], 0
    mov byte [es:bx+22], 4 ; Dark Red
    inc si
    dec dx
    jnz dwf1
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_roof:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 2
    mov ax, si           ; Save starting SI for sunroof
dr1_:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov cx, 22
dr2_:
    mov byte [es:bx], 12 ; Light Red
    inc bx
    dec cx
    jnz dr2_
    inc si
    dec dx
    jnz dr1_
    
    ;sunroof
    mov bx, ax           ; Use saved starting SI
    imul bx, 320
    add bx, di
    add bx, 8            ; Center position (offset 8 from left edge)
    mov cx, 8            ; Sunroof width
sunroof_r:
    mov byte [es:bx], 0  ; Black
    inc bx
    dec cx
    jnz sunroof_r
    
    pop si
    add si, 2
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_body:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 10
db1:
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 4 ; Dark Red
    mov byte [es:bx+23], 4 ; Dark Red
    add bx, 1
    mov cx, 22
db2:
    mov byte [es:bx], 12 ; Light Red
    inc bx
    dec cx
    jnz db2
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

draw_windshield_r:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 5
dwr1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 4 ; Dark Red
    mov byte [es:bx+1], 0
    mov byte [es:bx+2], 0
    mov byte [es:bx+3], 0
    mov byte [es:bx+4], 0
    mov byte [es:bx+5], 0
    mov byte [es:bx+6], 0
    mov byte [es:bx+7], 0
    mov byte [es:bx+8], 0
    mov byte [es:bx+9], 0
    mov byte [es:bx+10], 0
    mov byte [es:bx+11], 0
    mov byte [es:bx+12], 0
    mov byte [es:bx+13], 0
    mov byte [es:bx+14], 0
    mov byte [es:bx+15], 0
    mov byte [es:bx+16], 0
    mov byte [es:bx+17], 0
    mov byte [es:bx+18], 0
    mov byte [es:bx+19], 0
    mov byte [es:bx+20], 0
    mov byte [es:bx+21], 0
    mov byte [es:bx+22], 4 ; Dark Red
    inc si
    dec dx
    jnz dwr1
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_trunk:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 5
dt1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 4 ; Dark Red
    mov byte [es:bx+11], 4 ; Dark Red
    mov byte [es:bx+22], 4 ; Dark Red
    add bx, 1
    mov cx, 10
dt2:
    mov byte [es:bx], 12 ; Light Red
    inc bx
    dec cx
    jnz dt2
    inc bx
    mov cx, 10
dt3:
    mov byte [es:bx], 12 ; Light Red
    inc bx
    dec cx
    jnz dt3
    inc si
    dec dx
    jnz dt1
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_rear_bumper:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 3
drb1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2
    mov byte [es:bx], 12 ; Light Red
    mov byte [es:bx+1], 12 ; Light Red
    mov byte [es:bx+16], 12 ; Light Red
    mov byte [es:bx+17], 12 ; Light Red
    add bx, 2
    mov cx, 14
drb2:
    mov byte [es:bx], 4 ; Dark Red
    inc bx
    dec cx
    jnz drb2
    inc si
    dec dx
    jnz drb1
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_rear_taper:
    push ax
    push bx
    push cx
    push si
    ; Row 1: 16px
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 4
    mov cx, 16
drt1:
    mov byte [es:bx], 4 ; Dark Red
    inc bx
    dec cx
    jnz drt1
    inc si
    ; Row 2: 10px
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
drt2:
    mov byte [es:bx], 4 ; Dark Red
    inc bx
    dec cx
    jnz drt2
    pop si
    pop cx
    pop bx
    pop ax
    ret





draw_blue_car:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov si, [blue_car_y]     ; Start Y position
    mov di, [blue_car_x]     ; Start X position
    
    
    
   
    
    
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

;blue car

draw_blue_front:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, si
    ; Row 0: narrow (10px)
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
b_df1:
    mov byte [es:bx], 1 ; Dark Blue
    inc bx
    dec cx
    jnz b_df1
    inc dx
    ; Row 1: wider (16px)
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 4
    mov cx, 16
b_df2:
    mov byte [es:bx], 9 ; Light Blue
    inc bx
    dec cx
    jnz b_df2
    inc dx
    ; Row 2: full (20px)
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 2
    mov cx, 20
b_df3:
    mov byte [es:bx], 9 ; Light Blue
    inc bx
    dec cx
    jnz b_df3
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_blue_hood:
    push ax
    push bx
    push cx
    push dx
    push si
    mov ax, 3
b_dh1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 1 ; Dark Blue
    mov byte [es:bx+11], 1 ; Dark Blue
    mov byte [es:bx+22], 1 ; Dark Blue
    add bx, 1
    mov cx, 10
b_dh2:
    mov byte [es:bx], 9 ; Light Blue
    inc bx
    dec cx
    jnz b_dh2
    inc bx
    mov cx, 10
b_dh3:
    mov byte [es:bx], 9 ; Light Blue
    inc bx
    dec cx
    jnz b_dh3
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

draw_blue_windshield_f:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 5
b_dwf1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 1 ; Dark Blue
    mov byte [es:bx+1], 0
    mov byte [es:bx+2], 0
    mov byte [es:bx+3], 0
    mov byte [es:bx+4], 0
    mov byte [es:bx+5], 0
    mov byte [es:bx+6], 0
    mov byte [es:bx+7], 0
    mov byte [es:bx+8], 0
    mov byte [es:bx+9], 0
    mov byte [es:bx+10], 0
    mov byte [es:bx+11], 0
    mov byte [es:bx+12], 0
    mov byte [es:bx+13], 0
    mov byte [es:bx+14], 0
    mov byte [es:bx+15], 0
    mov byte [es:bx+16], 0
    mov byte [es:bx+17], 0
    mov byte [es:bx+18], 0
    mov byte [es:bx+19], 0
    mov byte [es:bx+20], 0
    mov byte [es:bx+21], 0
    mov byte [es:bx+22], 1 ; Dark Blue
    inc si
    dec dx
    jnz b_dwf1
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_blue_roof:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 2
    mov ax, si           ; Save starting SI for sunroof
b_dr1_:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov cx, 22
b_dr2_:
    mov byte [es:bx], 9 ; Light Blue
    inc bx
    dec cx
    jnz b_dr2_
    inc si
    dec dx
    jnz b_dr1_
    
   
    mov bx, ax           ; Use saved starting SI
    imul bx, 320
    add bx, di
    add bx, 8            ; Center position
    mov cx, 8            ; Sunroof width
b_sunroof_r:
    mov byte [es:bx], 0  ; Black
    inc bx
    dec cx
    jnz b_sunroof_r
    
    pop si
    add si, 2
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_blue_body:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 10
b_db1:
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1 ; Dark Blue
    mov byte [es:bx+23], 1 ; Dark Blue
    add bx, 1
    mov cx, 22
b_db2:
    mov byte [es:bx], 9 ; Light Blue
    inc bx
    dec cx
    jnz b_db2
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

draw_blue_windshield_r:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 5
b_dwr1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 1 ; Dark Blue
    mov byte [es:bx+1], 0
    mov byte [es:bx+2], 0
    mov byte [es:bx+3], 0
    mov byte [es:bx+4], 0
    mov byte [es:bx+5], 0
    mov byte [es:bx+6], 0
    mov byte [es:bx+7], 0
    mov byte [es:bx+8], 0
    mov byte [es:bx+9], 0
    mov byte [es:bx+10], 0
    mov byte [es:bx+11], 0
    mov byte [es:bx+12], 0
    mov byte [es:bx+13], 0
    mov byte [es:bx+14], 0
    mov byte [es:bx+15], 0
    mov byte [es:bx+16], 0
    mov byte [es:bx+17], 0
    mov byte [es:bx+18], 0
    mov byte [es:bx+19], 0
    mov byte [es:bx+20], 0
    mov byte [es:bx+21], 0
    mov byte [es:bx+22], 1 ; Dark Blue
    inc si
    dec dx
    jnz b_dwr1
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_blue_trunk:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 5
b_dt1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 1 ; Dark Blue
    mov byte [es:bx+11], 1 ; Dark Blue
    mov byte [es:bx+22], 1 ; Dark Blue
    add bx, 1
    mov cx, 10
b_dt2:
    mov byte [es:bx], 9 ; Light Blue
    inc bx
    dec cx
    jnz b_dt2
    inc bx
    mov cx, 10
b_dt3:
    mov byte [es:bx], 9 ; Light Blue
    inc bx
    dec cx
    jnz b_dt3
    inc si
    dec dx
    jnz b_dt1
    pop si
    add si, 5
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_blue_rear_bumper:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 3
b_drb1:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2
    mov byte [es:bx], 9 ; Light Blue
    mov byte [es:bx+1], 9 ; Light Blue
    mov byte [es:bx+16], 9 ; Light Blue
    mov byte [es:bx+17], 9 ; Light Blue
    add bx, 2
    mov cx, 14
b_drb2:
    mov byte [es:bx], 1 ; Dark Blue
    inc bx
    dec cx
    jnz b_drb2
    inc si
    dec dx
    jnz b_drb1
    pop si
    add si, 3
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_blue_rear_taper:
    push ax
    push bx
    push cx
    push si
    ; Row 1: 16px
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 4
    mov cx, 16
b_drt1:
    mov byte [es:bx], 1 ; Dark Blue
    inc bx
    dec cx
    jnz b_drt1
    inc si
    ; Row 2: 10px
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
b_drt2:
    mov byte [es:bx], 1 ; Dark Blue
    inc bx
    dec cx
    jnz b_drt2
    pop si
    pop cx
    pop bx
    pop ax
    ret


car_x dw 0
car_y dw 0
blue_car_x dw 0
blue_car_y dw 0
