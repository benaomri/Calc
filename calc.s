section .data 
    fmt: db "%s",10,0 ; fmt to print
    fmt_int: db "%d",10,0 ; fmt to print
    curr_index: dd 0
    calc_str: dd "calc:",0
    len: dd 0
    number: dd 0
    debug_mode: db 0
    stack_size: dd 5
section .bss
    stack: resd 5
    buffer: resb 80
  

section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc 
  extern calloc 
  extern free 
  extern gets 
  extern getchar 
  extern fgets 
  extern stdout
  extern stdin
  extern stderr

%macro convert_oct_decimal 2
    mov ecx,%2
    dec ecx
    mov ebx,1
    %%loop1:
        mov eax,0
        mov byte al,[%1+ecx]
        mov byte ah,0
        sub eax,'0'
        mul ebx
        add [number],eax ;add to acc
        cmp ecx,0
        je %%exit
        dec ecx
        shl ebx,3
        jmp %%loop1 
    %%exit:
        push dword [number]
        push fmt_int
        call printf
    %endmacro

%macro convert_dec_oct 1
    mov eax,%1
    mov dword [number],0
    mov ecx,1
    mov ebx,8
    %%loop1:
        check:
        div ebx
        mov edx,eax ;mov the division output
        mul ecx
        add dword [number],eax ; mov the mul output
        mov eax,ecx
        mov ecx,10
        mul ecx
        mov ecx,eax
        cmp eax,0
        jne %%loop1
     %endmacro   



main:	
    push ebp
    mov ebp, esp
;Check here for stack size
;-- Parse Args--



pre_init:
		mov ebx, dword[ebp+8]			;ecx = argc>=1
		dec ebx
		cmp ebx,0                       ;if zero than no farther args
		je finish_init
		mov ecx , dword[ebp+12]			;pointer to pointers of arguments (**)
		mov ecx, [ecx+4]				;pointer of args(*), content of args saperad with /0 [debug, /0, size]
		mov edx, 0
		mov dx, [ecx]


;Check for debug
;Maybe more
finish_init:

loop_start:
    pushad
    push calc_str
    call printf
    add esp,4 
    popad

    ;Input from stdin
    pushad
    push buffer
    call gets
    add esp,4 
    popad


;--Check Menu--
    cmp byte [buffer],'p'
    je p
    cmp byte [buffer],'d'
    je dup
    cmp byte [buffer],'+'
    je plus
    cmp byte [buffer],'&'
    je bitwise
    cmp byte [buffer],'n'
    je n 
    cmp byte [buffer],'q'
    je quit
    jmp push_to_stack


;---------Diffrent Cases-------

plus:
    dec dword[curr_index]
    mov edx, [curr_index]
    mov eax, [stack+edx*4]
    dec dword[curr_index]
    mov edx, [curr_index]
    mov ebx, [stack+edx*4]
    add eax,ebx
    mov [stack+edx*4],eax
    inc dword[curr_index]
    jmp loop_start

p:
;     push stack
;     push fmt
;     call printf
    jmp loop_start

dup:
;     mov eax,[stack-4]
;     mov [stack],eax
    jmp loop_start

bitwise:
;     mov eax, [stack]
;     mov ebx, [stack]
;     and eax,ebx
;     mov [stack],eax
    jmp loop_start

n:

    jmp loop_start
quit:
    dec dword[curr_index]
    mov edx,[curr_index]
    mov eax,dword[stack+edx*4]
    push eax
    push fmt_int
    call printf
    mov esp, ebp
    pop ebp
    ret

push_to_stack:

    ;check for size of stack

 check_len:
    mov ecx, 0	
    mov dword [len],0							; ebx = len of the number					
	loop_len:
		cmp byte[buffer + ecx],0			; check if ecx points to the end of the string = '\n'
		je is_zero							; input = 0
		inc dword [len]
		inc ecx
		jmp loop_len
    is_zero:

    mov dword [number],0
    convert_oct_decimal buffer,[len]
    convert_dec_oct [number]

    ; mov edx, [curr_index]
    ; convert_char buffer
    ; mov eax,dword[buffer]
    ; mov dword[stack+edx*4],eax
    ; inc dword[curr_index]
    jmp loop_start

