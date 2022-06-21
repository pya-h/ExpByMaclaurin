data segment
    ; add your data here!
    msg_enter_n db "Please enter n = ? $"
    n dw 0
    integer_part dw 0
    floating_part dw 0
    output_number dw 0
    ; temporary words defined for macloren calculations
    numerator dw 0 ; numerator of each term
    denominator dw 0 ; denominator of each term
    PRECISION EQU 100D ; meaning 2 floating points
    MAX_TERMS EQU 04H ; number of macloren series terms
    msg_exp_n db 0dh, 0ah, "exp(n) = $"
ends

stack segment
    dw   128  dup(0)
ends

code segment
start:
; set segment registers:
    mov ax, data
    mov ds, ax
    mov es, ax
    
    main proc far
        mov dx, offset msg_enter_n
        mov ah, 9
        int 21h        ; output string at ds:dx

        CHECK_KEYBOARD: 
            mov ah, 01h
            int 16h
        jz CHECK_KEYBOARD
        ; if a key has been pressed
        mov ah, 00h
        int 16h ; get the pressed key ascii value

        ; first: we type the entered character
        mov dx, ax ; copy al to dl for copying, dh will be 0
        mov ah, 02h ; dos function for printing characters in 21h
        int 21h

        sub al, '0' ; convert pressed key to a digit
        mov ah, 0
        mov n, ax ; copy digit into a word named n

        call macloren ; run macloren series and put the result in integer_part & floating_part words (integer.floating)
        ; e^n has been calculated into two parts: integer & floating
        ; now we print each part seperately

        mov dx, offset msg_exp_n
        mov ah, 9
        int 21h        ; output string at ds:dx

        ; print the number
        mov ax, integer_part
        mov output_number, ax ; memory to memory mov is not allowed so we used the ax regiuster as the bridge between these two
        ; output_number is the parameter for print_number function
        call print_number
        
        mov dx, 002eh ; copy the ascii code of . (dot) to dx for printing between integer_part and floating_part
        mov ah, 02h ; dos function for printing characters in 21h
        int 21h

        ; now we print the floating part here
        mov ax, floating_part
        mov output_number, ax
        call print_number

        mov ax, 4c00h ; return to DOS
        int 21h  
    endp

    macloren proc
        mov cx, 0001h ; cx is the counter register in the main loop
        mov integer_part, 0001h ; first term of macloren
        mov numerator, 0001h
        mov denominator, 0001h
        ; loop below is for second to forth terms of macloren series
        MAIN_LOOP: ; loop with counter cx > 0
            ; term 'cx': calculate the term's denominator
            mov ax, denominator
            mul cx ; cx! == factoriel(cx)
            mov denominator, ax ; copy the result into denumerator again ( for next term )

            ; term 'cx': calculate the term's numerator
            mov ax, numerator
            mov si, n
            mul si ; n ^ cx
            mov numerator, ax; copy the result into numerator again ( for next term )

            ; now we devide numerator on denominator
            mov si, denominator
            div si ; div ax/si === numerator / denominator
            ; ax is the integer part of division
            add integer_part, ax ; add the final result of this term calculation -> to word:integer_part
            ; dx is the remainder
            ; for calculating floating_part we use this formula:
            ; term_floating_part = remainder * PRECISION / cx! = dx * 100 / denominator
            mov ax, dx
            mov bx, PRECISION
            mul bx ; ax = dx * 100
            ; now divide ax by denominator=si
            div si
            add floating_part, ax

            ; in the operation floating point may become grater than (100) like: 0.5 + 0.5 = 1.00
            ; in that case we substract PRECISION from floating_part and add 1 to integer_part
            mov ax, floating_part
            cmp ax, PRECISION
            jl NEXT_TERM ; if floating_part < PRECISION => its ok
            ; if floating_part >= PRECISION
            sub ax, PRECISION
            mov floating_part, ax ; floating_part -= PRECISION
            INC integer_part ; increment integer_part

            NEXT_TERM:
                inc cx
                cmp cx, MAX_TERMS
            jne MAIN_LOOP
        ret
    endp

    print_number proc
        ; offset address must be in si
        mov ax, output_number
        
        mov bx, 00ffh ; last digit address
        mov di, bx; 
        mov [bx], '$' ;end of the string

        mov cx, 0
        mov dx, 0
       
        EXTRACT_DIGITS: 	
            mov si, 10d
            mov dx, 0
            div si
            mov dh, 0
            add dl, '0'
            dec di
            mov [di], dl
            
            cmp ax, 0000h
            jne EXTRACT_DIGITS

        ; now print it via 2109
        mov dx, di ;offset number string

        mov ah, 09h
        int 21h
        ret
    endp
ends

end start ; set entry point and stop the assembler.
