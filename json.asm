
section .text
struc JSONElement 
    elementType: resb 1
    data: resb 4
endstruc
global main
default rel
extern printf
extern calloc
main:
    cmp rdi, 1 ;check if no file name passed
    je no_filename

    ; open argv[1] as a file
    mov rdi, [rsi + 8] ; go to first argument
    xor rsi, rsi ; clear rsi
    mov rax, 2 ; set syscall to open
    syscall ; open file
    
    ; Check for errors
    cmp rax, 0
    jl no_file ; check if below 0
    mov [FD], rax ; set FD to the file descriptor

    ; lseek to end to get length
    mov rdi, [FD] 
    xor rsi, rsi
    mov rdx, 2
    mov rax, 8
    syscall ; seek to end of file
    
    ; lseek back to start
    mov [LENGTH], rax ; set LENGTH to value returned
    mov rax, 8 ; 
    mov rdi, [FD]
    xor rsi, rsi
    mov rdx, 0
    syscall

    ; Allocate buffer    
    mov rdi, [LENGTH]
    mov rsi, 1
    call calloc wrt ..plt
    mov [BUFFER], rax

    ; Read file 
    xor rax, rax
    mov rdi, [FD]
    mov rsi, [BUFFER]
    mov rdx, [LENGTH]
    syscall

    ; Get depth of JSON file to calloc
    mov rsi, [BUFFER]
    xor rbx, rbx
    xor rcx, rcx
get_depth_loop:
    
    
    cmp rbx, [LENGTH]
    jge get_depth_end
    xor rax, rax
    mov al, [rsi + rbx]
    inc rbx
    cmp al, '\'
    je escape
    cmp al, '['
    je increment_depth
    cmp al, '{'
    je increment_depth
    cmp al, ']'
    je decrement_depth
    cmp al, '}'
    je decrement_depth
    cmp al, '"'
    je toggle_string
    cmp al, 10
    je check_string
    

    jmp get_depth_loop
escape:
    inc rbx
    jmp get_depth_loop
increment_depth:
    inc rcx 
    cmp rcx, [MAX_DEPTH]
    jg set_max_depth
    jmp get_depth_loop
decrement_depth:
    dec rcx
    cmp rcx, 0
    jl unexpected_char
    jmp get_depth_loop
set_max_depth:
    mov [MAX_DEPTH], rcx
    jmp get_depth_loop
toggle_string:
    xor byte [IS_STRING], 1
    jmp get_depth_loop
check_string:
    cmp byte [IS_STRING], 1
    je unexpected_new_line
    jmp get_depth_loop

get_depth_end:
    cmp rcx, 0
    jz expected_character
    cmp [IS_STRING], 1
    je expected_character
    mov rdi, [MAX_DEPTH + 1]
    mov rsi, 1
    call calloc wrt ..plt
    mov [DEPTH_BUFFER], rax
    xor rcx, rcx
    xor rbx, rbx
    mov rsi, [DEPTH_BUFFER]
    xor [IS_STRING], [IS_STRING]
    jmp parse_json

parse_json:
    cmp rbx, [LENGTH]
    jge parse_json_end
    xor rax, rax
    mov al, [rsi + rbx]
    inc rbx
    cmp al, '\'
    je json_parse_escape
    cmp al, '['
    je json_parse_increment_depth
    cmp al, '{'
    je json_parse_increment_depth
    cmp al, ']'
    je json_parse_decrement_array
    cmp al, '}'
    je json_parse_decrement_object
    cmp al, '"'
    je json_parse_toggle_string
    cmp al, 10
    je json_parse_check_string
    cmp al, ':'
    je json_parse_colon
    cmp al, ','
    je json_parse_comma
    cmp [IS_STRING], 0
    jz unexpected_char        
    jmp parse_json

json_parse_colon:
    push rbx
    mov rbx, [DEPTH_BUFFER]
    add rbx, rcx
    dec rbx
    cmp [rbx], '['
    je unexpected_char
    ; TODO ADD HASHMAP 
    pop rbx
    jmp parse_json

json_parse_increment_depth:
    inc rcx
    push rbx
    mov rbx, [DEPTH_BUFFER]
    add rbx, rcx
    mov [rbx], al
    pop rbx
    jmp parse_json

json_parse_decrement_object:
    dec rcx
    push rbx
    mov rbx, [DEPTH_BUFFER]
    add rbx, rcx
    inc rbx
    cmp [rbx], '{'
    jne mismatch_character
    mov [rbx], 0
    pop rbx
    jmp parse_json

json_parse_decrement_array:
    dec rcx
    push rbx
    mov rbx, [DEPTH_BUFFER]
    add rbx, rcx
    inc rbx
    cmp [rbx], '['
    jne mismatch_character
    mov [rbx], 0
    pop rbx
    jmp parse_json

;============================; 
;           ERRORS           ;
;============================;

mismatch_character:
    mov rdi, ERROR_6
    xor rax, rax
    call printf wrt ..plt
    mov rax, 1
    ret
expected_character:
    mov rdi, ERROR_5
    xor rax, rax
    call printf wrt ..plt
    mov rax, 1
    ret

unexpected_new_line:
    mov rdi, ERROR_4
    xor rax, rax
    call printf wrt ..plt
    mov rax, 1
    ret
unexpected_char:
    mov rdi, ERROR_3
    mov rsi, rax
    xor rax, rax
    call printf wrt ..plt
    mov rax, 1
    ret
no_file:
    mov rdi, ERROR_2
    mov rsi, rax
    xor rax, rax
    call printf wrt ..plt
    mov rax, 1
    ret
no_filename: 
    mov rdi, ERROR_1
    xor rax, rax
    call printf wrt ..plt
    mov rax, 1
    ret
section .data
ERROR_1: db "No filename specified, please mention the filename!", 10, 0
ERROR_2: db "File cannot be opened: Error %d", 10, 0
ERROR_3: db "Error parsing JSON: Unexpected %c", 10, 0
ERROR_4: db "Error parsing JSON: Unexpected New Line", 10, 0
ERROR_5: db "Error parsing JSON: Expected Character", 10, 0
ERROR_6: db "Error parsing JSON: Mismatching Parentheses", 10, 0
INT_ARGS: db "%d", 10, 0
FD: dq 0
BUFFER: dq 0
LENGTH: dq 0
IS_STRING: db 0
MAX_DEPTH: dq 0
DEPTH_BUFFER: dq 0