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

%macro store_and_exit_fnct 1

	inc ecx  	
	fstp qword [inputed_nums + ecx*8]

	inc ecx 
	mov [current_iteration], ecx
	xor ecx, ecx
											
	; set the flag to false
	xor edi, edi
	mov [%1], edi
	
%endmacro

%macro handle_operands 1

	xor edi, edi
	mov [is_number], edi
				
	cmp byte [esi], ' '
	jne .error

	mov byte [%1], TRUE
	jmp .nextchar			

%endmacro

%macro load_two_numbers 0

	movzx ecx, byte [current_iteration]
	dec ecx

	; load the last 2 numbers in the inputed_nums list
	; in the fpu stack
 	dec ecx
	fld qword [inputed_nums + ecx*8]				
	inc ecx 
	fld qword [inputed_nums + ecx*8]

%endmacro

section .data

	str_welcome1 db 'Welcome to ASMC',0Ah,0Ah,'ASSEMBLY CALCULATOR ',0Ah,0
	str_welcome_len1 equ $ - str_welcome1

	str_input_not_number db 'Invalid input, try again!',0Ah,0
	str_input_not_number_len equ $ - str_input_not_number

	typed_nmbr_msg db 'The number you typed is: ',0
	typed_nmbr_msg_len equ $ - typed_nmbr_msg 




	scale dq 1000.0 ; scale of how many decimal digits to print, 10 = 1, 100 = 2, 1000 = 3
	float_number dq 0.0
	abs_float_number dq 0.0
	temp_fi dq 0
	
	int_part dd 0
	mul_value dd 10
	temp_number dd 0
	decimal_lenght dd 3
	decimal_threshold dd 0.0001
	decimal_scale dd 10



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

	; buffer for print_float
	buffer:    times 201 db 0
	; vector for conv_str_to_int
	inputed_nums: times 201 dq 0
	
	current_iteration db 0

	;welcome_msg_buffer_len equ (str_welcome_len1 + str_temperature_len + str_energia_len + str_com_qual_len + str_module_status_len) - 6

section .bss

	counter resb 1
	unit resb 1

	; where the user prompt will be stored, under check_u_expression
	ustr resb 200

section .text


	print_float:

		; esi =  counter of how many chars the string will have
		; edi = pointer to the buffer where the string will lice

		xor ecx, ecx                
		xor edx, edx
		xor edi, edi
		xor esi, esi

		mov edi, buffer	
		mov dword [temp_number], edx
    
		
		movzx ecx, byte [current_iteration]					
		fld qword [inputed_nums + ecx*8]
		xor ecx, ecx
		
    	                 
		xor edx, edx
		mov [temp_number], edx
		

		.load_int_part:

			fld st0
			fisttp dword [int_part] ; store the trucated integer part (st0)
			fild dword [int_part] ; load it back
			fsubp st1, st0
			
			xor eax, eax
			xor edx, edx

			mov eax, dword [int_part]

			mov ebx, 10
			xor ecx, ecx

			cmp eax, 0
			jnl .loop_convert_int

		.negate_value:

			fabs  ; makes the decimal part positive
			neg eax ; negates the interger part, so it becomes negative
			mov [edi], '-'
			inc edi
			inc esi
			
		.loop_convert_int:

		    xor edx, edx ; clear it after we store it or we blow up
			div ebx ; div ebx by eax
			
			add edx, '0'     	           
			push edx 
			inc ecx 
			
			cmp eax, 0    	         ; <- compare the result of the division to 0		
			jne .loop_convert_int    ; <- if its not zero, continue

		.loop_str_int_part:

			pop edx
			inc esi
			mov [edi], edx
			inc edi
					
			dec ecx

			cmp ecx, 0
			jne .loop_str_int_part
			
		.add_period:

			xor edx, edx
			mov edx, '.'

			inc edi
			mov [edi], edx
			inc esi

			xor ebx, ebx
				
		.loop_convert_fraction:

			fild dword [mul_value] ; mul value = 10 
			fmulp st1, st0
			fld st0 
			fisttp dword [temp_number]
			fild dword [temp_number]
			
			mov edx, dword [temp_number]
			add edx, '0'

			inc edi
			mov [edi], edx
			inc esi

		
			xor edx, edx
			mov [temp_number], edx

			inc ebx
			cmp ebx, 2
			ja .add_null_terminator
						
			fsubp st1, st0
			fabs
			
			fld dword [decimal_threshold]
			fcomip st0, st1
			jb .loop_convert_fraction

		.add_null_terminator:
		
			inc edi
			inc esi
			mov [edi], 0 ; 0 is the actual null terminator
			
		.print_buffer:
	 
	    	print_str buffer, esi

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

						cmp bl, '.'
						je .handle_fractional

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
						
					.handle_fractional:

						xor ebx, ebx
						mov bl, byte [esi]
						inc esi

						cmp bl, 0
						je .end_loop

						sub bl, '0'
						
						cmp bl, 9
						ja .end_loop
								
						mov dword [temp_number], ebx

						fild dword [temp_number]
						fild dword [decimal_scale]
						fdivp ; divides the two above
						
						fld qword [float_number] 
						faddp 
						fstp qword [float_number]

						xor edi, edi
						mov edi, [decimal_scale]
						imul edi, 10
						mov [decimal_scale], edi

						jmp .handle_fractional	
			
				.end_loop:

					; if not jump ahead and dont store it
					movzx edi, byte [is_number]
					cmp edi, TRUE
					jne .end_store_number

					; reset decimal scale back to 10
					mov edi, 10
					mov dword [decimal_scale], edi
					
				.store_number:

						; store the number into the array	
						mov dword [int_part], eax
						xor eax, eax
						
						fld qword [float_number]
						fild dword [int_part]

						faddp ; pops int part

					.should_negate:
						
						xor edi, edi
						movzx edi, byte [is_positive]
						cmp edi, FALSE
						jne .store_and_continue

					.negate:
						
						fchs ; negates it if it should negative
						
					.store_and_continue:
						
						movzx ecx, byte [current_iteration]					
						fstp qword [inputed_nums + ecx*8]

						; mark it as false now
						movzx edi, byte [is_number]
						mov edi, FALSE
						mov [is_number], dl

						; increase the current iteration
						xor ecx, ecx
						movzx ecx, byte [current_iteration]
						inc ecx
						mov [current_iteration], ecx

						; if we should sub the current value with the current one, do it
						movzx edi, byte [should_sub]
						cmp edi, TRUE
						je .sub_previous_and_current

						movzx edi, byte [should_add]
						cmp edi, TRUE
						je .add_previous_and_current

						movzx edi, byte [should_mul]
						cmp edi, TRUE
						je .mul_previous_and_current

						movzx edi, byte [should_div]
						cmp edi, TRUE
						je .div_previous_and_current						
											
				.end_store_number:

					xor edi, edi
					mov [int_part], edi

					; have to clear it one 32 bit register at a time
					mov [float_number], edi
					mov [float_number+4], edi

					cmp bl, 0 ; zero signifies the end of the string
					je .end_nextchar

					add bl, '0'

					cmp bl, ' '
					je .handle_whitespace

					cmp bl, '-'
					je .negative

					cmp bl, '+'
					je .positive

					cmp bl, '*'
					je .multiply

					cmp bl, '/'
					je .divide

			.div_previous_and_current:
				
				load_two_numbers
								
				; add the two and pop the most recent one
				fdivp st1, st0

				store_and_exit_fnct should_add

				xor edi, edi
				mov edi, [end_of_str_flag]
				cmp edi, TRUE
				je .end_nextchar
				
				; return to the main loop
				jmp .nextchar			


			.mul_previous_and_current:
			
				load_two_numbers
				
				; add the two and pop the most recent one
				fmulp st1, st0

				store_and_exit_fnct should_add

				xor edi, edi
				mov edi, [end_of_str_flag]
				cmp edi, TRUE
				je .end_nextchar
				
				; return to the main loop
				jmp .nextchar			


			.add_previous_and_current:
			
				load_two_numbers
								
				; add the two and pop the most recent one
				faddp st1, st0

				store_and_exit_fnct should_add

				xor edi, edi
				mov edi, [end_of_str_flag]
				cmp edi, TRUE
				je .end_nextchar
				
				; return to the main loop
				jmp .nextchar			
				
			.sub_previous_and_current:
				
				load_two_numbers
				
				; subract the two and pop the most recent one
				fsubp st1, st0
				
				store_and_exit_fnct should_sub

				xor edi, edi
				mov edi, [end_of_str_flag]
				cmp edi, TRUE
				je .end_nextchar
				
				; return to the main loop
				jmp .nextchar

			.handle_whitespace:

			jmp .nextchar			

			.divide:

			handle_operands should_div

			.multiply:

			handle_operands should_mul
		
			.positive:
		
			handle_operands should_add
										
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
			mov [current_iteration], ecx
			ret


	check_u_expression:

		xor eax, eax
		xor ecx, ecx
			
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
			
			ret									

global _start

_start:
	
	print_str str_welcome1, str_welcome_len1
	
	call check_u_expression
	call print_float

	exit_program
