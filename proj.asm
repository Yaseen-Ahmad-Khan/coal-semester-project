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
jc load_error        
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
jc load_error
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

load_error:
    mov ah, 0Bh
    mov bh, 00h
    mov bl, 4          
    int 10h

; -------------------------------
; Wait for SPACEBAR to Continue
; -------------------------------
wait_for_space:
    mov ah, 0
    int 16h         
    
    ; Check for ESC (Title Screen -> Confirm -> Direct Exit)
    cmp ah, 01h
    je title_esc_pressed

    cmp al, 20h     ; Spacebar
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
    je quit_direct_dos
    cmp al, 'Y'
    je quit_direct_dos
    
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

quit_direct_dos:
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h

; ==================================================================
; SECTION 1.5: INSTRUCTIONS SCREEN
; ==================================================================
section_1_5_start:

; -------------------------------
; 1. Open and Read INSTRUCTIONS Palette (ispal.bin)
; -------------------------------
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

; -------------------------------
; 2. Open and Read INSTRUCTIONS Pixels (ispixels.bin)
; -------------------------------
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
    jmp start_data_entry ; Skip if files missing

; -------------------------------
; Wait for 'N' to Continue
; -------------------------------
wait_for_n:
    mov ah, 0
    int 16h
    
    ; Check for ESC key
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
    je quit_direct_dos
    cmp al, 'Y'
    je quit_direct_dos
    
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
; SECTION 1.8: PLAYER DATA ENTRY (NAME & ROLL NO)
; ==================================================================
start_data_entry:

    ; 1. Reset Screen to Black (Text/Graphics Mode)
    mov ax, 0013h
    int 10h

    ; 2. Print "ENTER YOUR NAME:"
    ; Set Cursor Position (Row 10, Col 5)
    mov ah, 02h
    mov bh, 00h
    mov dh, 10      ; Row
    mov dl, 5       ; Column
    int 10h

    ; Print Prompt String
    mov si, name_prompt
    call print_string_bios

    ; 3. Get Name Input
    mov di, player_name     ; Point DI to storage buffer
    call get_input_string   ; Call custom input routine

    ; 4. Print "ENTER ROLL NUMBER:"
    ; Set Cursor Position (Row 14, Col 5)
    mov ah, 02h
    mov bh, 00h
    mov dh, 14      ; Row
    mov dl, 5       ; Column
    int 10h

    ; Print Prompt String
    mov si, roll_prompt
    call print_string_bios

    ; 5. Get Roll Number Input
    mov di, player_roll     ; Point DI to storage buffer
    call get_input_string   ; Call custom input routine

    ; Fall through to Story/Start screen...

; ==================================================================
; SECTION 1.9: STORY/START SCREEN (stpal.bin, stpixel.bin)
; ==================================================================

section_1_9_start:          ; Target for Spacebar on Quit Screen

; -------------------------------
; 1. Open and Read STORY Palette (stpal.bin)
; -------------------------------
mov ah, 3Dh
mov al, 0
mov dx, file_st_pal
int 21h
jc load_st_error        ; If error, skip straight to game
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
out_st_pal_loop:
    mov al, [si]
    out dx, al
    inc si
    loop out_st_pal_loop

; -------------------------------
; 2. Open and Read STORY Pixels (stpixel.bin)
; -------------------------------
mov ah, 3Dh
mov al, 0
mov dx, file_st_pix
int 21h
jc load_st_error
mov bx, ax

; Read Pixels to Video Memory
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

jmp wait_for_space_start

load_st_error:
    jmp start_game ; If files missing, jump straight to game

; -------------------------------
; Wait for SPACEBAR to Start Game
; -------------------------------
wait_for_space_start:
    mov ah, 0
    int 16h
    
    ; Check for ESC (Story Screen -> Confirm -> Direct Exit)
    cmp ah, 01h
    je story_esc_pressed

    cmp al, 20h     ; Spacebar ASCII
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
    je quit_direct_dos
    cmp al, 'Y'
    je quit_direct_dos
    
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

; ==================================================================
; SECTION 2: GAME LOGIC (LAAL GAARI PROJECT)
; ==================================================================

start_game:
; --- ARROW KEY & RESTART FIX ---
; 1. Reset Stack Pointer and Segments
cli             ; Disable interrupts briefly
mov ax, cs
mov ds, ax      ; Force DS = CS
mov es, ax      ; Force ES = CS
mov ss, ax      ; Force SS = CS
mov sp, 0xFFFE  ; Reset Stack Pointer (Prevents stack overflow on restart)
sti             ; Re-enable interrupts

; 2. Re-Initialize Video Mode
mov ax, 0013h
int 10h
mov ax, 0A000h
mov es, ax

; 3. Flush Keyboard Buffer
flush_keys:
    mov ah, 01h         
    int 16h
    jz buffer_clean     
    mov ah, 00h         
    int 16h
    jmp flush_keys
buffer_clean:

; --- INITIALIZATION (STATIC) ---
mov word [car_x], 148       
mov word [car_y], 120 

; 4. CRITICAL: Reset OLD coordinates so erasing works correctly on restart
mov word [car_x_old], 148   
mov word [car_y_old], 120   

mov word [car_lane], 2      
mov word [lane_offset], 0
mov word [game_state], 0    

; Blue Car position
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
    mov word [blue_car_y], 10   
mov ax, [blue_car_x]
mov [blue_car_x_old], ax
mov word [blue_car_y_old], 10 

; --- COIN INITIALIZATION  ---
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

; --- DRAW ALL STATIC ELEMENTS ONCE ---
call draw_static_background
call draw_car               
call draw_fuel_text         
call draw_fuel_tanks        

mov word [game_state], 1

; Main animation loop
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
    jne animation_loop      
   
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
    call draw_blue_car          

    call erase_coin
    mov ax, [coin_y]
    mov [coin_y_old], ax
    mov ax, [coin_x]
    mov [coin_x_old], ax
   
    mov ax, [coin_y]
    add ax, 4
    mov [coin_y], ax
   
    cmp ax, 200
    jb cnao
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
   
cnao:
    call draw_coin              

    mov ax, [lane_offset]
    add ax, 9           
    cmp ax, 75          
    jl no_wrap
    sub ax, 75
no_wrap:
    mov [lane_offset], ax
   
    jmp animation_loop

paused_game:
    call handle_pause_input
    jmp animation_loop

exit_game:
    jmp show_quit_screen  ; Game exits to IMAGE

; ==================================================================
; NEW HELPER FUNCTIONS FOR INPUT
; ==================================================================

; --- Print String using BIOS (INT 10h) ---
print_string_bios:
    push ax
    push bx
    push si
    mov bl, 10          ; Color: Bright Green
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

; --- Get Input String ---
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
    je quit_direct_dos
    cmp al, 'Y'
    je quit_direct_dos
    
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

; ==================================================================
; NEW: QUIT SCREEN LOGIC
; ==================================================================
show_quit_screen:
    ; 1. Initialize Video Mode
    mov ax, 0013h
    int 10h

    ; 2. Open and Read Quit Palette
    mov ah, 3Dh
    mov al, 0
    mov dx, file_qu_pal
    int 21h
    jc quit_direct_dos
    mov bx, ax

    ; Read Palette
    mov ah, 3Fh
    mov cx, 768
    mov dx, pal_buffer
    int 21h

    ; Close File
    mov ah, 3Eh
    int 21h

    ; Apply Palette
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

    ; 3. Open and Read Quit Pixels
    mov ah, 3Dh
    mov al, 0
    mov dx, file_qu_pix
    int 21h
    jc quit_direct_dos
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

    ; Close File
    mov ah, 3Eh
    int 21h

wait_quit_input:
    mov ah, 0
    int 16h
    
    cmp ah, 01h         ; ESC Key
    je quit_direct_dos
    
    cmp al, 20h         ; Spacebar
    je jmp_sec_1_9
    
    jmp wait_quit_input

jmp_sec_1_9:
    jmp section_1_9_start

; ==================================================================
; EXISTING GAME FUNCTIONS
; ==================================================================

erase_blue_car:
    push ax
    push bx
    push cx
    push si
    push di
    mov al, 8           
    mov si, [blue_car_y_old]    
    mov di, [blue_car_x_old]    
    sub di, 2                   
    mov cx, 40          
erase_row:
    push cx
    cmp si, 200                 
    jge erase_skip_row          
    mov bx, si
    imul bx, 320                
    add bx, di                  
    mov cx, 28                  
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

erase_coin:
    push ax
    push bx
    push cx
    push si
    push di
    mov al, 8                   
    mov si, [coin_y_old]        
    mov di, [coin_x_old]        
    sub di, 4                   
    mov cx, 10                  
coin_erase_row:
    push cx
    cmp si, 200                 
    jge coin_erase_skip_row     
    mov bx, si
    imul bx, 320                
    add bx, di                  
    mov cx, 8                   
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

erase_red_car:
    push ax
    push bx
    push cx
    push si
    push di
    mov al, [ROAD_COLOR] 
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
    
    ; --- ARROW KEY FIX: Handle Normal (AL=0) AND Extended (AL=E0) Keys ---
    cmp al, 0
    je process_key
    cmp al, 0E0h        
    je process_key
    
    jmp hi_ignore       ; If AL is not 0 or E0, ignore it

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

move_car_right:
    push ax
    push bx
    cmp word [car_lane], 3  
    je mcr_exit             
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
    jmp show_quit_screen  ; Game Pause -> Quit Image
hpi_exit:
    pop ax
    ret

; ==================================================================
; IMPROVED PAUSE FUNCTIONALITY
; ==================================================================

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
    mov byte [es:bx+1], 15
    mov byte [es:bx+2], 14 
    mov byte [es:bx+3], 0
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
    mov byte [es:bx+3], 0
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
    mov byte [es:bx+3], 0
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

draw_fuel_tanks:
    push ax
    push bx
    push cx
    push si
    push di
    push bp
    mov cx, 3           
    mov di, 273         
tank_loop:
    push cx             
    mov si, 180         
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 3           
    mov byte [es:bx], 0
    mov byte [es:bx+1], 0
    mov byte [es:bx+2], 0
    mov byte [es:bx+3], 0
    inc si
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2           
    mov cx, 6
tc1_pix:
    mov byte [es:bx], 0 
    inc bx
    loop tc1_pix
    inc si
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0 
    mov byte [es:bx+3], 4 
    mov byte [es:bx+4], 4
    mov byte [es:bx+5], 4
    mov byte [es:bx+6], 4
    mov byte [es:bx+8], 0 
    inc si
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0 
    mov cx, 6
    mov bp, bx
    add bp, 2 
tc3_fill:
    mov byte [es:bp], 4 
    inc bp
    loop tc3_fill
    mov byte [es:bx+8], 0 
    inc si
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0 
    mov byte [es:bx+2], 4 
    mov byte [es:bx+3], 15 
    mov byte [es:bx+4], 4 
    mov byte [es:bx+5], 4 
    mov byte [es:bx+6], 4 
    mov byte [es:bx+7], 4 
    mov byte [es:bx+8], 0 
    inc si
    mov cx, 5 
tc_main_loop:
    push cx
    mov bx, si
    imul bx, 320
    add bx, di
    mov byte [es:bx+1], 0 
    mov cx, 7
    mov bp, bx
    add bp, 2
tc_main_fill:
    mov byte [es:bp], 4 
    inc bp
    loop tc_main_fill
    mov byte [es:bx+8], 0 
    inc si
    pop cx
    loop tc_main_loop
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 2
    mov cx, 6
tc10_pix:
    mov byte [es:bx], 0 
    inc bx
    loop tc10_pix
    inc si
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 3
    mov byte [es:bx], 0
    mov byte [es:bx+1], 0
    mov byte [es:bx+2], 0
    mov byte [es:bx+3], 0
    add di, 14          
    pop cx              
    dec cx              
    jnz tank_loop        
    pop bp
    pop di
    pop si
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
    mov dx, si
    cmp dx, 200         
    jge b_df1_skip      
    mov bx, dx
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
b_df1:
    mov byte [es:bx], 1 
    inc bx
    loop b_df1
b_df1_skip:
    inc dx
    cmp dx, 200         
    jge b_df2_skip      
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
b_df2_skip:
    inc dx
    cmp dx, 200         
    jge b_df3_skip      
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
    jge b_dh_skip_row   
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
    cmp si, 200         
    jge b_dwf1_skip     
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
b_dwf1_skip:
    inc si
    cmp si, 200         
    jge b_dwf2_skip     
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
b_dwf2_skip:
    inc si
    cmp si, 200         
    jge b_dwf3_skip     
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
b_dwf3_skip:
    inc si
    cmp si, 200         
    jge b_dwf4_skip     
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
b_dwf4_skip:
    inc si
    cmp si, 200         
    jge b_dwf5_skip     
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
    jge b_dr_skip_row   
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
b_dr_skip_row:
    inc si
    dec dx
    jnz b_dr1_
    cmp ax, 200         
    jge b_dr_skip_sunroof 
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
    jge b_db_skip_row   
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
    cmp si, 200         
    jge b_dwr1_skip     
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
b_dwr1_skip:
    inc si
    cmp si, 200         
    jge b_dwr2_skip     
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
b_dwr2_skip:
    inc si
    cmp si, 200         
    jge b_dwr3_skip     
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
b_dwr3_skip:
    inc si
    cmp si, 200         
    jge b_dwr4_skip     
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
b_dwr4_skip:
    inc si
    cmp si, 200         
    jge b_dwr5_skip     
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
    cmp si, 200         
    jge b_dt1_skip      
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
b_dt1_skip:
    inc si
    cmp si, 200         
    jge b_dt2_skip      
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
b_dt2_skip:
    inc si
    cmp si, 200         
    jge b_dt3_skip      
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
b_dt3_skip:
    inc si
    cmp si, 200         
    jge b_dt4_skip      
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
b_dt4_skip:
    inc si
    cmp si, 200         
    jge b_dt5_skip      
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
    cmp si, 200         
    jge b_drb1_skip     
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
b_drb1_skip:
    inc si
    cmp si, 200         
    jge b_drb2_skip     
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
b_drb2_skip:
    inc si
    cmp si, 200         
    jge b_drb3_skip     
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
    cmp si, 200         
    jge b_drt1_skip     
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 4
    mov cx, 16
b_drt1:
    mov byte [es:bx], 1 
    inc bx
    loop b_drt1
b_drt1_skip:
    inc si
    cmp si, 200         
    jge b_drt2_skip     
    mov bx, si
    imul bx, 320
    add bx, di
    add bx, 7
    mov cx, 10
b_drt2:
    mov byte [es:bx], 1 
    inc bx
    loop b_drt2
b_drt2_skip:
    pop si
    pop cx
    pop bx
    pop ax
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


; ==================================================================
; UPDATED DATA SECTION
; ==================================================================

; Data section (add these to your data segment)
PAUSE_BOX_X dw 80
PAUSE_BOX_Y dw 60
PAUSE_BOX_W dw 160
PAUSE_BOX_H dw 80
pause_buffer times 12800 db 0      ; 160*80 buffer for saving screen
pause_line1 db 'GAME PAUSED', 0
pause_line2 db 'QUIT? (Y/N)', 0
 

; -- NEW DATA FOR INPUT SCREEN --
name_prompt db 'ENTER YOUR NAME:', 0
roll_prompt db 'ENTER ROLL NUMBER:', 0
player_name times 50 db 0   ; Buffer for name
player_roll times 20 db 0   ; Buffer for roll number

; Buffer for reading the palette (At the end of code)
pal_buffer times 768 db 0
file_pal db "mspal.bin", 0
file_pix db "mspixels.bin", 0
file_is_pal db "ispal.bin", 0
file_is_pix db "ispixels.bin", 0
file_st_pal db "stpal.bin", 0
file_st_pix db "stpixels.bin", 0
file_qu_pal db "qupal.bin", 0    ; ADDED: Quit Screen Palette
file_qu_pix db "qupixels.bin", 0 ; ADDED: Quit Screen Pixels
