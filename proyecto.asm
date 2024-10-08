
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h
.model small
.stack 100h
.data
    prompt db 'Ingrese una expresion (o "salir" para terminar): $'
    resultado_msg db 0Dh,0Ah,'Resultado: $'
    error_msg db 0Dh,0Ah,'Error en la expresion$'
    historial_msg db 0Dh,0Ah,'Historial de operaciones:',0Dh,0Ah,'$'
    nueva_linea db 0Dh,0Ah,'$'
    buffer db 100, ?, 100 dup('$')
    historial db 1000 dup('$')
    num_temp dw ?
    resultado dw ?
    operador db ?

.code
main proc
    mov ax, @data
    mov ds, ax

bucle_principal:
    lea dx, nueva_linea
    mov ah, 09h
    int 21h

    lea dx, prompt
    mov ah, 09h
    int 21h

    lea dx, buffer
    mov ah, 0Ah
    int 21h

    lea dx, nueva_linea
    mov ah, 09h
    int 21h

    mov si, offset buffer + 2
    mov cx, 5
    mov di, offset salir_str
    repe cmpsb
    je fin_programa

    call procesar_expresion
    call mostrar_resultado
    call almacenar_historial

    jmp bucle_principal

fin_programa:
    call mostrar_historial

    mov ah, 4Ch
    int 21h
main endp

procesar_expresion proc
    mov si, offset buffer + 2
    xor ax, ax
    mov [resultado], ax
    mov [operador], '+'

procesar_loop:
    call procesar_numero
    mov ax, [num_temp]
    mov bl, [operador]
    
    cmp bl, '+'
    je sumar
    cmp bl, '-'
    je restar
    cmp bl, '*'
    je multiplicar
    cmp bl, '/'
    je dividir

sumar:
    add [resultado], ax
    jmp siguiente_operador

restar:
    sub [resultado], ax
    jmp siguiente_operador

multiplicar:
    mov bx, [resultado]
    imul bx
    mov [resultado], ax
    jmp siguiente_operador

dividir:
    xchg ax, [resultado]
    cwd  ; Extiende AX a DX:AX para division con signo
    idiv word ptr [num_temp]
    mov [resultado], ax

siguiente_operador:
    lodsb
    cmp al, '$'
    je fin_procesar
    mov [operador], al
    jmp procesar_loop

fin_procesar:
    ret
procesar_expresion endp

procesar_numero proc
    xor ax, ax
    mov [num_temp], ax
    mov cx, 1  ; Factor para numero positivo/negativo

    ; Verificar si hay signo negativo
    cmp byte ptr [si], '-'
    jne procesar_digito
    mov cx, -1
    inc si

procesar_digito:
    mov bl, [si]
    cmp bl, '0'
    jl fin_numero
    cmp bl, '9'
    jg fin_numero
    sub bl, '0'
    mov ax, [num_temp]
    imul cx  ; Aplicar signo
    mov dx, 10
    imul dx
    add ax, bx
    mov [num_temp], ax
    inc si
    jmp procesar_digito

fin_numero:
    mov ax, [num_temp]
    imul cx  ; Aplicar signo final
    mov [num_temp], ax
    ret
procesar_numero endp

mostrar_resultado proc
    lea dx, resultado_msg
    mov ah, 09h
    int 21h

    mov ax, [resultado]
    call convertir_a_ascii

    lea dx, nueva_linea
    mov ah, 09h
    int 21h

    ret
mostrar_resultado endp

convertir_a_ascii proc
    mov bx, 10
    xor cx, cx
    test ax, ax
    jns convertir_loop
    neg ax
    push ax
    mov dl, '-'
    mov ah, 02h
    int 21h
    pop ax

convertir_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz convertir_loop

mostrar_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop mostrar_loop

    ret
convertir_a_ascii endp

almacenar_historial proc
    mov si, offset buffer + 2
    mov di, offset historial
buscar_fin:
    cmp byte ptr [di], '$'
    je encontrado_fin
    inc di
    jmp buscar_fin
encontrado_fin:
    mov al, 0Dh
    stosb
    mov al, 0Ah
    stosb
copiar_expresion:
    lodsb
    cmp al, 0Dh
    je fin_copiar
    stosb
    jmp copiar_expresion
fin_copiar:
    mov al, '='
    stosb
    mov ax, [resultado]
    call convertir_a_ascii_historial
    mov al, '$'
    stosb
    ret
almacenar_historial endp

convertir_a_ascii_historial proc
    mov bx, 10
    xor cx, cx
    test ax, ax
    jns convertir_loop_hist
    neg ax
    mov byte ptr [di], '-'
    inc di

convertir_loop_hist:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz convertir_loop_hist

mostrar_loop_hist:
    pop dx
    add dl, '0'
    mov al, dl
    stosb
    loop mostrar_loop_hist

    ret
convertir_a_ascii_historial endp

mostrar_historial proc
    lea dx, historial_msg
    mov ah, 09h
    int 21h

    lea dx, historial
    mov ah, 09h
    int 21h

    ret
mostrar_historial endp

salir_str db 'salir'

end main