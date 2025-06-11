; http_full.s
section .data
    msg_method db "Method: ", 0
    msg_path db "Path: ", 0
    msg_version db "Version: ", 0
    msg_header db "Header: ", 0
    newline db 10

section .bss
    buf resb 2048
    token resb 256

section .text
    global _start

_start:
    ; read(0, buf, 2048)
    mov eax, 0
    mov edi, 0
    mov rsi, buf
    mov edx, 2048
    syscall

    mov rbx, buf  ; pointer to parse

    ; === Parse Method ===
    mov rdi, msg_method
    call print_str
    call parse_token
    call print_token

    ; === Parse Path ===
    mov rdi, msg_path
    call print_str
    call parse_token
    call print_token

    ; === Parse Version ===
    mov rdi, msg_version
    call print_str
    call parse_until_crlf
    call print_token

    ; === Parse Headers ===
.parse_headers:
    ; check if line starts with \r\n (end of headers)
    mov al, [rbx]
    cmp al, 13     ; \r
    jne .parse_header_line
    mov al, [rbx+1]
    cmp al, 10     ; \n
    jne .parse_header_line
    add rbx, 2
    jmp .done

.parse_header_line:
    mov rdi, msg_header
    call print_str
    call parse_until_crlf
    call print_token
    jmp .parse_headers

.done:
    ; exit
    mov eax, 60
    xor edi, edi
    syscall

; -------------------------------
; parse_token: parse until ' '
; rbx = input ptr, result in [token]
parse_token:
    mov rsi, token
.token_loop:
    mov al, [rbx]
    cmp al, ' '
    je .done_tok
    mov [rsi], al
    inc rbx
    inc rsi
    jmp .token_loop
.done_tok:
    mov byte [rsi], 0
    inc rbx
    ret

; -------------------------------
; parse_until_crlf: until \r\n
; rbx = input ptr, result in [token]
parse_until_crlf:
    mov rsi, token
.loop_crlf:
    mov al, [rbx]
    cmp al, 13
    je .check_lf
    mov [rsi], al
    inc rbx
    inc rsi
    jmp .loop_crlf
.check_lf:
    cmp byte [rbx+1], 10
    jne .loop_crlf
    add rbx, 2
    mov byte [rsi], 0
    ret

; -------------------------------
; print_str: print null-terminated rdi (tanpa newline)
print_str:
    push rdi
    call strlen
    mov edx, eax
    pop rsi
    mov eax, 1
    mov edi, 1
    syscall
    ret

; print_token: print [token] + newline
print_token:
    mov rdi, token
    call strlen
    mov edx, eax
    mov eax, 1
    mov edi, 1
    mov rsi, token
    syscall
    ; print newline
    mov eax, 1
    mov edi, 1
    mov rsi, newline
    mov edx, 1
    syscall
    ret

; -------------------------------
; strlen: rdi -> rax = length
strlen:
    xor rax, rax
.loop_strlen:
    cmp byte [rdi+rax], 0
    je .done_strlen
    inc rax
    jmp .loop_strlen
.done_strlen:
    ret
