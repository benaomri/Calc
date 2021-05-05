section .data 
    
    fmt: db "%s",10,0 ; fmt to print
    fmt_int: db "%d",10,0 ; fmt to print
    curr_stack_index: dd 0
    calc_str: dd "calc:",0
    len: dd 0
    numberOfAction: dd 0
    temp_link: dd 0
    link_list_head: dd 0
    stack_size: dd 5
    debug_mode: db 0
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

%macro add_link 1
    pushad
    push 1
    push 5
    call calloc                         ;allocate memory for new link
    add esp, 8                          
    mov dword[temp_link],eax            ;set temp_link pointing to the allocated memory
    mov ebx, 0                          
    mov ebx, [temp_link]                
    mov edi, [link_list_head]           ;set edi as pointer to the head of the prev state of the list
    mov byte[ebx], %1                   ;new_link.data = %1
    mov dword[ebx + 1], edi             ;new_link.next = prev list head
    mov dword[link_list_head], 0        
    mov dword[link_list_head], ebx      ;changing the head of the list to the new link
    popad
%endmacro



main:	
    push ebp
    mov ebp, esp
;Check here for stack size
;Check for debug
;Maybe more

loop_start:
    pushad
    push calc_str               ;represent the string "calc: "
    call printf                 ;printing to usr "calc: "
    add esp,4               
    popad

    ;Input from stdin
    pushad
    push buffer                 ;buffer for reading input 
    call gets                   ;reading input from usr
    add esp,4           
    popad   


;--Check Menu--
    cmp byte [buffer],'p'
    je print_and_pop
    cmp byte [buffer],'d'
    je duplicate
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
    
    jmp loop_start


print_and_pop:
   
    jmp loop_start

duplicate:
    
    jmp loop_start

bitwise:
    
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

