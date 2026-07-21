%macro read_stdin 2 
	mov   eax, 3
    mov   ebx, 0
    mov   ecx, %1
    mov   edx, %2
    int   80h
%endmacro

%macro print_str 2 
	mov   eax, 4
    mov   ebx, 1
    mov   edx, %2
    mov   ecx, %1
    int   80h
%endmacro

%macro exit_program 0 
	mov   eax, 1
    xor   ebx, ebx
    int   80h
%endmacro

section .data

	str_welcome1 db 'Welcome to ASMC',0Ah,0Ah,'ASSEMBLY CALCULATOR ',0Ah,0
	str_welcome_len1 equ $ - str_welcome1

	str_input_not_number db 'Invalid input, try again!',0Ah,0
	str_input_not_number_len equ $ - str_input_not_number

	typed_nmbr_msg db 'The number you typed is: ',0
	typed_nmbr_msg_len equ $ - typed_nmbr_msg 


	is_positive db 1
	is_number db 0

	;num_of_conv_vals dd 0
	limit_to_convert db 2

	end_of_str_flag dd 0

	should_sub db 0
	should_add db 0
	should_mul db 0
	should_div db 0	

	TRUE equ 1
	FALSE equ 0

	buffer:    times 201 db 0
	inputed_nums: times 201 dd 0
	
	current_iteration db 0

	;welcome_msg_buffer_len equ (str_welcome_len1 + str_temperature_len + str_energia_len + str_com_qual_len + str_module_status_len) - 6

section .bss

	; 32 bits word to hold eax (converted u_str)
	u_n1 resd 1
	u_n2 resd 1

	counter resb 1
	unit resb 1

	ustr resb 200

section .text

	print_number:

		xor ecx, ecx                
		xor edx, edx
		xor edi, edi
		xor esi, esi
			
    	mov ebx, 10
		mov edi, buffer   		   ; <- load our buffer into ebx
    	                 
		; if the number is positive, then jump to immediately converting it
		cmp eax, 0
		jnl .loop_push_stack

		; if not positive, make it positve as the rest of the code only works with positve integers, then
		; add a '-' at the start of the string, because the number is meant to be negative
		neg eax
		mov [edi], '-'
		inc edi

		.loop_push_stack:

		    xor edx, edx    	   ; clear it after we store it or we blow up
			div ebx    	           ; divide eax by 10
			push edx    		   ; push into the stack the leftover which is in edx	   
			   
			inc ecx    	           ; <- increment the counter
	
			cmp eax, 0    	       ; <- compare the result of the division to 0		
			jne .loop_push_stack    ; <- if its not zero, continue
			
	    mov esi, ecx               ; <- save our counter into a general porpuse register for printing

		mov edx, [is_positive]
		cmp edx, FALSE
		jne .loop_pop_stack
		
		inc esi
		  
		.loop_pop_stack:
		    
			pop edx    			   ; <- pop our data back from the stack
			    
			add edx, '0'           ; <- convert to ascii    
			mov byte [edi], dl     ; <- puts the converted digit into the buffer at the ebx position
			
			inc edi    		       ; <- increment the position of the buffer, (so we put the next converted number there)
			dec ecx                ; <- decrement the loop counter
			
			jne .loop_pop_stack     ; <- checks the zero flag of the instruction before it, if not equal (to zero), continue

		; adds a null terminator at the end	
		inc edi
		mov [edi], 0

		inc esi                    ; <- needed because we can have the additional '-' char at the start, so we need to account for it
	    mov ecx, buffer    		   ; <- move our buffer to ecx so we can print it
	    print_str ecx, esi

	ret


	conv_str_to_int:

		mov edi, [should_sub]
		mov edi, FALSE
		mov [should_sub], edi

		xor ebx, ebx
		xor ecx, ecx
		xor eax, eax
		xor edi, edi

		mov edi, TRUE 
		mov byte [is_positive], 1

		.nextchar: 

			.convert_digit:

				; marks flag as positive
				mov [is_number], FALSE
				xor edi, edi

				.conv_loop:
						
					mov bl, byte [esi]  ; load current char	

					; if that char is a number and it zero, its the null terminator
					cmp bl, 0 ; zero signifies the end of the string
					jne .convert

					xor edi, edi
					mov byte [end_of_str_flag], TRUE
					xor edi, edi
					jmp .end_loop

					.convert:
						
						inc esi

						sub bl, '0'	
						cmp bl, 9
						ja .end_loop

						cmp bl, 0
						jl .end_loop

						; marks flag as positive
						mov byte [is_number], 1
						xor edi, edi
			 				
						;imul eax, eax, 10 multiplies the current value in EAX by 10 and stores the result back in EAX
						imul eax, eax, 10

						; since the converted digit is now in bl (lower portion of ebx)
						; we can add ebx (which only contains the digit to eax) slowly building the stringh
						add eax, ebx				
						jmp .conv_loop

				.end_loop:

					; if not jump ahead and dont store it
					movzx edi, byte [is_number]
					cmp edi, TRUE
					jne .end_store_number


					.store_number:

						; increment the current iteration of the array
						xor edi, edi
						movzx edi, byte [is_positive]
						cmp edi, FALSE
						jne .store
						
					.neg_number:

						cmp eax, 0
						jl .store
						neg eax
						mov byte [is_positive], 1
							
					.store:
					
						; store the number into the array	
						movzx ecx, byte [current_iteration]
						mov [inputed_nums + ecx*4], eax
						xor eax, eax

						; mark it as false now
						movzx edi, byte [is_number]
						mov edi, FALSE
						mov [is_number], dl

						; increase the current iteration
						xor ecx, ecx
						movzx ecx, byte [current_iteration]
						inc ecx
						mov [current_iteration], cl

						; if we should sub the current value with the current one, do it
						movzx edi, byte [should_sub]
						cmp edi, TRUE
						je .sub_previous_and_current
						
					.end_store_number:


					cmp bl, 0 ; zero signifies the end of the string
					je .end_nextchar

					add bl, '0'

					cmp bl, ' '
					je .handle_whitespace

					cmp bl, '-'
					je .negative

			.sub_previous_and_current:

				xor eax, eax
				xor edx, edx				
				xor ecx, ecx
				
				movzx ecx, byte [current_iteration]
				dec ecx
				
				dec ecx
				mov eax, [inputed_nums + ecx*4]

				inc ecx ; go back one unit into the array of converted numbers
				mov edx, [inputed_nums + ecx*4]
			
				; result will now be in eax, which handle_whitespace will put it
				; int the next location
				sub eax, edx

				.store_and_exit:
				
				; store the number into the array	
				movzx ecx, byte [current_iteration]
				mov [inputed_nums + ecx*4], eax
				xor eax, eax
				inc ecx
				mov [current_iteration], cl
											
				; set the flag to false
				xor edi, edi
				mov [should_sub], edi

				xor edi, edi
				mov edi, [end_of_str_flag]
				cmp edi, TRUE
				je .end_nextchar
				
				; return to the main loop
				jmp .nextchar
			
			.handle_whitespace:

				jmp .nextchar			
						
			.negative:

				; marks the is number flag as false
				xor edi, edi
				mov [is_number], edi
				
				cmp byte [esi], ' '
				jne .mark_as_neg


				mov byte [should_sub], TRUE
				jmp .nextchar

				.mark_as_neg:
						
					xor edi, edi
					mov byte [is_positive], 0

					jmp .nextchar	
					 
			.error:
	
				mov edi, -1
				ret 

		.end_nextchar:

			xor ecx, ecx
			movzx ecx, byte [current_iteration]
			dec ecx ; dec due to difference of position x lenght of arrays

			mov eax, [inputed_nums + ecx*4]
			
			xor edi, edi
			ret


	check_u_expression:

		; clear all registers for use
		xor ecx, ecx
		xor eax, eax
		xor ebx, ebx
		xor esi, esi
		xor edi, edi 
		xor edx, edx
					
			.check_number:
						
				; call read and pass our string and lenght	
				read_stdin ustr, 200
				
				; ecx = ptr to buffer (beggining of the string) eax = number of bytes read (doing this equation gives us str lenght)
				mov byte [ecx + eax - 1], 0 ; <- null terminate the ustr by replacing \n with 0

				; mov the user input to esi and call conv_str_to_int
				; to convert it into a number not a string
				mov esi, ustr
				call conv_str_to_int

				; compare conv_str_to_int return value
				mov ebx, -1
				; if edi is not -1, but instead of a converted positive nubmer, goto valid 
				cmp edi, ebx
				jne .valid 
							
				; if not digit, tell user input was not valid, and iterate again
				print_str str_input_not_number, str_input_not_number_len

				jmp .check_number
		
			.valid: 
			
				mov [u_n1], eax										
			
		.end_check_u_expression:
			
			ret

global _start

_start:
	
	print_str str_welcome1, str_welcome_len1
	
	call check_u_expression

	mov eax, [u_n1]
	call print_number

	exit_program
