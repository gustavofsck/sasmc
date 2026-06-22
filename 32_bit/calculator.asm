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

	test_msg db 'TEST MESSAGE, TEST MESSAGE!!!!!!!',0Ah,0
	test_msg_len equ $ - test_msg 

	
	;negative_msg db 'NEGATIVE NUMBER DETECTED!!!!!!!',0Ah,0
	;negative_msg_len equ $ - negative_msg 

	is_positive db 1

	my_number db 120

	TRUE equ 1
	FALSE equ 0

	buffer:    times 201 db 0

	;welcome_msg_buffer_len equ (str_welcome_len1 + str_temperature_len + str_energia_len + str_com_qual_len + str_module_status_len) - 6

section .bss

	; 32 bits word to hold eax (converted u_str)
	u_n1 resd 1
	u_n2 resd 1

	counter resb 1
	unit resb 1

	ustr resb 200

	;welcome_msg_buffer resb welcome_msg_buffer_len

section .text

	print_number:

		xor ecx, ecx                
		xor edx, edx
		xor edi, edi
		xor esi, esi
			
    	mov ebx, 10
		mov edi, buffer   		   ; <- load our buffer into ebx
    	                 
		; if the number is positive, then jump to immediately converting it
		mov esi, [is_positive]
		cmp esi, FALSE
		jne .loop_push_stack

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

		xor ebx, ebx
		xor ecx, ecx
		xor eax, eax
		xor edi, edi

		mov edi, TRUE 
		mov [is_positive], edi

		.nextchar: ; loop for going char by char until we find the end of the string

			; the whole string is in esi, a single char is in the lower byte
			; by loading a byte of esi into a 1 byte register we load a single char
			mov bl, byte [esi]  ; load current char


			; if that char is a number and it zero, its the null terminator
			cmp bl, 0 ; zero signifies the end of the string
			je .end_nextchar

			cmp bl, '-'
			je .negative

			; convert from ascii to number and compare it to 9 if its above the char was not a digit
			sub bl, '0'			
			jmp .positve
						
			.negative:
				
				mov edi, FALSE 
				mov [is_positive], edi

				inc esi
				jmp .nextchar	 


			.positve:
				cmp bl, 9
				ja .error
				
				;imul eax, eax, 10 multiplies the current value in EAX by 10 and stores the result back in EAX
				imul eax, eax, 10

				; since the converted digit is now in bl (lower portion of ebx)
				; we can add ebx (which only contains the digit to eax) slowly building the stringh
				add eax, ebx

				; increment esi so we use the next char (esi is pointer to string)
				inc esi
				jmp .nextchar
			
			.error:
	
				mov edi, -1
				ret 

		.end_nextchar:

			ret


	check_u_input:

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
		
			; if its not positive
			; make the number actually negative
			mov edi, [is_positive]
			cmp edi, FALSE

			mov [u_n1], eax  ; store the conveted number into u_n1
			je .convert_to_neg
			
			;print_str test_msg, test_msg_len
			ret
			
			.convert_to_neg:

				mov esi, [u_n1]	
				neg esi
				mov [u_n1], esi  ; store the conveted number into u_n1
				;print_str negative_msg, negative_msg_len
			ret



global _start

_start:
	
	print_str str_welcome1, str_welcome_len1
	
	call check_u_input

	print_str typed_nmbr_msg, typed_nmbr_msg_len
	mov eax, [u_n1]
	call print_number


	exit_program


; TODO:
; DONE: make print_number correctly print negative numbers (rn it prints them as postive) 

 
	;mov edi, welcome_msg_buffer
	;mov esi, str_welcome1
	;mov ecx, str_welcome_len1 - 1
	;rep movsb
	;mov byte [edi], 0 ; < null terminator

	;mov ecx, welcome_msg_buffer
	;mov edx, welcome_msg_buffer_len
	;print_string ecx, edx

	;greet_user:
		
		;mov ecx, str_welcome1
		;mov edx, str_welcome_len1
