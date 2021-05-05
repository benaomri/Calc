section	.rodata						; we define (global) read-only variables in .rodata section
	calc_string : 		db "calc: ", 0
	;printHex_string : 	db "%X",0
	printHex_string : 	db "%02X",0
	print_new_line:		db "",10, 0
	format_string: 		db "%s",10
	error_msg_args : 	db "Error: Insufficient Number of Arguments on Stack", 10, 0 
	error_msg_overflow: db "Error: Operand Stack Overflow" , 10, 0
	debug_mode_print: 	db "Debug mode: ", 0

section .data
	debug_flag: 	dd 0					;debug mode
	count_op: 	 	dd 0					;count number of operations
	carryAdd: 	 	dd 0
	size_stack:  	dd 5					;defult size of stack
	curr_link: 		dd 0					; last added link
	first_index:    dd 0					; points to the first char in the input that is not '0'
	tmp_link:		dd 0
	count_dig: 		dd 0
	count_push:		dd 0


section .text
	align 16
	global main
	;global calculator1
	extern printf
	extern fprintf 
	extern fflush
	extern malloc 
	extern calloc 
	extern free 
	extern gets 
	extern getchar 
	extern fgets
	extern stderr 

section .bss				; we define (global) uninitialized variables in .bss section
	node: 			resb 5
	buffer: 		resb 80
	;an: 			resb 12
	count_stack: 	resb 12
	stack : 	 	resb 255

section .text
%macro convertByte 1		; change ascii %1 to its hex true value
	sub %1 ,48				; change %1 to its true value
    cmp %1, 10				; if curr is a letter - sub 7
	jl %%end
	sub %1,7
	%%end:
%endmacro

%macro allocate 3 		; allocates space for %2 elements , each with %1 storage space , allocated for %3
	pushad
	push %1				;each link is %1 bytes
	push %2				;allocate %2 links
	call calloc
	mov %3, eax			; calloc returns pointer to eax (%3 points to the new allocated space)
	add esp, 8
	popad
%endmacro

%macro clean_buff 2		; initialize %1 with %2 0's
	pushad
	mov edx, 0
	%%initialize:
		mov byte[%1 + edx], 0
		inc edx
		cmp edx, %2
		jne %%initialize 
	popad
%endmacro

%macro add_new_link 1	; adds new link to the list representing the added numebr to the stack
						; the new link had the value %1 and will point to the current link
	pushad
	push 1
	push 5
	call calloc			; allocate storage for the new link [data: 1 byte, ptr: 4 byte] , ptr -> [curr_link]  
	add esp, 8
	mov dword[tmp_link], eax
	popad

	pushad
	mov ecx, 0
	mov ecx, [tmp_link]
	mov byte[ecx], %1			; node.data = %1
	mov edi, [curr_link]			; edi points to the head of the list
	mov dword[ecx + 1], edi 	; node.next = edi
	mov dword[curr_link],0
	mov dword[curr_link], ecx	; the new link is now the head of the list

	popad
%endmacro

%macro pop_list 0
	pushad

	mov dword[tmp_link], 0			;  reset the tmp_link - tmp_link will hold the poped number
	mov ecx,0
	mov cl, [count_stack]			
	dec ecx							; ecx now points to the last added number
	
	mov edx, [stack + ecx*4]		; edx is now the pointer to the list
	mov dword[tmp_link], edx		
	popad
%endmacro

%macro print_list 1					; %1 is the register that stores the poped list
	pushad
	mov ecx, 0						; ecx will hold the curr			
	mov ecx , %1
	mov ebx, 0
	mov byte[count_dig], 0			; count of bytes in the number
	%%loop_push:
		mov bl, byte[ecx]				; push to the mem stack the current
		push ebx
		push printHex_string    	; print in hexa format 
		inc byte[count_dig]						
		mov ecx, dword[ecx+1]
		cmp ecx, 0					; if the next link is null, go to loop_print	
		jne %%loop_push
	%%loop_print:
		dec byte[count_dig]
		call printf
		add esp, 8				; clean up stack after call
		cmp byte[count_dig],0
		jne %%loop_print

	push print_new_line
	call printf
	add esp, 4
	popad
%endmacro

%macro delete_list 1				; %1 is the list we want to delete 
	pushad
	mov ecx, 0
	mov eax, %1

	%%loop_delete:
		cmp eax, 0
		je %%end_delete
		mov ecx, [eax + 1]
		
		pushad
		push eax					; push curr link to the free func.
		call free
		add esp, 4
		popad
		
		mov eax, ecx				; else - ecx = curr.next 
		jmp %%loop_delete
	%%end_delete:
	popad
%endmacro

%macro getArgs 1 					; %1 is the argument
	pushad
	mov eax, 0
	mov eax, %1 
	cmp eax, '0'
	jl %%is_debug						; args is "-d" or a number - "-" in ascii = 45 
	
	%%is_size:
		mov dword[size_stack], eax
		jmp %%finish_args		
	%%is_debug:
		mov byte[debug_flag], 1

	%%finish_args:
	popad
%endmacro

%macro debug_print 1				; %1 is the number read from the user or the result of the command
	pushad
	mov ecx, 0						; ecx will hold the curr			
	mov ecx , %1
	mov ebx, 0
	mov byte[count_dig], 0			; count of bytes in the number
	
	pushad
	push debug_mode_print
	push dword[stderr]
	call fprintf
	add esp, 8
	popad

	%%loop_push_debug:
		
		mov bl, byte[ecx]				; push to the mem stack the current
		push ebx
		push printHex_string    		; print in hexa format 
		push dword[stderr]						; stderr
		inc byte[count_dig]						
		mov ecx, dword[ecx+1]
		cmp ecx, 0						; if the next link is null, go to loop_print	
		jne %%loop_push_debug
	
	%%loop_print_debug:
		dec byte[count_dig]
    	call    fprintf 			;print to stderr
		add esp, 12					; clean up stack after call
		cmp byte[count_dig],0
		jne %%loop_print_debug

	push print_new_line
	push dword[stderr]
	call fprintf
	add esp, 8
	popad

%endmacro

%macro convertNumArg 0		; We assume that we always work on edx
	convertByte dh
	cmp dl, 0
	je %%singel
	convertByte dl
	shl dh, 4
	or dl, dh
	xor dh, dh
	jmp %%end_macro
	%%singel:
	shr edx, 8
	%%end_macro:
%endmacro
;========================= begining of the program =========================
main:
	push ebp
	mov ebp, esp	
	

	pre_init:
		mov ebx, dword[ebp+8]			;ecx = argc
		dec ebx
		cmp ebx,0
		je init
		mov ecx , dword[ebp+12]			;pointer to pointers of arguments (**)
		mov ecx, [ecx+4]				;pointer of args(*), content of args saperad with /0 [debug, /0, size]
		mov edx, 0
		mov dx, [ecx]					;get first argument

		parse_first:
			cmp dl, '-'
			jne set_stack_size						; args is "-d" or a number - "-" in ascii = 45 
			mov byte[debug_flag], 1
			dec ebx

		parse_second:
			cmp ebx, 0
			je init
			mov edx, 0 
			cmp byte[ecx+1], 0			
			je arg_2_offset				;if first arg hold 2 byte (1 digit of size + /0) 
			add ecx, 3					;get second argument
			jmp continue_parsing
			arg_2_offset:
				add ecx, 2	
			
			continue_parsing:
			cmp byte [ecx], '-'
			jne set_stack_size					; args is "-d" or a number - "-" in ascii = 45 
			mov byte[debug_flag], 1
			jmp init

			set_stack_size:
				mov dword[size_stack], 0 
				dec ebx
				;jle singal_digit_second
				mov dx, [ecx]
				convertNumArg
				mov dword [size_stack], edx
				;mov byte[size_stack], dh
				;cmp dl, 0
				;je init	
				;mov eax, [size_stack]
				;shl eax,4
				;mov [size_stack], eax			
				;singal_digit_second:
					;convertByte dl
					;add [size_stack], dl
				jmp parse_second			
			

	init:
		mov dword[count_stack],0
		clean_buff stack, size_stack*4
		mov eax,0
		mov dword[count_op],0
		jmp calc_loop


	calc_loop:
		clean_buff buffer, 80			; initialize input - buffer with zeros before receiving an input
		mov dword[curr_link], 0
		mov byte[first_index],0
		mov dword[tmp_link], 0

		input:
			pushad
			push calc_string		; print calc: to user to get input
			call printf
			add esp, 4				; clean up stack after call
			popad

		read_command:
			pushad
			push buffer
			call gets
			add esp, 4
			popad

		;options:

		cmp byte[buffer], 'q'
		je quit
		cmp byte[buffer], '+'
		je sum
		cmp byte[buffer], 'p'
		je p_and_p
		cmp byte[buffer], 'd'
		je dupli
		cmp byte[buffer], '&'
		je bit_and
		cmp byte[buffer], '|'
		je bit_or
		cmp byte[buffer], 'n'
		je num_hex
		jmp add_to_stack					;else: input num to add the stack


	; ========== Quit ===========
	quit:
		loop_quit:
			cmp dword[count_stack],0
			je finish
			pop_list
			mov eax, dword[tmp_link]
			delete_list eax
			mov dl, byte[count_stack]
			dec dl
			mov dword[stack + edx*4] , 0		; clean the stack's pointer to the deleted list
			dec byte[count_stack]
			jmp loop_quit

	; =========== Sum ===========
	sum:
		inc dword[count_op]
		cmp byte[count_stack], 2				;check for Insufficient number of arguments
		jl error_args
		
		mov dword[tmp_link],0				; tmp_link will be the final result
		mov eax,0							; first node
		mov ebx,0							; second node
		mov ecx, 0							; first byte to add
		mov edx, 0							; second byte to add
		mov byte[count_dig], 0
		mov byte[carryAdd], 0

		pop_list							; tmp_link = first 
		mov eax, dword[tmp_link]
		dec byte[count_stack]
		pop_list							; tmp_link = first 
		mov ebx, dword[tmp_link]
		
		pushad								; backup the heads of the lists we want to add

		add_bytes_loop:
			mov cl, byte[eax]				; cl = byte of the first numebr
			mov dl, byte[ebx]				; dl = byte of second number
			add cx, dx						; cl = sum of dl and cl
			add cx, [carryAdd]
			mov byte[carryAdd], ch			; if the CF of cx + dx = 1 -> ch = 1 
			push ecx							; push the sum to the mem stack - 1 byte
			inc byte[count_dig]				
			mov eax, [eax + 1]
			mov ebx, [ebx + 1]
			cmp eax, 0						; if the first number ended
			je first_is_null
			cmp ebx, 0						; if the second number ended
			je sec_is_null
			jmp add_bytes_loop

		first_is_null:					; iterate over the second number until it ends and sum it with the carry
			cmp ebx, 0							
			je check_carry
			mov dl, byte[ebx]
			add dx, [carryAdd]
			mov byte[carryAdd], dh
			push 0x01
			inc byte[count_dig]
			mov ebx, [ebx + 1]
			jmp first_is_null

		sec_is_null:
			cmp eax, 0				
			je check_carry
			mov cl, byte[eax]
			add cx, [carryAdd]


			mov byte[carryAdd], ch
			push ecx
			inc byte[count_dig]
			mov eax, [eax + 1]
			jmp sec_is_null

		check_carry:
			cmp byte[carryAdd], 1				; we will add the carry flag if its on
			jne create_res_link
			push 0x01
			inc byte[count_dig]				;TODO: check inc byte[]

		create_res_link:
			cmp byte[count_dig], 0			; if we poped all of the res digits -> jmp to add to stack		
			je continue
			pop eax							; eax = curr byte
			add_new_link al
			dec byte[count_dig]
			jmp create_res_link

		
		continue:
			popad

			delete_list eax						; delete the list
			delete_list ebx

			mov dl, byte[count_stack]			; edx = pointer to the head of the stack

			mov dword[stack + edx*4],0			; clean the stack - in the indices of the deleted lists
			dec edx
			mov dword[stack + edx*4],0


		push_res:
			mov eax, 0
			mov eax, [curr_link]				; eax = sumed number
			mov dword[stack + edx*4], eax		; push new linked list to the stack
			inc edx
			mov byte[count_stack], dl


		cmp byte[debug_flag], 1
		jne calc_loop

		pop_list							; tmp_link = first 
		mov eax, dword[tmp_link]
		debug_print eax


		jmp calc_loop

	; ====== Pop-and-print =======
	p_and_p:
		cmp dword[count_stack], 0
		je error_args
		pop_list							; tmp_link = first 
		mov eax, dword[tmp_link]
		print_list eax
		delete_list eax
		mov dl, byte[count_stack]
		mov dword[stack + edx*4] , 0		; clean the stack's pointer to the deleted list
		dec byte[count_stack]
		inc dword[count_op]
		jmp calc_loop

	; ========= Duplicate =========
	
	dupli:
		mov ecx,0
		mov ecx, dword[size_stack]
		cmp dword[count_stack], ecx				; if the stack is full
		je error_overflow

		pop_list								; tmp_link = first 
		mov ecx, dword[tmp_link]
		mov eax, 0
		mov dword[curr_link], 0
		mov byte[count_dig], 0					; count of bytes in the number
	
		take_data:
			mov al, byte[ecx]					; push to the mem stack the current
			push eax
			inc byte[count_dig]						
			mov ecx, dword[ecx+1]
			cmp ecx, 0							; if the next link is null, go to loop_print	
			jne take_data
		
		dup_list:
			pop eax								; node.data
			add_new_link al						; add the data to the duplicated new list
			dec byte[count_dig]
			cmp byte[count_dig],0
			jne dup_list

		mov edx,0
		mov dl, [count_stack]
		mov ecx, 0
		mov ecx, [curr_link]
		mov dword[stack + edx*4], ecx		; push new linked list to the stack
		
		inc byte[count_stack]					; stack points to the next number
		inc dword[count_op]
		
		cmp byte[debug_flag], 1
		jne calc_loop

		pop_list							; tmp_link = first 
		mov eax, dword[tmp_link]
		debug_print eax
		
		
		jmp calc_loop

	; ======== Bitwise AND ========
	bit_and:
	
		inc dword[count_op]
		cmp byte[count_stack], 2				;check for Insufficient number of arguments
		jl error_args
		
		mov dword[tmp_link],0				; tmp_link will be the final result
		mov eax,0							; first node
		mov ebx,0							; second node
		mov ecx, 0							; first byte to add
		mov edx, 0							; second byte to add
		mov byte[count_dig], 0

		pop_list							; tmp_link = first 
		mov eax, dword[tmp_link]
		dec byte[count_stack]
		pop_list							; tmp_link = first 
		mov ebx, dword[tmp_link]
		
		pushad								; backup the heads of the lists we want to add

		and_bytes_loop:
			mov cl, byte[eax]				; cl = byte of the first numebr
			mov dl, byte[ebx]				; dl = byte of second number
			and cx, dx						; cl = sum of dl and cl
			push ecx							; push the sum to the mem stack - 1 byte
			inc byte[count_dig]				
			mov eax, [eax + 1]
			mov ebx, [ebx + 1]
			cmp eax, 0						; if the first number ended
			je create_and_link
			cmp ebx, 0						; if the second number ended
			je create_and_link
			jmp and_bytes_loop

		create_and_link:
			cmp byte[count_dig], 0			; if we poped all of the res digits -> jmp to add to stack		
			je continue_and
			pop eax							; eax = curr byte
			add_new_link al
			dec byte[count_dig]
			jmp create_and_link
		
		continue_and:
			popad
			delete_list eax						; delete the list
			delete_list ebx
			mov dl, byte[count_stack]			; edx = pointer to the head of the stack
			mov dword[stack + edx*4],0			; clean the stack - in the indices of the deleted lists
			dec edx
			mov dword[stack + edx*4],0

		push_and:
			mov eax, 0
			mov eax, [curr_link]				; eax = sumed number
			mov dword[stack + edx*4], eax		; push new linked list to the stack
			inc edx
			mov byte[count_stack], dl

		cmp byte[debug_flag], 1
		jne calc_loop

		pop_list							; tmp_link = first 
		mov eax, dword[tmp_link]
		debug_print eax


		jmp calc_loop

	; ======== Bitwise OR =========
	bit_or:
		inc dword[count_op]
		cmp byte[count_stack], 2				;check for Insufficient number of arguments
		jl error_args
		
		mov dword[tmp_link],0				; tmp_link will be the final result
		mov eax,0							; first node
		mov ebx,0							; second node
		mov ecx, 0							; first byte to add
		mov edx, 0							; second byte to add
		mov byte[count_dig], 0

		pop_list							; tmp_link = first 
		mov eax, dword[tmp_link]
		dec byte[count_stack]
		pop_list							; tmp_link = first 
		mov ebx, dword[tmp_link]
		
		pushad								; backup the heads of the lists we want to add

		or_bytes_loop:
			mov cl, byte[eax]				; cl = byte of the first numebr
			mov dl, byte[ebx]				; dl = byte of second number
			or cx, dx						; cl = sum of dl and cl
			push ecx							; push the sum to the mem stack - 1 byte
			inc byte[count_dig]				
			mov eax, [eax + 1]
			mov ebx, [ebx + 1]
			cmp eax, 0						; if the first number ended
			je chain_second
			cmp ebx, 0						; if the second number ended
			je chain_first
			jmp or_bytes_loop

		chain_second:
			cmp ebx, 0						; if the second number ended
			je create_or_link
			mov dl, byte[ebx]				; dl = byte of second number
			push edx							; push the sum to the mem stack - 1 byte
			inc byte[count_dig]				
			mov ebx, [ebx + 1]
			jmp chain_second

		chain_first:
			cmp eax, 0						; if the first number ended
			je create_or_link
			mov cl, byte[eax]				; cl = byte of the first numebr
			push ecx							; push the sum to the mem stack - 1 byte
			inc byte[count_dig]				
			mov eax, [eax + 1]
			jmp chain_first

		create_or_link:
			cmp byte[count_dig], 0			; if we poped all of the res digits -> jmp to add to stack		
			je continue_or
			pop eax							; eax = curr byte
			add_new_link al
			dec byte[count_dig]
			jmp create_or_link
		
		continue_or:
			popad
			delete_list eax						; delete the list
			delete_list ebx
			mov dl, byte[count_stack]			; edx = pointer to the head of the stack
			mov dword[stack + edx*4],0			; clean the stack - in the indices of the deleted lists
			dec edx
			mov dword[stack + edx*4],0

		push_or:
			mov eax, 0
			mov eax, [curr_link]				; eax = sumed number
			mov dword[stack + edx*4], eax		; push new linked list to the stack
			inc edx
			mov byte[count_stack], dl

		cmp byte[debug_flag], 1
		jne calc_loop

		pop_list									; tmp_link = first 
		mov eax, dword[tmp_link]
		debug_print eax

		jmp calc_loop

	; ==== Number of hex digits ====
	num_hex:
		inc dword[count_op]
		cmp byte[count_stack], 1					;check for Insufficient number of arguments
		jl error_args
		
		mov dword[tmp_link],0						; tmp_link will be the final result
		mov eax,0									; first node
		mov byte[count_dig], 0

		pop_list									; tmp_link = first 
		mov eax, dword[tmp_link]
		mov ebx,0									; second node
		mov ecx,0 
		pushad

		count_num_dig:
			mov cl, byte[eax]
			mov eax, [eax + 1]				; eax = eax.next
			cmp eax, 0						; finish the iteration
			je push_hex
			add byte[count_dig],2
			mov ecx, 0
			jmp count_num_dig

		push_hex:
			
			cmp ecx, 16
			jl pre
			inc byte[count_dig]
			pre:
				inc byte[count_dig]
				mov eax, 0							;  num \ 100
				mov edx, 0							;  num % 100
				mov eax, [count_dig]				;  eax = remaind num
				mov ecx, 100
				mov dword[count_push],0

		loop_hex:
			cmp eax, 0						; finish loop
			je create_dig_list
			inc byte[count_push]
			div ecx							; eax = eax \ 100 , edx = eax % 100
			push edx
			jmp loop_hex

		create_dig_list:
			cmp byte[count_push], 0					; if we poped all of the res digits -> jmp to add to stack		
			je continue_dig
			pop eax									; eax = curr byte
			add_new_link al
			dec byte[count_push]
			jmp create_dig_list

		continue_dig:
			popad
			delete_list eax							; delete the list
			dec byte[count_stack]
			mov dl, byte[count_stack]				; edx = pointer to the head of the stack
			mov dword[stack + edx*4],0				; clean the stack - in the indices of the deleted lists
			mov eax, 0
			mov eax, [curr_link]					; eax = sumed number
			mov dword[stack + edx*4], eax			; push new linked list to the stack
			inc byte[count_stack]
			
			cmp byte[debug_flag], 1
			jne calc_loop

			pop_list								; tmp_link = first 
			mov eax, dword[tmp_link]
			debug_print eax
			
			jmp calc_loop

	; ===== Add new number to stack =====

	add_to_stack:
		mov ecx,0
		mov ecx, dword[size_stack]
		cmp dword[count_stack], ecx					; if the stack is full
		je error_overflow

		mov dword[first_index], 0					; initialize the first char to be in index 0
		
		
		mov ecx,0									; ecx = first non zero index

		clean_leading_zeros:
			cmp byte[buffer + ecx], 0
			je get_len
			cmp byte[buffer + ecx], '0'
			jne get_len
			inc ecx
			jmp clean_leading_zeros

		get_len:
			mov ebx, 0								; ebx = len of the number
			mov dword[first_index], ecx 					
			loop_len:
				cmp byte[buffer + ecx],0			; check if ecx points to the end of the string = '\n'
				je is_zero							; input = 0
				inc ebx
				inc ecx
				jmp loop_len
		
		is_zero:
			;mov dword[str_len], ebx	
			cmp ebx ,0								; if input = 0 create a single link with 0
			jne is_odd
			inc ebx
			dec byte[first_index]
		
		is_odd:
			mov edx, 0
			mov edx, dword[first_index]				; edx points to the first char of the number
			mov eax, 0
			mov eax, ebx							; eax = len
			and eax, 1								; if and eax,1  = 1 -> len is odd
			cmp al,1
			jne loop_num

		odd_len:
			mov al, 48								; padding with 0 for an odd len number
			mov bl, byte[buffer + edx] 				; get second char 
			dec edx									; dec 1 for the extra 0 added				
			jmp create_num_list

		loop_num: 
			mov ebx, 0
			mov al, byte[buffer + edx] 				; get first char for the next node
			cmp eax, 0								; end of string
			je push_to_stack
			mov bl, byte[buffer + edx + 1]  		; get second char for the next node
			
		create_num_list:
			convertByte eax							; convert eax to its true hex value
			shl al,4								; make space for the second char
			convertByte ebx							; convert eax to its true hex value
			add al,bl								; megre the digits
			add_new_link al							; link the new 2 digits to the rest of the number
			add edx, 2								; move first_index to point to the next two digits
			jmp loop_num

		push_to_stack:
			mov edx,0
			mov dl, [count_stack]
			mov eax, 0
			mov eax, [curr_link]
			mov dword[stack + edx*4], eax		; push new linked list to the stack
			
		inc byte[count_stack]					; stack points to the next number
		
		cmp byte[debug_flag], 1
		jne calc_loop

		pop_list								; tmp_link = first 
		mov eax, dword[tmp_link]
		debug_print eax
		
		jmp calc_loop
	
	error_args:
		pushad
		push error_msg_args
		call printf
		add esp,4
		popad
		jmp calc_loop

	error_overflow:
		pushad
		push error_msg_overflow
		call printf
		add esp,4
		popad
		jmp calc_loop

	finish:
		pushad
		push dword[count_op]			; print num of op calls  
		push printHex_string    ; print in hexa format
		call printf
		add esp, 8				; clean up stack after call
		popad
		
		pushad
		push print_new_line    ; print in hexa format
		call printf
		add esp, 4				; clean up stack after call
		popad

	mov esp, ebp	
	pop ebp
	ret