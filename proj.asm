[org 0x100]

; ==================================================================
; SECTION 1: TITLE SCREEN (LOAD FROM DISK)
; ==================================================================

; -------------------------------
; Set Mode 13h (320x200, 256 colors)
; -------------------------------
mov ax, 0013h
int 10h

; -------------------------------
; 1. Open and Read Palette File (mspal.bin)
; -------------------------------
mov ah, 3Dh
mov al, 0
mov dx, file_pal
int 21h
jc load_error_trampoline
mov bx, ax

; Read Palette Data
mov ah, 3Fh
mov cx, 768
mov dx, pal_buffer
int 21h

; Close Palette File
mov ah, 3Eh
int 21h

; Apply Palette
mov dx, 03C8h
xor al, al
out dx, al
mov dx, 03C9h
mov si, pal_buffer
mov cx, 768
out_pal_loop:
    mov al, [si]
    out dx, al
    inc si
    loop out_pal_loop

; -------------------------------
; 2. Open and Read Pixels File (mspixels.bin)
; -------------------------------
mov ah, 3Dh
mov al, 0
mov dx, file_pix
int 21h
jc load_error_trampoline
mov bx, ax

; Read Pixels
push ds
mov ax, 0A000h
mov ds, ax
xor dx, dx
mov cx, 64000
mov ah, 3Fh
int 21h
pop ds

; Close Pixel File
mov ah, 3Eh
int 21h

jmp wait_for_space

load_error_trampoline:
    jmp load_error

load_error:
    mov ah, 0Bh
    mov bh, 00h
    mov bl, 4
    int 10h
    jmp quit_direct_dos

; -------------------------------
; Wait for SPACEBAR to Continue
; -------------------------------
wait_for_space:
    mov ah, 0
    int 16h
   
    ; Check for ESC
    cmp ah, 01h
    je title_esc_pressed

    cmp al, 20h      ; Spacebar
    jne wait_for_space

    jmp section_1_5_start

title_esc_pressed:
    mov ax, 0xA000
    mov es, ax
    call draw_confirmation_box

title_wait_response:
    mov ah, 0
    int 16h
    cmp al, 'y'
    je quit_direct_dos_jump
    cmp al, 'Y'
    je quit_direct_dos_jump
    cmp al, 'n'
    je title_resume
    cmp al, 'N'
    je title_resume
    cmp ah, 01h
    je title_resume
    jmp title_wait_response

title_resume:
    call erase_confirmation_box
    jmp wait_for_space

quit_direct_dos_jump:
    jmp quit_direct_dos

; ==================================================================
; SECTION 1.5: INSTRUCTIONS SCREEN
; ==================================================================
section_1_5_start:

; Load Instructions Palette
mov ah, 3Dh
mov al, 0
mov dx, file_is_pal
int 21h
jc load_is_error
mov bx, ax
mov ah, 3Fh
mov cx, 768
mov dx, pal_buffer
int 21h
mov ah, 3Eh
int 21h
mov dx, 03C8h
xor al, al
out dx, al
mov dx, 03C9h
mov si, pal_buffer
mov cx, 768
out_is_pal_loop:
    mov al, [si]
    out dx, al
    inc si
    loop out_is_pal_loop

; Load Instructions Pixels
mov ah, 3Dh
mov al, 0
mov dx, file_is_pix
int 21h
jc load_is_error
mov bx, ax
push ds
mov ax, 0A000h
mov ds, ax
xor dx, dx
mov cx, 64000
mov ah, 3Fh
int 21h
pop ds
mov ah, 3Eh
int 21h
jmp wait_for_n

load_is_error:
    jmp start_data_entry

wait_for_n:
    mov ah, 0
    int 16h
    cmp ah, 01h
    je instructions_esc_pressed
    cmp al, 'n'
    je start_data_entry
    cmp al, 'N'
    je start_data_entry
    jmp wait_for_n

instructions_esc_pressed:
    mov ax, 0xA000
    mov es, ax
    call draw_confirmation_box
instructions_wait_response:
    mov ah, 0
    int 16h
    cmp al, 'y'
    je quit_direct_dos_jump
    cmp al, 'Y'
    je quit_direct_dos_jump
    cmp al, 'n'
    je instructions_resume
    cmp al, 'N'
    je instructions_resume
    cmp ah, 01h
    je instructions_resume
    jmp instructions_wait_response
instructions_resume:
    call erase_confirmation_box
    jmp wait_for_n

; ==================================================================
; SECTION 1.8: PLAYER DATA ENTRY (IMAGE + INPUT)
; ==================================================================
start_data_entry:

    ; 1. LOAD NAME/ROLL IMAGE (nrpal.bin / nrpixels.bin)
   
    ; Palette
    mov ah, 3Dh
    mov al, 0
    mov dx, file_nr_pal
    int 21h
    jc entry_load_error
    mov bx, ax
    mov ah, 3Fh
    mov cx, 768
    mov dx, pal_buffer
    int 21h
    mov ah, 3Eh
    int 21h
    mov dx, 03C8h
    xor al, al
    out dx, al
    mov dx, 03C9h
    mov si, pal_buffer
    mov cx, 768
out_nr_pal_loop:
    mov al, [si]
    out dx, al
    inc si
    loop out_nr_pal_loop

    ; Pixels
    mov ah, 3Dh
    mov al, 0
    mov dx, file_nr_pix
    int 21h
    jc entry_load_error
    mov bx, ax
    push ds
    mov ax, 0A000h
    mov ds, ax
    xor dx, dx
    mov cx, 64000
    mov ah, 3Fh
    int 21h
    pop ds
    mov ah, 3Eh
    int 21h


    push cs
    pop es
    ; ==========================================================

    jmp start_typing

entry_load_error:
    mov ax, 0013h
    int 10h

start_typing:
    ; 2. Get Name Input (No Prompt Displayed, just cursor)
    ; Position cursor for Name
    mov ah, 02h
    mov bh, 00h
    mov dh, 6        ; Row
    mov dl, 13       ; Column
    int 10h
   
    mov di, player_name
    call get_input_string

    ; 3. Get Roll Number Input
    ; Position cursor for Roll No
    mov ah, 02h
    mov bh, 00h
    mov dh, 13       ; Row
    mov dl, 13       ; Column
    int 10h
   
    mov di, player_roll
    call get_input_string

    ; Fall through to Story

; ==================================================================
; SECTION 1.9: STORY/START SCREEN (RESTORED)
; ==================================================================
section_1_9_start:

; Load Story Palette
mov ah, 3Dh
mov al, 0
mov dx, file_st_pal
int 21h
jc load_st_error
mov bx, ax
mov ah, 3Fh
mov cx, 768
mov dx, pal_buffer
int 21h
mov ah, 3Eh
int 21h
mov dx, 03C8h
xor al, al
out dx, al
mov dx, 03C9h
mov si, pal_buffer
mov cx, 768
out_st_pal_loop:
    mov al, [si]
    out dx, al
    inc si
    loop out_st_pal_loop

; Load Story Pixels
mov ah, 3Dh
mov al, 0
mov dx, file_st_pix
int 21h
jc load_st_error
mov bx, ax
push ds
mov ax, 0A000h
mov ds, ax
xor dx, dx
mov cx, 64000
mov ah, 3Fh
int 21h
pop ds
mov ah, 3Eh
int 21h
jmp wait_for_space_start

load_st_error:
    jmp start_game

wait_for_space_start:
    mov ah, 0
    int 16h
    cmp ah, 01h
    je story_esc_pressed
    cmp al, 20h      ; Spacebar
    jne wait_for_space_start
    jmp start_game

story_esc_pressed:
    mov ax, 0xA000
    mov es, ax
    call draw_confirmation_box
story_wait_response:
    mov ah, 0
    int 16h
    cmp al, 'y'
    je quit_direct_dos_jump
    cmp al, 'Y'
    je quit_direct_dos_jump
    cmp al, 'n'
    je story_resume
    cmp al, 'N'
    je story_resume
    cmp ah, 01h
    je story_resume
    jmp story_wait_response
story_resume:
    call erase_confirmation_box
    jmp wait_for_space_start

quit_direct_dos:
    push cs
    pop ds
    call remove_music_interrupt
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h

; ==================================================================
; SECTION 2: GAME LOGIC
; ==================================================================
start_game:
; Reset Stack
cli
mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0xFFFE
sti

call setup_music_interrupt

; Init Video
mov ax, 0013h
int 10h
mov ax, 0A000h
mov es, ax

; Flush keys
flush_keys:
    mov ah, 01h
    int 16h
    jz buffer_clean
    mov ah, 00h
    int 16h
    jmp flush_keys
buffer_clean:

; Init Vars
mov word [car_x], 148
mov word [car_y], 120
mov word [car_x_old], 148
mov word [car_y_old], 120
mov word [car_lane], 2
mov word [lane_offset], 0
mov word [game_state], 0
mov word [score], 0
mov word [collision_flag], 0

; --- INIT FUEL VARS ---
mov word [fuel_val], 40      ; Max width in pixels (reduced from 60)
mov word [fuel_timer], 0     ; Reset timer
mov word [fuel_empty_flag], 0

; After coin initialization (around line with coin_y_old), add:
mov word [fuel_can_x], 160
mov word [fuel_can_y], -50
mov word [fuel_can_x_old], 160
mov word [fuel_can_y_old], -50
mov word [fuel_can_active], 0
mov word [fuel_spawn_counter], 0

; Randomize positions
call get_random_0_to_2
    cmp bx, 0
    je lane1_initial
    cmp bx, 1
    je lane2_initial
    mov word [blue_car_x], 203
    jmp initialize_y
; ... inside start_game ...

lane1_initial:
    mov word [blue_car_x], 90
    jmp initialize_y
lane2_initial:
    mov word [blue_car_x], 148
initialize_y:
 
    mov word [blue_car_y], -45
    ; -----------------------------------------------
   
mov ax, [blue_car_x]
mov [blue_car_x_old], ax
mov word [blue_car_y_old], -45  ; Update old Y as well

call get_random_0_to_2
    cmp bx, 0
    je coin_lane1_initial
    cmp bx, 1
    je coin_lane2_initial
    mov word [coin_x], 215
    jmp coin_initialize_y
coin_lane1_initial:
    mov word [coin_x], 105
    jmp coin_initialize_y
coin_lane2_initial:
    mov word [coin_x], 160
coin_initialize_y:
    mov word [coin_y], 80
mov ax, [coin_x]
mov [coin_x_old], ax
mov word [coin_y_old], 80

; Draw Initial
call draw_static_background
call draw_car
call draw_fuel_text
call draw_fuel_bar  ; Draw initial full bar
call draw_score

mov word [game_state], 1

; LOOP
animation_loop:
    cmp word [game_state], 1
    je running_game
    cmp word [game_state], 2
    jne check_exit
    jmp paused_game

check_exit:
    jmp exit_game
running_game:
    mov cx, 0x0001
    mov dx, 0x0000
    mov ah, 86h
    int 15h
   
    call handle_input
   
   
    cmp word [game_state], 1
    je continue_render
    jmp animation_loop
continue_render:
   
    call draw_scrolling_grass
    call draw_lane_markers
   
    call erase_blue_car
    mov ax, [blue_car_y]
    mov [blue_car_y_old], ax
    mov ax, [blue_car_x]
    mov [blue_car_x_old], ax
   
    mov ax, [blue_car_y]
    add ax, 4
    mov [blue_car_y], ax
   
    ; Collision
    call check_collision
    cmp word [collision_flag], 1
    jne no_collision_continue
    jmp game_over_collision
no_collision_continue:
   
    cmp ax, 200
    jl bnao

    ; 1. Check distance from Coin
    mov cx, [coin_y]
    cmp cx, 70              ; Safe distance (70 pixels)
    jl keep_blue_car_waiting

    ; 2. Check distance from Fuel (only if active)
    cmp word [fuel_can_active], 1
    jne spawn_blue_car_now
    mov cx, [fuel_can_y]
    cmp cx, 70              ; Safe distance
    jl keep_blue_car_waiting

spawn_blue_car_now:
    ; Safe to spawn - proceed with standard reset

   
   
    mov word [blue_car_y], -45
    ; -------------------------------------------------

    call get_random_0_to_2
    cmp bx, 0
    je lane1
    ; ... rest of the code is same ...
    cmp bx, 1
    je lane2
    mov word [blue_car_x], 203
    jmp bnao
lane1:
    mov word [blue_car_x], 90
    jmp bnao
lane2:
    mov word [blue_car_x], 148
    jmp bnao

keep_blue_car_waiting:
    ; Not safe yet, keep it off-screen
    mov word [blue_car_y], 205
    jmp bnao

   
bnao:
    call draw_blue_car

    call erase_coin
    mov ax, [coin_y]
    mov [coin_y_old], ax
    mov ax, [coin_x]
    mov [coin_x_old], ax
   
    mov ax, [coin_y]
    add ax, 4
    mov [coin_y], ax
   
    ; Coin Check
    call check_coin_collection
   
    cmp ax, 200
    jb cnao


    ; 1. Check distance from Blue Car
    mov cx, [blue_car_y]
    cmp cx, 70          ; Safe distance
    jl keep_coin_waiting

    ; 2. Check distance from Fuel (only if active)
    cmp word [fuel_can_active], 1
    jne spawn_coin_now
    mov cx, [fuel_can_y]
    cmp cx, 70          ; Safe distance
    jl keep_coin_waiting

spawn_coin_now:
    mov word [coin_y], 10
   
    call get_random_0_to_2
    cmp bx, 0
    je coin_lane1
    cmp bx, 1
    je coin_lane2
    mov word [coin_x], 215
    jmp cnao
coin_lane1:
    mov word [coin_x], 105
    jmp cnao
coin_lane2:
    mov word [coin_x], 160
    jmp cnao

keep_coin_waiting:
    ; Not safe yet, keep coin off-screen
    mov word [coin_y], 205
    jmp cnao
 

cnao:
    call draw_coin
    ;FUEL CAN LOGIC
    inc word [fuel_spawn_counter]
   
    ; Spawn new fuel can every 150 frames (less frequent than coins)
    cmp word [fuel_can_active], 0
    jne fuel_can_already_active
    cmp word [fuel_spawn_counter], 50
    jl fuel_can_already_active
 


   
    ; 1. Check Blue Car Position
    mov ax, [blue_car_y]
    cmp ax, 70              ; If car is in top 70px
    jl fuel_can_already_active ; Don't spawn yet, try next frame
   
    ; 2. Check Coin Position
    mov ax, [coin_y]
    cmp ax, 70              ; If coin is in top 70px
    jl fuel_can_already_active ; Don't spawn yet


   
    ; Spawn new fuel can
    mov word [fuel_spawn_counter], 0
    mov word [fuel_can_active], 1
    mov word [fuel_can_y], 10
   
    ; Random lane for fuel can
    call get_random_0_to_2
    cmp bx, 0
    je fuel_lane1_spawn
    cmp bx, 1
    je fuel_lane2_spawn
    mov word [fuel_can_x], 215
    jmp fuel_can_already_active
fuel_lane1_spawn:
    mov word [fuel_can_x], 105
    jmp fuel_can_already_active
fuel_lane2_spawn:
    mov word [fuel_can_x], 160
   
fuel_can_already_active:
    ; Update fuel can if active
    cmp word [fuel_can_active], 0
    je skip_fuel_can_update
   
    call erase_fuel_can
    mov ax, [fuel_can_y]
    mov [fuel_can_y_old], ax
    mov ax, [fuel_can_x]
    mov [fuel_can_x_old], ax
   
    mov ax, [fuel_can_y]
    add ax, 4
    mov [fuel_can_y], ax
   
    ; Check fuel can collection
    call check_fuel_can_collection
   
    ; Reset if off-screen
    cmp ax, 200
    jb fuel_can_onscreen
    mov word [fuel_can_active], 0
    mov word [fuel_can_y], -50
    jmp skip_fuel_can_update
   
fuel_can_onscreen:

    ; Check if the can was collected inside check_fuel_can_collection
    cmp word [fuel_can_active], 0  
    je skip_fuel_can_update        ; If collected (0), DO NOT DRAW. Skip immediately.

    call draw_fuel_can
   
skip_fuel_can_update:

    mov ax, [lane_offset]
    add ax, 9
    cmp ax, 75
    jl no_wrap
    sub ax, 75
no_wrap:
    mov [lane_offset], ax
   
    ; --- FUEL LOGIC START ---
    inc word [fuel_timer]
    cmp word [fuel_timer], 5     ; Speed of fuel decrease
    jl skip_fuel_update
    mov word [fuel_timer], 0
    dec word [fuel_val]
    cmp word [fuel_val], 0
    jle fuel_ran_out
    call draw_fuel_bar
    jmp skip_fuel_update

fuel_ran_out:
    jmp show_fuel_out_screen     ; JUMP TO FUEL SCREEN

skip_fuel_update:
    ; --- FUEL LOGIC END ---

    jmp animation_loop

game_over_collision:
    call draw_collision_spark
    mov cx, 0x000F
    mov dx, 0x4240
    mov ah, 86h
    int 15h
    jmp show_crash_screen

paused_game:
    call handle_pause_input
    jmp animation_loop

exit_game:
    jmp show_quit_screen

; ==================================================================
;  CRASH SCREEN (Collision)
; ==================================================================
show_crash_screen:
    mov ax, 0013h
    int 10h

    ; Load Crash Palette
    mov ah, 3Dh
    mov al, 0
    mov dx, file_cr_pal
    int 21h
    jc quit_direct_dos_jump3
    mov bx, ax
    mov ah, 3Fh
    mov cx, 768
    mov dx, pal_buffer
    int 21h
    mov ah, 3Eh
    int 21h
    mov dx, 03C8h
    xor al, al
    out dx, al
    mov dx, 03C9h
    mov si, pal_buffer
    mov cx, 768
out_cr_pal_loop:
    mov al, [si]
    out dx, al
    inc si
    loop out_cr_pal_loop

    ; Load Crash Pixels
    mov ah, 3Dh
    mov al, 0
    mov dx, file_cr_pix
    int 21h
    jc quit_direct_dos_jump3
    mov bx, ax
    push ds
    mov ax, 0A000h
    mov ds, ax
    xor dx, dx
    mov cx, 64000
    mov ah, 3Fh
    int 21h
    pop ds
    mov ah, 3Eh
    int 21h

wait_crash_input:
    mov ah, 0
    int 16h
    cmp ah, 01h     ; ESC -> EXIT
    je quit_direct_dos_jump3
   
    cmp al, 'r'     ; R -> Results
    je show_results_screen_jump
    cmp al, 'R'     ; R -> Results
    je show_results_screen_jump
    jmp wait_crash_input

quit_direct_dos_jump3:
    jmp quit_direct_dos

show_results_screen_jump:
    jmp show_results_screen

; ==================================================================
; FUEL OUT SCREEN
; ==================================================================
show_fuel_out_screen:
    mov ax, 0013h
    int 10h

    ; Load Fuel Palette
    mov ah, 3Dh
    mov al, 0
    mov dx, file_fu_pal
    int 21h
    jc quit_direct_dos_jump3
    mov bx, ax
    mov ah, 3Fh
    mov cx, 768
    mov dx, pal_buffer
    int 21h
    mov ah, 3Eh
    int 21h
    mov dx, 03C8h
    xor al, al
    out dx, al
    mov dx, 03C9h
    mov si, pal_buffer
    mov cx, 768
out_fu_pal_loop:
    mov al, [si]
    out dx, al
    inc si
    loop out_fu_pal_loop

    ; Load Fuel Pixels
    mov ah, 3Dh
    mov al, 0
    mov dx, file_fu_pix
    int 21h
    jc quit_direct_dos_jump3
    mov bx, ax
    push ds
    mov ax, 0A000h
    mov ds, ax
    xor dx, dx
    mov cx, 64000
    mov ah, 3Fh
    int 21h
    pop ds
    mov ah, 3Eh
    int 21h

wait_fu_input:
    mov ah, 0
    int 16h
    cmp ah, 0x01
    je quit_direct_dos_jump3
   
    cmp al, 'r'
    je show_results_screen_jump
    cmp al, 'R'
    je show_results_screen_jump
    jmp wait_fu_input

; ==================================================================
;  RESULTS SCREEN (Loaded via 'R')
; ==================================================================
show_results_screen:
    mov ax, 0013h
    int 10h

    ; Load Results Palette (repal.bin)
    mov ah, 3Dh
    mov al, 0
    mov dx, file_re_pal
    int 21h
    jc quit_direct_dos_jump3
    mov bx, ax
    mov ah, 3Fh
    mov cx, 768
    mov dx, pal_buffer
    int 21h
    mov ah, 3Eh
    int 21h
    mov dx, 03C8h
    xor al, al
    out dx, al
    mov dx, 03C9h
    mov si, pal_buffer
    mov cx, 768
out_re_pal_loop:
    mov al, [si]
    out dx, al
    inc si
    loop out_re_pal_loop

    ; Load Results Pixels (repixels.bin)
    mov ah, 3Dh
    mov al, 0
    mov dx, file_re_pix
    int 21h
    jc quit_direct_dos_jump3
    mov bx, ax
    push ds
    mov ax, 0A000h
    mov ds, ax
    xor dx, dx
    mov cx, 64000
    mov ah, 3Fh
    int 21h
    pop ds
    mov ah, 3Eh
    int 21h

    ; -------------------------------------------------------
    ; DISPLAY PLAYER DATA ON RESULTS SCREEN
    ; -------------------------------------------------------
    push cs
    pop es          ; Ensure ES is correct for string printing

    ; 1. Print "NAME:" Label
    mov ah, 02h     ; Set Cursor
    mov bh, 00h
    mov dh, 9      ; Row
    mov dl, 17      ; Column
    int 10h
   

    ; Print Actual Name
    mov si, player_name
    call print_string_bios

    ; 2. Print "ROLL NO:" Label
    mov ah, 02h     ; Set Cursor
    mov bh, 00h
    mov dh, 12      ; Row
    mov dl, 22      ; Column
    int 10h


    ; Print Actual Roll Number
    mov si, player_roll
    call print_string_bios

    ; 3. Print "SCORE:" Label
    mov ah, 02h     ; Set Cursor
    mov bh, 00h
    mov dh, 15      ; Row
    mov dl, 21      ; Column
    int 10h


    ; Print Actual Score
    mov ax, [score]
    call display_number
    ; -------------------------------------------------------

wait_re_input:
    mov ah, 0
    int 16h
    cmp ah, 01h     ; ESC -> EXIT
    je quit_direct_dos_jump3
    cmp al, 20h     ; Spacebar -> RESTART
    je restart_results_jump
    jmp wait_re_input

restart_results_jump:
    call remove_music_interrupt
    jmp section_1_9_start

; ==================================================================
; QUIT SCREEN (Manual Quit)
; ==================================================================
show_quit_screen:
    mov ax, 0013h
    int 10h

    ; Load Quit Palette
    mov ah, 3Dh
    mov al, 0
    mov dx, file_qu_pal
    int 21h
    jc quit_direct_dos_jump3
    mov bx, ax
    mov ah, 3Fh
    mov cx, 768
    mov dx, pal_buffer
    int 21h
    mov ah, 3Eh
    int 21h
    mov dx, 03C8h
    xor al, al
    out dx, al
    mov dx, 03C9h
    mov si, pal_buffer
    mov cx, 768
out_qu_pal_loop:
    mov al, [si]
    out dx, al
    inc si
    loop out_qu_pal_loop

    ; Load Quit Pixels
    mov ah, 3Dh
    mov al, 0
    mov dx, file_qu_pix
    int 21h
    jc quit_direct_dos_jump3
    mov bx, ax
    push ds
    mov ax, 0A000h
    mov ds, ax
    xor dx, dx
    mov cx, 64000
    mov ah, 3Fh
    int 21h
    pop ds
    mov ah, 3Eh
    int 21h

wait_quit_input:
    mov ah, 0
    int 16h
    cmp ah, 01h     ; ESC -> DOS
    je quit_direct_dos_jump3
    cmp al, 20h     ; Space -> Restart (Story)
    je jmp_sec_1_9
    jmp wait_quit_input

jmp_sec_1_9:
    call remove_music_interrupt
    jmp section_1_9_start

; ==================================================================
; DRAWING & HELPER FUNCTIONS
; ==================================================================

; --- Collision Check ---
check_collision:
    push ax
    push bx
    push cx
    push dx
    mov word [collision_flag], 0
    mov ax, [car_x]
    mov bx, [blue_car_x]
    sub ax, bx
    cmp ax, 0
    jge check_x_pos
    neg ax
check_x_pos:
    cmp ax, 24
    jg no_collision
    mov ax, [car_y]
    mov bx, [blue_car_y]
    sub ax, bx
    cmp ax, 0
    jge check_y_pos
    neg ax
check_y_pos:
    cmp ax, 40
    jg no_collision
    mov word [collision_flag], 1
no_collision:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; --- Lane Collision Check (For Movement) ---
check_lane_collision:
    push bx
    push cx
    push dx
    mov word [collision_flag], 0
    cmp ax, 1
    je lane_check_1
    cmp ax, 2
    je lane_check_2
    mov dx, [LANE_3_X]
    jmp check_lane_x
lane_check_1:
    mov dx, [LANE_1_X]
    jmp check_lane_x
lane_check_2:
    mov dx, [LANE_2_X]
check_lane_x:
    mov bx, [blue_car_x]
    sub bx, dx
    cmp bx, 0
    jge abs_lane_x
    neg bx
abs_lane_x:
    cmp bx, 10
    jg no_lane_collision
    mov ax, [car_y]
    mov bx, [blue_car_y]
    sub ax, bx
    cmp ax, 0
    jge check_lane_y_pos
    neg ax
check_lane_y_pos:
    cmp ax, 45
    jg no_lane_collision
    mov word [collision_flag], 1
no_lane_collision:
    pop dx
    pop cx
    pop bx
    ret

; --- Coin Collection Check ---
check_coin_collection:
    push ax
    push bx
    push cx
   
    mov ax, [car_x]
    mov bx, [coin_x]
    sub ax, bx
    cmp ax, 0
    jge check_coin_x_pos
    neg ax
check_coin_x_pos:
    cmp ax, 23
    jg no_coin_collect
   
    mov ax, [car_y]
    add ax, 20
    mov bx, [coin_y]
    sub ax, bx
    cmp ax, 0
    jge check_coin_y_pos
    neg ax
check_coin_y_pos:
    cmp ax, 28
    jg no_coin_collect

    ; --- COLLISION DETECTED ---
    inc word [score]
    call draw_score

    ; FIX: Don't spawn at Y=10 immediately.
    ; Send it off-screen (Y=215). The main loop's safety logic
    ; will check the Blue Car position and reset this coin
    ; only when it is safe to do so.
    mov word [coin_y], 215  
   
    ; We don't need to set X or random lane here anymore,
    ; the main loop handles that when it resets Y to 10.

no_coin_collect:
    pop cx
    pop bx
    pop ax
    ret

check_fuel_can_collection:
    push ax
    push bx
    push cx
    push dx

    ; 1. Check Y intersection (Vertical Distance)
    mov ax, [car_y]
   
    ; FIX: Add offset to check from the CENTER of the car, not the top.
    ; This delays collection until the fuel is actually overlapping.
    add ax, 15          
   
    mov bx, [fuel_can_y]
    sub ax, bx
   
    ; Get Absolute Value of Y Difference
    cmp ax, 0
    jge f_abs_y
    neg ax
f_abs_y:
    ; FIX: Reduced Radius to 25.
    ; Combined with the offset above, this ensures solid overlap
    ; at both the Top AND Bottom of the car.
    cmp ax, 25      
    jg no_fuel_collection

    ; 2. Check X intersection (Horizontal Distance)
    mov ax, [car_x]
    mov bx, [fuel_can_x]
    sub ax, bx
   
    ; Get Absolute Value of X Difference
    cmp ax, 0
    jge f_abs_x
    neg ax
f_abs_x:
    cmp ax, 25       ; Width Collision Threshold
    jg no_fuel_collection

    ; --- COLLISION DETECTED ---
   
    ; Erase the can visually
    call erase_fuel_can

    ; B. Deactivate Fuel Can Logic
    mov word [fuel_can_active], 0
    mov word [fuel_can_y], -50   ; Move off-screen
    mov word [fuel_spawn_counter], 0 ; Reset spawn timer

    ; C. Increase Fuel Amount
    add word [fuel_val], 10      ; Add 10 units of fuel
    cmp word [fuel_val], 40      ; Check max fuel limit
    jle f_not_full
    mov word [fuel_val], 40      ; Cap at max
f_not_full:
   
    ; D. Update UI
    call draw_fuel_bar           ; Update the fuel bar on screen
   
    ; Redraw car to ensure no parts were clipped
    call draw_car

no_fuel_collection:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; --- DRAW_FUEL_CAN ROUTINE (Box with Handle & Black Nozzle) ---
draw_fuel_can:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, [fuel_can_y]
    mov di, [fuel_can_x]
    sub di, 8              ; Center the can (16 pixels wide)
   
    mov cx, 18             ; Total Height (rows)

draw_can_loop:
    ; Clip Top/Bottom
    cmp si, 200
    jge skip_can_row_draw
    cmp si, 0
    jl skip_can_row_draw

    mov bx, si
    imul bx, 320
    add bx, di             ; ES:BX = Start of row

    ; Logic: Top 5 rows = Handle/Nozzle. Bottom 13 rows = Red Box.
    cmp cx, 14
    jg draw_handle_section
    jmp draw_body_section

draw_handle_section:
    ; -- Handle & Nozzle (Top Rows) --
   
    ; Top of Handle (Row 18)
    cmp cx, 18
    je draw_handle_top

    ; Handle Sides (Red vertical bars)
    mov byte [es:bx+4], 4  ; Red Left
    mov byte [es:bx+5], 4
    mov byte [es:bx+10], 4 ; Red Right
    mov byte [es:bx+11], 4
   
    ; Black Nozzle (Sticking out right)
    mov byte [es:bx+12], 0
    mov byte [es:bx+13], 0
    mov byte [es:bx+14], 0
   
    jmp skip_can_row_draw

draw_handle_top:
    ; Solid Red Top Bar for Handle
    mov dx, 8
    lea bp, [bx+4]
fill_handle_top:
    mov byte [es:bp], 4
    inc bp
    dec dx
    jnz fill_handle_top
    jmp skip_can_row_draw

draw_body_section:
    ; -- Main Box Body (Bottom Rows) --
   
    ; Black Outline (Left/Right)
    mov byte [es:bx+2], 0
    mov byte [es:bx+13], 0
   
    ; Red Fill Center
    mov dx, 10
    lea bp, [bx+3]
fill_can_body:
    mov byte [es:bp], 4
    inc bp
    dec dx
    jnz fill_can_body

skip_can_row_draw:
    inc si
    dec cx
    jnz draw_can_loop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



erase_fuel_can:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; 1. BLIND ERASE (Clears the can, fixes the trail issue)
    mov si, [fuel_can_y]
    mov di, [fuel_can_x]
    sub di, 8               ; Match draw offset

    mov cx, 18              ; Height
    mov al, 8               ; Road Color (Gray)

erase_can_loop_simple:
    cmp si, 200
    jge erase_can_next
    cmp si, 0
    jl erase_can_next

    mov bx, si
    imul bx, 320
    add bx, di

    mov dx, 16              ; Width
erase_pixels_simple:
    mov [es:bx], al         ; Force paint gray
    inc bx
    dec dx
    jnz erase_pixels_simple

erase_can_next:
    inc si
    dec cx
    jnz erase_can_loop_simple

    ; 2. REPAIR CAR (Fixes the "eating car" issue)
    ; Check if the Fuel Can is close to the Car.
    ; If it is, we redraw the car immediately to patch any holes.
   
    ; Check Y Distance
    mov ax, [car_y]
    sub ax, [fuel_can_y]
   
    ; Absolute value of Y diff
    cmp ax, 0
    jge abs_diff_y
    neg ax
abs_diff_y:
    cmp ax, 50              ; If Y distance < 50 pixels
    jg skip_car_repair      ; Too far away, no need to repair

    ; Check X Distance (Optimization)
    mov ax, [car_x]
    sub ax, [fuel_can_x]
   
    ; Absolute value of X diff
    cmp ax, 0
    jge abs_diff_x
    neg ax
abs_diff_x:
    cmp ax, 40              ; If X distance < 40 pixels
    jg skip_car_repair      ; Different lane, no need to repair

    ; If we are here, the Fuel Can is touching/near the Car.
    ; Redraw the car to ensure it looks solid.
    call draw_car

skip_car_repair:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
; --- Draw Score ---
draw_score:
    push ax
    push bx
    push cx
    push dx
    push bp
    push es
    push ds
    mov ah, 02h
    mov bh, 00h
    mov dh, 21
    mov dl, 0
    int 10h
    push cs
    pop es
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 14
    mov cx, 6
    mov bp, score_msg_label
    int 0x10
    mov ah, 02h
    mov bh, 00h
    mov dh, 22
    mov dl, 2
    int 10h
    mov ax, [score]
    call display_number
    pop ds
    pop es
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

display_number:
    push ax
    push bx
    push cx
    push dx
    mov bx, 10
    xor cx, cx
convert_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne convert_loop
print_digits:
    pop dx
    add dl, '0'
    mov ah, 0Eh
    mov al, dl
    mov bl, 15
    int 10h
    loop print_digits
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; --- Draw Explosion Spark ---
draw_collision_spark:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov ax, [car_x]
    add ax, [blue_car_x]
    shr ax, 1
    add ax,11
    mov di, ax
    mov ax, [car_y]
    add ax, [blue_car_y]
    shr ax, 1
    add ax,8
    mov si, ax
    mov cx, -4
core_y_loop:
    mov dx, -4
core_x_loop:
    mov bx, si
    add bx, cx
    cmp bx, 0
    jl skip_core
    cmp bx, 200
    jge skip_core
    imul bx, 320
    push ax
    mov ax, di
    add ax, dx
    add bx, ax
    pop ax
    mov byte [es:bx], 14
skip_core:
    inc dx
    cmp dx, 5
    jl core_x_loop
    inc cx
    cmp cx, 5
    jl core_y_loop
    mov cx, -6
middle_y_loop:
    mov dx, -6
middle_x_loop:
    mov bx, si
    add bx, cx
    cmp bx, 0
    jl skip_middle
    cmp bx, 200
    jge skip_middle
    imul bx, 320
    push ax
    mov ax, di
    add ax, dx
    add bx, ax
    pop ax
    push cx
    push dx
    mov ax, cx
    cmp ax, 0
    jge abs_cy
    neg ax
abs_cy:
    cmp ax, 4
    jg draw_middle
    mov ax, dx
    cmp ax, 0
    jge abs_cx
    neg ax
abs_cx:
    cmp ax, 4
    jle skip_middle_pixel
draw_middle:
    mov byte [es:bx], 12
skip_middle_pixel:
    pop dx
    pop cx
skip_middle:
    inc dx
    cmp dx, 7
    jl middle_x_loop
    inc cx
    cmp cx, 7
    jl middle_y_loop
    mov cx, 7
up_spike:
    mov bx, si
    sub bx, cx
    cmp bx, 0
    jl skip_up
    imul bx, 320
    add bx, di
    mov byte [es:bx], 4
    cmp cx, 7
    jne up_thin
    mov byte [es:bx-1], 4
    mov byte [es:bx+1], 4
up_thin:
skip_up:
    inc cx
    cmp cx, 12
    jl up_spike
    mov cx, 7
down_spike:
    mov bx, si
    add bx, cx
    cmp bx, 200
    jge skip_down
    imul bx, 320
    add bx, di
    mov byte [es:bx], 4
    cmp cx, 7
    jne down_thin
    mov byte [es:bx-1], 4
    mov byte [es:bx+1], 4
down_thin:
skip_down:
    inc cx
    cmp cx, 12
    jl down_spike
    mov cx, 7
left_spike:
    mov bx, si
    imul bx, 320
    add bx, di
    sub bx, cx
    mov byte [es:bx], 4
    cmp cx, 7
    jne left_thin
    mov byte [es:bx-320], 4
    mov byte [es:bx+320], 4
left_thin:
    inc cx
    cmp cx, 12
    jl left_spike
    mov cx, 7
right_spike:
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, cx
    mov byte [es:bx], 4
    cmp cx, 7
    jne right_thin
    mov byte [es:bx-320], 4
    mov byte [es:bx+320], 4
right_thin:
    inc cx
    cmp cx, 12
    jl right_spike
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; --- Input Functions ---
get_input_string:
    push ax
    push bx
    push di
    mov bx, di
input_loop:
    mov ah, 0
    int 16h
    cmp ah, 01h
    je input_esc_pressed
    cmp al, 0Dh
    je input_done
    cmp al, 08h
    je handle_backspace
    stosb
    push bx
    mov ah, 0Eh
    mov bl, 15
    int 10h
    pop bx
    jmp input_loop
handle_backspace:
    cmp di, bx
    je input_loop
    dec di
    push bx
    mov ah, 0Eh
    mov al, 08h
    int 10h
    mov al, ' '
    int 10h
    mov al, 08h
    int 10h
    pop bx
    jmp input_loop
input_esc_pressed:
    mov ax, 0xA000
    mov es, ax
    call draw_confirmation_box
input_wait_response:
    mov ah, 0
    int 16h
    cmp al, 'y'
    je quit_direct_dos_jump2
    cmp al, 'Y'
    je quit_direct_dos_jump2
    cmp al, 'n'
    je input_resume
    cmp al, 'N'
    je input_resume
    cmp ah, 01h
    je input_resume
    jmp input_wait_response
input_resume:
    call erase_confirmation_box
    jmp input_loop
input_done:
    mov al, 0
    stosb
    pop di
    pop bx
    pop ax
    ret
quit_direct_dos_jump2:
    jmp quit_direct_dos

print_string_bios:
    push ax
    push bx
    push si
    mov bl, 9
print_loop_bios:
    lodsb
    cmp al, 0
    je print_done_bios
    mov ah, 0Eh
    int 10h
    jmp print_loop_bios
print_done_bios:
    pop si
    pop bx
    pop ax
    ret



erase_blue_car:
    push ax
    push bx
    push cx
    push si
    push di
   
    mov al, 8               ; Road Color (Gray)
    mov si, [blue_car_y_old]
    mov di, [blue_car_x_old]
    sub di, 2
    mov cx, 40              ; Car Height

erase_row:
    push cx
   
    ; --- SAFETY CHECK START ---
    cmp si, 200
    jge erase_skip_row      ; If below screen, skip
    cmp si, 0
    jl erase_skip_row       ; If above screen (Negative), SKIP!
    ; --- SAFETY CHECK END ---
   
    mov bx, si
    imul bx, 320
    add bx, di
   
    mov cx, 28              ; Car Width
erase_col:
    mov [es:bx], al         ; Paint Gray
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


; Checks if the pixel is part of the CAR (Red, Black, White) before erasing.
; If it is a car pixel, we leave it alone. Otherwise, paint it grey (Road).
erase_coin:
    push ax
    push bx
    push cx
    push si
    push di
   
    mov al, 8           ; Road Color
    mov si, [coin_y_old]
    mov di, [coin_x_old]
    sub di, 4
    mov cx, 10          ; Height of coin area
   
coin_erase_row:
    push cx
    cmp si, 200
    jge coin_erase_skip_row
   
    mov bx, si
    imul bx, 320
    add bx, di
   
    mov cx, 8           ; Width of coin area
coin_erase_col:
    ; --- SMART CHECK START ---
    ; Read the pixel currently on screen
    mov ah, [es:bx]    
   
    ; 1. Check Red Car body (Color 4)
    cmp ah, 4          
    je skip_erase_pixel
   
    ; 2. Check Red Car shading (Color 12)
    cmp ah, 12          
    je skip_erase_pixel

    ; 3. Check Black details/Tires (Color 0)
    cmp ah, 0
    je skip_erase_pixel

    ; 4. Check White lights/Windshield (Color 15)
    cmp ah, 15
    je skip_erase_pixel

    ; If it's none of the above, it's safe to erase (paint road color)
    mov [es:bx], al    
   
skip_erase_pixel:
    ; --- SMART CHECK END ---
   
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
erase_red_car:
    push ax
    push bx
    push cx
    push si
    push di
    mov al, 8      ; ROAD_COLOR
    mov si, [car_y_old]
    mov di, [car_x_old]
    sub di, 2
    mov cx, 40
erase_red_row:
    push cx
    cmp si, 200
    jge erase_red_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov cx, 28
erase_red_col:
    mov [es:bx], al
    inc bx
    loop erase_red_col
erase_red_skip:
    inc si
    pop cx
    loop erase_red_row
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

handle_input:
    push ax
    push bx
check_key_loop:
    mov ah, 01h
    int 16h
    jz hi_exit
    mov ah, 00h
    int 16h
    cmp ah, 01h
    je hi_pause_game
    cmp al, 0
    je process_key
    cmp al, 0E0h
    je process_key
    jmp hi_ignore
process_key:
    cmp ah, 75
    je hi_left
    cmp ah, 77
    je hi_right
    cmp ah, 72
    je hi_up
    cmp ah, 80
    je hi_down
hi_ignore:
    jmp check_key_loop
hi_left:
    call move_car_left
    jmp check_key_loop
hi_right:
    call move_car_right
    jmp check_key_loop
hi_up:
    call move_car_up
    jmp check_key_loop
hi_down:
    call move_car_down
    jmp check_key_loop
hi_pause_game:
    mov word [game_state], 2
    call draw_confirmation_box
    jmp hi_exit
hi_exit:
    pop bx
    pop ax
    ret

move_car_left:
    push ax
    push bx
    cmp word [car_lane], 1
    je mcl_exit
    mov ax, [car_lane]
    dec ax
    call check_lane_collision
    cmp word [collision_flag], 1
    je mcl_collision_detected
    mov ax, [car_x]
    mov [car_x_old], ax
    mov ax, [car_y]
    mov [car_y_old], ax
    dec word [car_lane]
    mov bx, [car_lane]
    cmp bx, 1
    je mcl_lane1
    cmp bx, 2
    je mcl_lane2
    jmp mcl_exit
mcl_lane1:
    mov ax, [LANE_1_X]
    jmp mcl_update
mcl_lane2:
    mov ax, [LANE_2_X]
    jmp mcl_update
mcl_update:
    mov [car_x], ax
    call erase_red_car
    call draw_car
mcl_exit:
    pop bx
    pop ax
    ret
mcl_collision_detected:
    call draw_collision_spark
    mov cx, 0x000F
    mov dx, 0x4240
    mov ah, 86h
    int 15h
    jmp show_crash_screen

move_car_right:
    push ax
    push bx
    cmp word [car_lane], 3
    je mcr_exit
    mov ax, [car_lane]
    inc ax
    call check_lane_collision
    cmp word [collision_flag], 1
    je mcr_collision_detected
    mov ax, [car_x]
    mov [car_x_old], ax
    mov ax, [car_y]
    mov [car_y_old], ax
    inc word [car_lane]
    mov bx, [car_lane]
    cmp bx, 2
    je mcr_lane2
    cmp bx, 3
    je mcr_lane3
    jmp mcr_exit
mcr_lane2:
    mov ax, [LANE_2_X]
    jmp mcr_update
mcr_lane3:
    mov ax, [LANE_3_X]
    jmp mcr_update
mcr_update:
    mov [car_x], ax
    call erase_red_car
    call draw_car
mcr_exit:
    pop bx
    pop ax
    ret
mcr_collision_detected:
    call draw_collision_spark
    mov cx, 0x000F
    mov dx, 0x4240
    mov ah, 86h
    int 15h
    jmp show_crash_screen

move_car_up:
    push ax
    push cx
    push bx
    mov ax, [car_x]
    mov [car_x_old], ax
    mov ax, [car_y]
    mov [car_y_old], ax
    mov ax, [car_y]
    sub ax, [Y_STEP]
    cmp ax, 0
    jl mcu_clip_or_exit
    mov [car_y], ax
    call erase_red_car
    call draw_car
    jmp mcu_exit
mcu_clip_or_exit:
    mov bx, [car_y]
    cmp bx, 0
    je mcu_exit
    mov ax, 0
    mov [car_y], ax
    call erase_red_car
    call draw_car
mcu_exit:
    pop bx
    pop cx
    pop ax
    ret

move_car_down:
    push ax
    push cx
    push bx
    mov ax, [car_x]
    mov [car_x_old], ax
    mov ax, [car_y]
    mov [car_y_old], ax
    mov ax, [car_y]
    mov bx, [CAR_HEIGHT]
    add ax, bx
    cmp ax, [SCREEN_BOTTOM]
    jge mcd_exit
    mov ax, [car_y]
    add ax, [Y_STEP]
    mov [car_y], ax
    call erase_red_car
    call draw_car
mcd_exit:
    pop bx
    pop cx
    pop ax
    ret

handle_pause_input:
    push ax
   
    ; Silence speaker while paused
    in al, 61h
    and al, 0FCh
    out 61h, al
   
    mov ah, 0
    int 16h
    cmp ah, 01h
    je hpi_resume
    cmp al, 'y'
    je hpi_quit
    cmp al, 'Y'
    je hpi_quit
    cmp al, 'n'
    je hpi_resume
    cmp al, 'N'
    je hpi_resume
    jmp hpi_exit
hpi_resume:
    call erase_confirmation_box
    mov word [game_state], 1
    jmp hpi_exit
hpi_quit:
    jmp show_quit_screen
hpi_exit:
    pop ax
    ret

draw_confirmation_box:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds
   
    ; Set video segment
    mov ax, 0xA000
    mov es, ax
   
    ; Save current video memory to buffer
    push cs
    pop ds
   
    mov si, [PAUSE_BOX_Y]
    mov di, 0                     ; Buffer offset
   
save_vram_outer:
    mov cx, [PAUSE_BOX_H]
    mov dx, 0                     ; Row counter
   
save_vram_row:
    cmp dx, cx                    ; Check if done with all rows
    jge save_done
   
    mov bx, si
    imul bx, 320
    add bx, [PAUSE_BOX_X]
   
    push cx
    mov cx, [PAUSE_BOX_W]
   
save_vram_col:
    mov al, byte [es:bx]
    mov byte [pause_buffer+di], al
    inc bx
    inc di
    loop save_vram_col
   
    pop cx
    inc si
    inc dx
    jmp save_vram_row
   
save_done:
    ; Draw solid background fill first
    mov si, [PAUSE_BOX_Y]
    mov dx, [PAUSE_BOX_H]
   
fill_background:
    cmp dx, 0
    jle background_done
   
    mov bx, si
    imul bx, 320
    add bx, [PAUSE_BOX_X]
   
    mov cx, [PAUSE_BOX_W]
fill_bg_row:
    mov byte [es:bx], 1            ; Dark blue background
    inc bx
    loop fill_bg_row
   
    inc si
    dec dx
    jmp fill_background
   
background_done:
    ; Draw outer border (3 pixels thick)
    mov si, [PAUSE_BOX_Y]
    mov dx, [PAUSE_BOX_H]
   
draw_outer_border:
    cmp dx, 0
    jle outer_border_done
   
    mov bx, si
    imul bx, 320
    add bx, [PAUSE_BOX_X]
   
    ; Check if this is in top 3 or bottom 3 rows
    mov ax, si
    sub ax, [PAUSE_BOX_Y]
    cmp ax, 3
    jl draw_full_border
   
    mov ax, [PAUSE_BOX_H]
    sub ax, 3
    mov cx, si
    sub cx, [PAUSE_BOX_Y]
    cmp cx, ax
    jge draw_full_border
   
    ; Middle section - draw left and right borders (3 pixels each)
    mov cx, 3
draw_left_border:
    mov byte [es:bx], 0
    inc bx
    loop draw_left_border
   
    add bx, [PAUSE_BOX_W]
    sub bx, 6
    mov cx, 3
draw_right_border:
    mov byte [es:bx], 0
    inc bx
    loop draw_right_border
   
    jmp next_outer_row
   
draw_full_border:
    mov cx, [PAUSE_BOX_W]
draw_border_row:
    mov byte [es:bx], 0
    inc bx
    loop draw_border_row
   
next_outer_row:
    inc si
    dec dx
    jmp draw_outer_border
   
outer_border_done:
    ; Draw inner decorative border
    mov si, [PAUSE_BOX_Y]
    add si, 5
    mov dx, [PAUSE_BOX_H]
    sub dx, 10
   
draw_inner_border:
    cmp dx, 0
    jle inner_done
   
    mov bx, si
    imul bx, 320
    add bx, [PAUSE_BOX_X]
    add bx, 5
   
    ; Check if top or bottom of inner border
    mov ax, [PAUSE_BOX_Y]
    add ax, 5
    cmp si, ax
    je draw_inner_full
   
    mov ax, [PAUSE_BOX_Y]
    add ax, [PAUSE_BOX_H]
    sub ax, 6
    cmp si, ax
    je draw_inner_full
   
    ; Just left and right pixels
    mov byte [es:bx], 15            ; White
    add bx, [PAUSE_BOX_W]
    sub bx, 11
    mov byte [es:bx], 15
    jmp next_inner_row
   
draw_inner_full:
    mov cx, [PAUSE_BOX_W]
    sub cx, 10
draw_inner_row:
    mov byte [es:bx], 15            ; White
    inc bx
    loop draw_inner_row
   
next_inner_row:
    inc si
    dec dx
    jmp draw_inner_border
   
inner_done:
    ; Draw text lines using BIOS
 
   
    ; Line 1: "GAME PAUSED"
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 14                     ; Yellow
    mov cx, 11                     ; Length of "GAME PAUSED"
    mov dh, 9                      ; Row (centered vertically)
    mov dl, 14                     ; Column (centered horizontally)
    push cs
    pop es
    mov bp, pause_line1
    int 0x10
   
    ; Line 2: "QUIT? (Y/N)"
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 15                     ; White
    mov cx, 11                     ; Length of "QUIT? (Y/N)"
    mov dh, 11                     ; Row
    mov dl, 14                     ; Column
    push cs
    pop es
    mov bp, pause_line2
    int 0x10

    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
erase_confirmation_box:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds
   
    ; Set video segment
    mov ax, 0xA000
    mov es, ax
   
    ; Set data segment
    push cs
    pop ds
   
    mov si, [PAUSE_BOX_Y]
    mov di, 0                      ; Buffer offset
   
restore_vram_outer:
    mov dx, 0                      ; Row counter
   
restore_vram_row:
    mov cx, [PAUSE_BOX_H]
    cmp dx, cx                     ; Check if done with all rows
    jge restore_done
   
    mov bx, si
    imul bx, 320
    add bx, [PAUSE_BOX_X]
   
    push cx
    mov cx, [PAUSE_BOX_W]
   
restore_vram_col:
    mov al, byte [pause_buffer+di]
    mov byte [es:bx], al
    inc bx
    inc di
    loop restore_vram_col
   
    pop cx
    inc si
    inc dx
    jmp restore_vram_row
   
restore_done:
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_static_background:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    xor si, si
bg_row:
    xor di, di
    mov bx, si
    imul bx, 320
bg_col:
    mov al, 8
    cmp di, 50
    jl bg_set_black_border
    cmp di, 270
    jge bg_set_black_border
    cmp di, 79
    je bg_set_black
    cmp di, 80
    je bg_set_black
    cmp di, 240
    je bg_set_black
    cmp di, 241
    je bg_set_black
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
    cmp di, 80
    jb bg_set_grass
    cmp di, 240
    ja bg_set_grass
    jmp bg_write_pixel
bg_set_black_border:
    mov al, 0
    jmp bg_write_pixel
bg_set_black:
    mov al, 0
    jmp bg_write_pixel
bg_set_grass:
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
    mov al, 15
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

draw_scrolling_grass:
    push ax
    push bx
    push cx
    push si
    push di
    xor si, si
grass_row_loop:
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
    mov al, 2
    shr cx, 3
    test cx, 1
    jz draw_grass_cols
    mov al, 10
draw_grass_cols:
    mov bx, si
    imul bx, 320
    mov di, 50
draw_left_grass:
    mov [es:bx+di], al
    inc di
    cmp di, 79
    jl draw_left_grass
    mov di, 242
draw_right_grass:
    mov [es:bx+di], al
    inc di
    cmp di, 270
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
    xor si, si
lane_row:
    mov cx, si
    sub cx, [lane_offset]
check_pattern:
    cmp cx, 0
    jge check_pattern_pos
    add cx, 75
    jmp check_pattern
check_pattern_pos:
    cmp cx, 75
    jl check_in_segment
    sub cx, 75
    jmp check_pattern
check_in_segment:
    cmp cx, 50
    jge skip_lane_draw
    mov bx, si
    imul bx, 320
    mov di, 128
draw_left_marker:
    mov byte [es:bx+di], 15
    inc di
    cmp di, 133
    jl draw_left_marker
    mov di, 188
draw_right_marker:
    mov byte [es:bx+di], 15
    inc di
    cmp di, 193
    jl draw_right_marker
    jmp lane_continue
skip_lane_draw:
    mov bx, si
    imul bx, 320
    mov di, 128
erase_left_marker:
    mov byte [es:bx+di], 8
    inc di
    cmp di, 133
    jl erase_left_marker
    mov di, 188
erase_right_marker:
    mov byte [es:bx+di], 8
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

draw_coin:
    push ax
    push bx
    push cx
    push si
    push di
    push bp
    mov si, [coin_y]
    mov di, [coin_x]
    sub di, 4
    cmp si, 200
    jge dc1_skip
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2
    mov cx, 4
dc1:
    mov byte [es:bx], 6
    inc bx
    loop dc1
dc1_skip:
    inc si
    mov ax, 2
dc_highlight_body:
    cmp si, 200
    jge dc_hb_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 6
    mov byte [es:bx+1], 14
    mov byte [es:bx+2], 14
    mov byte [es:bx+3], 1
    mov byte [es:bx+4], 14
    mov byte [es:bx+5], 14
    mov byte [es:bx+6], 6
    mov byte [es:bx+7], 6
dc_hb_skip:
    inc si
    dec ax
    jnz dc_highlight_body
    mov ax, 4
dc_main_body:
    cmp si, 200
    jge dc_mb_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 6
    mov byte [es:bx+7], 6
    mov cx, 6
    mov bp, bx
    add bp, 1
dc_fill_loop:
    mov byte [es:bp], 14
    inc bp
    loop dc_fill_loop
    mov byte [es:bx+3], 1
dc_mb_skip:
    inc si
    dec ax
    jnz dc_main_body
    mov ax, 2
dc_shade_body:
    cmp si, 200
    jge dc_sb_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 6
    mov byte [es:bx+7], 6
    mov cx, 6
    mov bp, bx
    add bp, 1
dc_shade_fill_loop:
    mov byte [es:bp], 6
    inc bp
    loop dc_shade_fill_loop
    mov byte [es:bx+3], 1
dc_sb_skip:
    inc si
    dec ax
    jnz dc_shade_body
    cmp si, 200
    jge dc9_skip
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2
    mov cx, 4
dc9:
    mov byte [es:bx], 6
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

draw_fuel_text:
    push ax
    push bp
    push cx
    push dx
    push es
    push ds
    pop es
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 14
    mov cx, 6
    mov dh, 21
    mov dl, 34
    mov bp, fuel_msg
    int 0x10
    pop es
    pop dx
    pop cx
    pop bp
    pop ax
    ret

; ==================================================================
;  DRAW FUEL BAR
; ==================================================================
draw_fuel_bar:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
   
    ; Define Bar Area (X:190, Y:180, MaxWidth:40, Height:6)
    ; First, draw black background for the whole max width (erase old)
    mov si, 180      ; Y start
    mov dx, 6        ; Height
draw_bar_bg_row:
    mov bx, si
    imul bx, 320
    add bx, 274      ; X start
    mov cx, 40       ; Max width
draw_bar_bg_col:
    mov byte [es:bx], 0 ; Black background
    inc bx
    loop draw_bar_bg_col
    inc si
    dec dx
    jnz draw_bar_bg_row

    ; Second, draw current fuel level
    mov ax, [fuel_val]
    cmp ax, 0
    jle draw_bar_done ; If empty, nothing to draw
   
    mov si, 180
    mov dx, 6
   
; Determine Color
    mov al, 2           ; Default: Green
   
    cmp word [fuel_val], 20
    jg color_selected   ; If > 20 (Above 50%), keep Green
   
    mov al, 14          ; Set Yellow (50% or less)
    cmp word [fuel_val], 10
    jg color_selected   ; If > 10 (Above 25%), keep Yellow
   
    mov al, 4           ; Set Red (25% or less)

color_selected:

draw_bar_fill_row:
    mov bx, si
    imul bx, 320
    add bx, 274
    mov cx, [fuel_val] ; Width = fuel value
draw_bar_fill_col:
    mov byte [es:bx], al
    inc bx
    loop draw_bar_fill_col
    inc si
    dec dx
    jnz draw_bar_fill_row

draw_bar_done:
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
    mov si, [car_y]
    mov di, [car_x]
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
    cmp dx, 200
    jge df1_skip
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
df1:
    mov byte [es:bx], 0
    inc bx
    loop df1
df1_skip:
    inc dx
    cmp dx, 200
    jge df2_skip
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 4
    mov byte [es:bx], 15
    mov byte [es:bx+1], 15
    mov byte [es:bx+14], 15
    mov byte [es:bx+15], 15
    mov cx, 12
df2:
    mov byte [es:bx+2], 4
    inc bx
    loop df2
df2_skip:
    inc dx
    cmp dx, 200
    jge df3_skip
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 2
    mov byte [es:bx], 0
    mov byte [es:bx+1], 4
    mov byte [es:bx+2], 4
    mov byte [es:bx+3], 4
    mov byte [es:bx+16], 4
    mov byte [es:bx+17], 4
    mov byte [es:bx+18], 4
    mov byte [es:bx+19], 0
    mov cx, 12
df3:
    mov byte [es:bx+4], 0
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

draw_hood:
    push ax
    push bx
    push cx
    push dx
    push si
    mov ax, 3
dh1:
    cmp si, 200
    jge dh_skip_row
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 0
    mov byte [es:bx+21], 0
    mov cx, 19
dh2:
    mov byte [es:bx+1], 4
    inc bx
    loop dh2
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 0
    mov byte [es:bx+14], 0
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

draw_windshield_f:
    push ax
    push bx
    push cx
    push dx
    push si
    cmp si, 200
    jge dwf1_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx-2], 0
    mov byte [es:bx-1], 0
    mov byte [es:bx], 0
    mov byte [es:bx+23], 0
    mov byte [es:bx+24], 0
    mov byte [es:bx+25], 0
    mov cx, 22
dwf1:
    mov byte [es:bx+1], 0
    inc bx
    loop dwf1
dwf1_skip:
    inc si
    cmp si, 200
    jge dwf2_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx-1], 0
    mov byte [es:bx+1], 0
    mov byte [es:bx+22], 0
    mov byte [es:bx+23], 0
    mov cx, 20
dwf2:
    mov byte [es:bx+2], 0
    inc bx
    loop dwf2
dwf2_skip:
    inc si
    cmp si, 200
    jge dwf3_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+21], 0
    mov cx, 18
dwf3:
    mov byte [es:bx+3], 0
    inc bx
    loop dwf3
dwf3_skip:
    inc si
    cmp si, 200
    jge dwf4_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+21], 0
    mov cx, 18
dwf4:
    mov byte [es:bx+3], 0
    inc bx
    loop dwf4
dwf4_skip:
    inc si
    cmp si, 200
    jge dwf5_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+21], 0
    mov cx, 18
dwf5:
    mov byte [es:bx+3], 0
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

draw_roof:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 2
    mov ax, si
dr1_:
    cmp si, 200
    jge dr_skip_row
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2
    mov cx, 20
dr2_:
    mov byte [es:bx], 4
    inc bx
    loop dr2_
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+21], 0
dr_skip_row:
    inc si
    dec dx
    jnz dr1_
    cmp ax, 200
    jge dr_skip_sunroof
    mov bx, ax
    imul bx, 320
    add bx, di
    add bx, 8
    mov cx, 8
sunroof_r:
    mov byte [es:bx], 0
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

draw_body:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 10
db1:
    cmp si, 200
    jge db_skip_row
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0
    mov byte [es:bx+23], 0
    add bx, 1
    mov cx, 22
db2:
    mov byte [es:bx], 4
    inc bx
    loop db2
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+5], 15
    mov byte [es:bx+18], 15
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

draw_windshield_r:
    push ax
    push bx
    push cx
    push dx
    push si
    cmp si, 200
    jge dwr1_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+21], 0
    mov cx, 18
dwr1:
    mov byte [es:bx+3], 0
    inc bx
    loop dwr1
dwr1_skip:
    inc si
    cmp si, 200
    jge dwr2_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+21], 0
    mov cx, 18
dwr2:
    mov byte [es:bx+3], 0
    inc bx
    loop dwr2
dwr2_skip:
    inc si
    cmp si, 200
    jge dwr3_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+21], 0
    mov cx, 18
dwr3:
    mov byte [es:bx+3], 0
    inc bx
    loop dwr3
dwr3_skip:
    inc si
    cmp si, 200
    jge dwr4_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0
    mov byte [es:bx+22], 0
    mov cx, 20
dwr4:
    mov byte [es:bx+2], 0
    inc bx
    loop dwr4
dwr4_skip:
    inc si
    cmp si, 200
    jge dwr5_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0
    mov byte [es:bx+23], 0
    mov cx, 22
dwr5:
    mov byte [es:bx+1], 0
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

draw_trunk:
    push ax
    push bx
    push cx
    push dx
    push si
    cmp si, 200
    jge dt1_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0
    mov byte [es:bx+23], 0
    mov cx, 22
dt1:
    mov byte [es:bx+1], 4
    inc bx
    loop dt1
dt1_skip:
    inc si
    cmp si, 200
    jge dt2_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0
    mov byte [es:bx+23], 0
    mov cx, 22
dt2:
    mov byte [es:bx+1], 4
    inc bx
    loop dt2
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 0
    mov byte [es:bx+15], 0
dt2_skip:
    inc si
    cmp si, 200
    jge dt3_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 0
    mov byte [es:bx+23], 0
    mov cx, 22
dt3:
    mov byte [es:bx+1], 4
    inc bx
    loop dt3
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 0
    mov byte [es:bx+15], 0
dt3_skip:
    inc si
    cmp si, 200
    jge dt4_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0
    mov byte [es:bx+22], 0
    mov cx, 20
dt4:
    mov byte [es:bx+2], 4
    inc bx
    loop dt4
dt4_skip:
    inc si
    cmp si, 200
    jge dt5_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+21], 0
    mov cx, 18
dt5:
    mov byte [es:bx+3], 4
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

draw_rear_bumper:
    push ax
    push bx
    push cx
    push dx
    push si
    cmp si, 200
    jge drb1_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+21], 0
    mov cx, 18
drb1:
    mov byte [es:bx+3], 4
    inc bx
    loop drb1
drb1_skip:
    inc si
    cmp si, 200
    jge drb2_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 0
    mov byte [es:bx+3], 4
    mov byte [es:bx+4], 4
    mov byte [es:bx+19], 4
    mov byte [es:bx+20], 4
    mov byte [es:bx+21], 0
    mov cx, 14
drb2:
    mov byte [es:bx+5], 8
    inc bx
    loop drb2
drb2_skip:
    inc si
    cmp si, 200
    jge drb3_skip
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+3], 0
    mov byte [es:bx+20], 0
    mov cx, 16
drb3:
    mov byte [es:bx+4], 8
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

draw_rear_taper:
    push ax
    push bx
    push cx
    push si
    cmp si, 200
    jge drt1_skip
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 4
    mov cx, 16
drt1:
    mov byte [es:bx], 0
    inc bx
    loop drt1
drt1_skip:
    inc si
    cmp si, 200
    jge drt2_skip
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
drt2:
    mov byte [es:bx], 0
    inc bx
    loop drt2
drt2_skip:
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
    mov si, [blue_car_y]
    mov di, [blue_car_x]
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


draw_blue_front:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; --- ROW 1 ---
    mov dx, si
    cmp dx, 200
    jge b_df1_trampoline    ; Jump to trampoline if bottom clipped
    cmp dx, 0
    jl b_df1_trampoline     ; Jump to trampoline if top clipped
   
    ; Draw Row 1
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
b_df1:
    mov byte [es:bx], 1
    inc bx
    loop b_df1
    jmp b_df1_done

b_df1_trampoline:           ; Helper label for long jumps
    jmp b_df1_skip

b_df1_done:
b_df1_skip:
    inc si                  ; Move to next row relative to SI
    mov dx, si              ; Update DX

    ; --- ROW 2 ---
    cmp dx, 200
    jge b_df2_trampoline
    cmp dx, 0
    jl b_df2_trampoline
   
    ; Draw Row 2
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 4
    mov byte [es:bx], 15
    mov byte [es:bx+1], 15
    mov byte [es:bx+14], 15
    mov byte [es:bx+15], 15
    mov cx, 12
b_df2:
    mov byte [es:bx+2], 9
    inc bx
    loop b_df2
    jmp b_df2_done

b_df2_trampoline:
    jmp b_df2_skip

b_df2_done:
b_df2_skip:
    inc si
    mov dx, si

    ; --- ROW 3 ---
    cmp dx, 200
    jge b_df3_trampoline
    cmp dx, 0
    jl b_df3_trampoline
   
    ; Draw Row 3
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 2
    mov byte [es:bx], 1
    mov byte [es:bx+1], 9
    mov byte [es:bx+2], 9
    mov byte [es:bx+3], 9
    mov byte [es:bx+16], 9
    mov byte [es:bx+17], 9
    mov byte [es:bx+18], 9
    mov byte [es:bx+19], 1
    mov cx, 12
b_df3:
    mov byte [es:bx+4], 0
    inc bx
    loop b_df3

b_df3_trampoline:
    jmp b_df3_skip

b_df3_skip:
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
    cmp si, 200
    jge b_dh_skip_safe
    cmp si, 0
    jl b_dh_skip_safe

    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 1
    mov byte [es:bx], 1
    mov byte [es:bx+21], 1
    mov cx, 19
b_dh2:
    mov byte [es:bx+1], 1
    inc bx
    loop b_dh2
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 1
    mov byte [es:bx+14], 1
    jmp b_dh_next_iter

b_dh_skip_safe:
    jmp b_dh_skip_row

b_dh_next_iter:
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

draw_blue_windshield_f:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 1
    cmp si, 200
    jge b_dwf1_out
    cmp si, 0
    jl b_dwf1_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx-2], 1
    mov byte [es:bx-1], 1
    mov byte [es:bx], 1
    mov byte [es:bx+23], 1
    mov byte [es:bx+24], 1
    mov byte [es:bx+25], 1
    mov cx, 22
b_dwf1:
    mov byte [es:bx+1], 0
    inc bx
    loop b_dwf1
    jmp b_dwf1_done
b_dwf1_out:
    jmp b_dwf1_skip
b_dwf1_done:
b_dwf1_skip:
    inc si

    ; Row 2
    cmp si, 200
    jge b_dwf2_out
    cmp si, 0
    jl b_dwf2_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx-1], 1
    mov byte [es:bx+1], 1
    mov byte [es:bx+22], 1
    mov byte [es:bx+23], 1
    mov cx, 20
b_dwf2:
    mov byte [es:bx+2], 0
    inc bx
    loop b_dwf2
    jmp b_dwf2_done
b_dwf2_out:
    jmp b_dwf2_skip
b_dwf2_done:
b_dwf2_skip:
    inc si

    ; Row 3
    cmp si, 200
    jge b_dwf3_out
    cmp si, 0
    jl b_dwf3_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+21], 1
    mov cx, 18
b_dwf3:
    mov byte [es:bx+3], 0
    inc bx
    loop b_dwf3
    jmp b_dwf3_done
b_dwf3_out:
    jmp b_dwf3_skip
b_dwf3_done:
b_dwf3_skip:
    inc si

    ; Row 4
    cmp si, 200
    jge b_dwf4_out
    cmp si, 0
    jl b_dwf4_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+21], 1
    mov cx, 18
b_dwf4:
    mov byte [es:bx+3], 0
    inc bx
    loop b_dwf4
    jmp b_dwf4_done
b_dwf4_out:
    jmp b_dwf4_skip
b_dwf4_done:
b_dwf4_skip:
    inc si

    ; Row 5
    cmp si, 200
    jge b_dwf5_out
    cmp si, 0
    jl b_dwf5_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+21], 1
    mov cx, 18
b_dwf5:
    mov byte [es:bx+3], 0
    inc bx
    loop b_dwf5
    jmp b_dwf5_done
b_dwf5_out:
    jmp b_dwf5_skip
b_dwf5_done:
b_dwf5_skip:
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
    mov ax, si
b_dr1_:
    cmp si, 200
    jge b_dr_skip_safe
    cmp si, 0
    jl b_dr_skip_safe

    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2
    mov cx, 20
b_dr2_:
    mov byte [es:bx], 1
    inc bx
    loop b_dr2_
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+21], 1
    jmp b_dr_next

b_dr_skip_safe:
    jmp b_dr_skip_row

b_dr_next:
b_dr_skip_row:
    inc si
    dec dx
    jnz b_dr1_
   
    cmp ax, 200
    jge b_dr_skip_sunroof
    cmp ax, 0
    jl b_dr_skip_sunroof

    mov bx, ax
    imul bx, 320
    add bx, di
    add bx, 8
    mov cx, 8
b_sunroof_r:
    mov byte [es:bx], 0
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

draw_blue_body:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, 10
b_db1:
    cmp si, 200
    jge b_db_skip_safe
    cmp si, 0
    jl b_db_skip_safe

    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1
    mov byte [es:bx+23], 1
    add bx, 1
    mov cx, 22
b_db2:
    mov byte [es:bx], 1
    inc bx
    loop b_db2
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+5], 15
    mov byte [es:bx+18], 15
    jmp b_db_next

b_db_skip_safe:
    jmp b_db_skip_row

b_db_next:
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

draw_blue_windshield_r:
    push ax
    push bx
    push cx
    push dx
    push si
   
    ; Row 1
    cmp si, 200
    jge b_dwr1_out
    cmp si, 0
    jl b_dwr1_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+21], 1
    mov cx, 18
b_dwr1:
    mov byte [es:bx+3], 0
    inc bx
    loop b_dwr1
    jmp b_dwr1_done
b_dwr1_out:
    jmp b_dwr1_skip
b_dwr1_done:
b_dwr1_skip:
    inc si

    ; Row 2
    cmp si, 200
    jge b_dwr2_out
    cmp si, 0
    jl b_dwr2_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+21], 1
    mov cx, 18
b_dwr2:
    mov byte [es:bx+3], 0
    inc bx
    loop b_dwr2
    jmp b_dwr2_done
b_dwr2_out:
    jmp b_dwr2_skip
b_dwr2_done:
b_dwr2_skip:
    inc si

    ; Row 3
    cmp si, 200
    jge b_dwr3_out
    cmp si, 0
    jl b_dwr3_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+21], 1
    mov cx, 18
b_dwr3:
    mov byte [es:bx+3], 0
    inc bx
    loop b_dwr3
    jmp b_dwr3_done
b_dwr3_out:
    jmp b_dwr3_skip
b_dwr3_done:
b_dwr3_skip:
    inc si

    ; Row 4
    cmp si, 200
    jge b_dwr4_out
    cmp si, 0
    jl b_dwr4_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 1
    mov byte [es:bx+22], 1
    mov cx, 20
b_dwr4:
    mov byte [es:bx+2], 0
    inc bx
    loop b_dwr4
    jmp b_dwr4_done
b_dwr4_out:
    jmp b_dwr4_skip
b_dwr4_done:
b_dwr4_skip:
    inc si

    ; Row 5
    cmp si, 200
    jge b_dwr5_out
    cmp si, 0
    jl b_dwr5_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1
    mov byte [es:bx+23], 1
    mov cx, 22
b_dwr5:
    mov byte [es:bx+1], 0
    inc bx
    loop b_dwr5
    jmp b_dwr5_done
b_dwr5_out:
    jmp b_dwr5_skip
b_dwr5_done:
b_dwr5_skip:
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
   
    ; Row 1
    cmp si, 200
    jge b_dt1_out
    cmp si, 0
    jl b_dt1_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1
    mov byte [es:bx+23], 1
    mov cx, 22
b_dt1:
    mov byte [es:bx+1], 1
    inc bx
    loop b_dt1
    jmp b_dt1_done
b_dt1_out:
    jmp b_dt1_skip
b_dt1_done:
b_dt1_skip:
    inc si

    ; Row 2
    cmp si, 200
    jge b_dt2_out
    cmp si, 0
    jl b_dt2_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1
    mov byte [es:bx+23], 1
    mov cx, 22
b_dt2:
    mov byte [es:bx+1], 1
    inc bx
    loop b_dt2
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 1
    mov byte [es:bx+15], 1
    jmp b_dt2_done
b_dt2_out:
    jmp b_dt2_skip
b_dt2_done:
b_dt2_skip:
    inc si

    ; Row 3
    cmp si, 200
    jge b_dt3_out
    cmp si, 0
    jl b_dt3_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx], 1
    mov byte [es:bx+23], 1
    mov cx, 22
b_dt3:
    mov byte [es:bx+1], 1
    inc bx
    loop b_dt3
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+8], 1
    mov byte [es:bx+15], 1
    jmp b_dt3_done
b_dt3_out:
    jmp b_dt3_skip
b_dt3_done:
b_dt3_skip:
    inc si

    ; Row 4
    cmp si, 200
    jge b_dt4_out
    cmp si, 0
    jl b_dt4_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 1
    mov byte [es:bx+22], 1
    mov cx, 20
b_dt4:
    mov byte [es:bx+2], 1
    inc bx
    loop b_dt4
    jmp b_dt4_done
b_dt4_out:
    jmp b_dt4_skip
b_dt4_done:
b_dt4_skip:
    inc si

    ; Row 5
    cmp si, 200
    jge b_dt5_out
    cmp si, 0
    jl b_dt5_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+21], 1
    mov cx, 18
b_dt5:
    mov byte [es:bx+3], 1
    inc bx
    loop b_dt5
    jmp b_dt5_done
b_dt5_out:
    jmp b_dt5_skip
b_dt5_done:
b_dt5_skip:
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
   
    ; Row 1
    cmp si, 200
    jge b_drb1_out
    cmp si, 0
    jl b_drb1_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+21], 1
    mov cx, 18
b_drb1:
    mov byte [es:bx+3], 1
    inc bx
    loop b_drb1
    jmp b_drb1_done
b_drb1_out:
    jmp b_drb1_skip
b_drb1_done:
b_drb1_skip:
    inc si

    ; Row 2
    cmp si, 200
    jge b_drb2_out
    cmp si, 0
    jl b_drb2_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+2], 1
    mov byte [es:bx+3], 4
    mov byte [es:bx+4], 4
    mov byte [es:bx+19], 4
    mov byte [es:bx+20], 4
    mov byte [es:bx+21], 1
    mov cx, 14
b_drb2:
    mov byte [es:bx+5], 8
    inc bx
    loop b_drb2
    jmp b_drb2_done
b_drb2_out:
    jmp b_drb2_skip
b_drb2_done:
b_drb2_skip:
    inc si

    ; Row 3
    cmp si, 200
    jge b_drb3_out
    cmp si, 0
    jl b_drb3_out
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+3], 1
    mov byte [es:bx+20], 1
    mov cx, 16
b_drb3:
    mov byte [es:bx+4], 8
    inc bx
    loop b_drb3
    jmp b_drb3_done
b_drb3_out:
    jmp b_drb3_skip
b_drb3_done:
b_drb3_skip:
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
   
    ; Row 1
    cmp si, 200
    jge b_drt1_out
    cmp si, 0
    jl b_drt1_out
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 4
    mov cx, 16
b_drt1:
    mov byte [es:bx], 1
    inc bx
    loop b_drt1
    jmp b_drt1_done
b_drt1_out:
    jmp b_drt1_skip
b_drt1_done:
b_drt1_skip:
    inc si

    ; Row 2
    cmp si, 200
    jge b_drt2_out
    cmp si, 0
    jl b_drt2_out
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
b_drt2:
    mov byte [es:bx], 1
    inc bx
    loop b_drt2
    jmp b_drt2_done
b_drt2_out:
    jmp b_drt2_skip
b_drt2_done:
b_drt2_skip:
    pop si
    pop cx
    pop bx
    pop ax
    ret

; ==================================================================
; MULTITASKING: BACKGROUND MUSIC ISR
; ==================================================================
setup_music_interrupt:
    ; Remove any existing interrupt first
    call remove_music_interrupt
   
    cli                         ; Disable interrupts while hooking
    ; 1. Save Old Interrupt Vector (INT 1Ch - System Timer Tick)
    mov ah, 35h
    mov al, 1Ch
    int 21h
    mov [old_isr_offset], bx
    mov [old_isr_segment], es

    ; 2. Set New Interrupt Vector to our routine
    mov ah, 25h
    mov al, 1Ch
    mov dx, music_player_isr
    push cs
    pop ds                  ; DS must point to our segment
    int 21h
   
    ; 3. Reset music state
    mov word [current_note_idx], 0
    mov word [music_tick_count], 1
    mov byte [music_active], 1
    sti                         ; Re-enable interrupts
    ret
remove_music_interrupt:
    cmp byte [music_active], 0
    je remove_skip
   
    cli
    ; 1. Silence the Speaker immediately
    in al, 61h
    and al, 0FCh            ; Clear bits 0 and 1
    out 61h, al

    ; 2. Restore Old Interrupt Vector
    push ds
    mov dx, [old_isr_offset]
    mov ax, [old_isr_segment]
    mov ds, ax
    mov ah, 25h
    mov al, 1Ch
    int 21h
    pop ds
   
    mov byte [music_active], 0
    sti
remove_skip:
    ret

; ------------------------------------------------------------------
; The "Process" that runs in the background 18.2 times/sec
; ------------------------------------------------------------------
music_player_isr:
    pusha                    ; Save all registers (Context Switch)
    push ds
    push es
   
    ; Ensure DS points to our data
    push cs
    pop ds

    ; Logic: Decrease duration counter
    dec word [music_tick_count]
    cmp word [music_tick_count], 0
    jg music_keep_playing   ; Current note not finished

    ; Load Next Note
    mov si,  music_score
    add si, [current_note_idx]
   
    mov ax, [si]            ; Read Frequency
    cmp ax, 0
    je music_reset_song      ; If 0, loop back to start

    mov cx, [si+2]          ; Read Duration
    mov [music_tick_count], cx
   
    add word [current_note_idx], 4 ; Move to next pair (2 words = 4 bytes)

    ; Play the Sound
    call play_frequency_port
    jmp music_keep_playing

music_reset_song:
    mov word [current_note_idx], 0
    mov word [music_tick_count], 1 ; Trigger load next tick
    jmp music_keep_playing

music_keep_playing:
    pop es
    pop ds
    popa                    ; Restore registers
    iret                    ; Return from Interrupt

; ------------------------------------------------------------------
; HARDWARE PORT ACCESS
; ------------------------------------------------------------------
play_frequency_port:
    ; AX contains Frequency in Hz
    cmp ax, 0
    je silence_speaker      ; If freq is 0, silence (rest)

    ; 1. Set up PIT (Programmable Interval Timer)
    push ax
    mov al, 0B6h            ; Channel 2, LSB/MSB, Square Wave
    out 43h, al
   
    ; 2. Calculate Divisor (1,193,180 / Frequency)
    mov dx, 0012h
    mov ax, 34DCh           ; DX:AX = 1,193,180
    pop bx                  ; Retrieve Frequency
    div bx
   
    ; 3. Send Divisor to Port 42h
    out 42h, al             ; Send LSB
    mov al, ah
    out 42h, al             ; Send MSB

    ; 4. Turn Speaker ON (Port 61h)
    in al, 61h
    or al, 03h              ; Set bits 0 and 1
    out 61h, al
    ret

silence_speaker:
    in al, 61h
    and al, 0FCh            ; Clear bits 0 and 1
    out 61h, al
    ret


get_random_0_to_2:
    push ax
    push cx
    push dx
    mov al, 0
    out 0x70, al
    jmp short rtc_delay
rtc_delay:
    in al, 0x71
    mov ah, al
    shr ah, 4
    and al, 0x0F
    push ax
    mov al, ah
    xor ah, ah
    mov cx, 10
    mul cx
    pop dx
    xor dh, dh
    add ax, dx
    mov cx, 3
    xor dx, dx
    div cx
    mov bx, dx
    pop dx
    pop cx
    pop ax
    ret




car_x dw 0
car_y dw 0
blue_car_x dw 0
blue_car_y dw 0
blue_car_x_old dw 0
blue_car_y_old dw 0
lane_offset dw 0

; Add these after fuel_empty_flag
fuel_can_x dw 0
fuel_can_y dw 0
fuel_can_x_old dw 0
fuel_can_y_old dw 0
fuel_can_active dw 0        ; 0 = not active, 1 = active
fuel_spawn_counter dw 0     ; Counter to control spawn frequency

coin_x dw 0
coin_y dw 0
coin_x_old dw 0
coin_y_old dw 0
car_x_old   dw 0
car_y_old   dw 0
CAR_WIDTH   dw 30
ROAD_COLOR  db 8
fuel_msg db 'FUEL: ', 0
game_state  dw 0
car_lane    dw 2
LANE_1_X    dw 90
LANE_2_X    dw 148
LANE_3_X    dw 203
Y_STEP      dw 10
CAR_HEIGHT  dw 40
SCREEN_BOTTOM dw 200
PAUSE_BOX_X dw 80
PAUSE_BOX_Y dw 60
PAUSE_BOX_W dw 160
PAUSE_BOX_H dw 80
PAUSE_TEXT_ROW db 10
PAUSE_TEXT_COL db 12
GREEN_COLOR db 10
MSG_LENGTH  dw 28
pause_buffer times 12800 db 0
pause_msg db 'QUIT? (Y/N)', 0
pause_line1 db 'GAME PAUSED', 0
pause_line2 db 'QUIT? (Y/N)', 0
score_msg_label db 'SCORE:', 0
score        dw 0
collision_flag dw 0
name_prompt db 'ENTER YOUR NAME:', 0
roll_prompt db 'ENTER ROLL NUMBER:', 0
player_name times 50 db 0
player_roll times 20 db 0
fuel_val dw 0         ; Current width of fuel bar
fuel_timer dw 0       ; Timer to slow down fuel decrease
fuel_empty_flag dw 0  ; Flag if fuel runs out
fuel_tank_x dw 0
fuel_tank_y dw 0
fuel_tank_x_old dw 0
fuel_tank_y_old dw 0
pal_buffer times 768 db 0
file_pal db "mspal.bin", 0
file_pix db "mspixels.bin", 0
file_is_pal db "ispal.bin", 0
file_is_pix db "ispixels.bin", 0
file_nr_pal db "nrpal.bin", 0
file_nr_pix db "nrpixels.bin", 0
file_st_pal db "stpal.bin", 0
file_st_pix db "stpixels.bin", 0
file_qu_pal db "qupal.bin", 0
file_qu_pix db "qupixels.bin", 0
file_cr_pal db "crpal.bin", 0
file_cr_pix db "crpixels.bin", 0
file_fu_pal db "fupal.bin", 0
file_fu_pix db "fupixels.bin", 0
file_re_pal db "repal.bin", 0
file_re_pix db "repixels.bin", 0

; --- NEW STRINGS FOR RESULTS SCREEN ---
txt_res_name  db "NAME: ", 0
txt_res_roll  db "ROLL: ", 0
txt_res_score db "SCORE: ", 0

; ==================================================================
; MUSIC DATA SECTION
; ==================================================================
; Frequencies (Hertz)
NOTE_C4  EQU 262
NOTE_D4  EQU 294
NOTE_E4  EQU 330
NOTE_F4  EQU 349
NOTE_G4  EQU 392
NOTE_A4  EQU 440
NOTE_B4  EQU 494
NOTE_C5  EQU 523

; Music State Variables
old_isr_offset  dw 0
old_isr_segment dw 0
music_tick_count dw 1
current_note_idx dw 0
music_active     db 0    ; 1 = ON, 0 = OFF

; THE MELODY: Pair of DW (Frequency, Duration in ticks)
; REPLACED: Faster Tempo for Racing Game (Duration 2 ticks = ~0.11s)
music_score:
    ; Pattern 1: Fast rising arpeggio (C Major)
    dw NOTE_C4, 2, NOTE_E4, 2, NOTE_G4, 2, NOTE_C5, 2
    dw NOTE_G4, 2, NOTE_E4, 2, NOTE_C4, 2, 0, 1       ; Brief rest

    ; Pattern 2: Fast rising arpeggio (D Minorish)
    dw NOTE_D4, 2, NOTE_F4, 2, NOTE_A4, 2, NOTE_D4, 2
    dw NOTE_A4, 2, NOTE_F4, 2, NOTE_D4, 2, 0, 1

    ; Pattern 3: Rising Tension
    dw NOTE_E4, 2, NOTE_G4, 2, NOTE_B4, 2, NOTE_E4, 2
    dw NOTE_F4, 2, NOTE_A4, 2, NOTE_C5, 2, NOTE_F4, 2
   
    ; Pattern 4: Quick Descent
    dw NOTE_G4, 2, NOTE_F4, 2, NOTE_E4, 2, NOTE_D4, 2
    dw NOTE_C4, 4, 0, 4                               ; End phrase with a hold

    dw 0, 0 ; End of list marker (Loops back)
