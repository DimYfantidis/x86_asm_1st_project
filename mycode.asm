; Program description:
;   The program below takes a precomputed array of 16-bit integers, inputArray 
;   and computes its inverse and prefix-sum arrays. Next, all three of them are
;   printed to the terminal by directly accessing the video memory. Each number 
;   has its own foreground and background color.
;
; Author: Yfantidis Dimitrios
; Creation Date: 22/11/2023
; Revisions:
;   - 24/11/2023: Added function to convert WORDs to their corresponding alphanumerics.
;   - 25/11/2023: Added function to print WORDs to the console, print_word (buggy)
;   - 26/11/2023: Fixed print_word + Added print_array + Added print_alnum
; Date: 26/11/2023

.model flat, stdcall
.stack 4096

.data
; Input array and its length
inputArray  DW  12, 6, 34, 8, 21, 4      ; My random array with 6 words
lengthInBytes = ($-inputArray)
len = 6


; Output arrays
inverseArray DW  0, 0, 0, 0, 0, 0
prefixSumArray  DW  0, 0, 0, 0, 0, 0


; Variables for WORD to string conversion
; Buffer String
stringRepresentation    DB  0, 0, 0, 0, 0
; Digits as ASCII characters
digitsAscii     DB  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
; Quotient for parse_word
num             DW  ?


; Variables for WORD printing
; Different color for each of the 18 numbers
colorConfigs    DB  0Ah, 20h, 6Fh, 75h, 1Fh, 0D4h, 1Eh, 04h, 0F5h, 89h, 0F5h, 0F0h, 0Bh, 0DFh, 34h, 12h, 08Eh, 0Dh
; Color of the next number to be printed
colorConfig     DB  ?
; Position of the next number to be printed (based on terminal's coordinates)
positionConfig  DW  ?


; Array Names
input_name      DB  'I', 'N', 'P', 'U', 'T', ':', ' ', ' '
inverse_name    DB  'I', 'N', 'V', 'E', 'R', 'S', 'E', ':'
prefix_name     DB  'P', 'R', '.', ' ', 'S', 'U', 'M', ':'
name_len = ($-prefix_name)




.code
_start:
    MOV AX, @data
    MOV DS, AX                  ; Initialize data segment                            
                                                         
	CLD 
	LEA SI, inputArray			; Index to Source memory is the input array
	LEA DI, inverseArray		; Index to Destination memory is set to the transposed arry
	ADD DI, lengthInBytes		; It is incremented to point to the end of array
	ADD DI, -2					; Decremented by 2 to point to the final element of the transposed array
	MOV CX, len                 ; Set counter to loop 6 times

inverse_loop:
	MOV		AX, [SI]				; Copy the first element of the input array to AX
	MOV		[DI], AX				; Copy AX to the last element of the transposed
	ADD		SI, 2					; Traverse input array forward
	ADD		DI, -2					; Traverse output array backwards
	LOOP	inverse_loop			; Repeat 6 times
inverse_loop_end:      

	CLD
	LEA		SI, inputArray			; Index to Source memory is the input array
	LEA		DI, prefixSumArray		; Index to Destination memory is set to the prefix-sum array
	MOV		AX, 0					; Sum (AX) set to 0
	MOV		CX, len
	
prefixSum_loop:
	ADD		AX, [SI]				; AX stores the sum of the previous array cells
	MOV		[DI], AX				; Store the sum to the prefix-sum array
	ADD		SI, 2					; Traverse input array forward
	ADD		DI, 2					; Traverse prefix-sum array forward
	LOOP	prefixSum_loop
prefixSum_loop_end:

    
    ; Prints the name of the input array
    MOV     BX, 14Ah        ; Start position in terminal
    MOV     DH, 0Fh         ; white-on-black (color attribute byte)
    LEA     SI, input_name  ; Index to the name array
    MOV     CX, name_len    ; Loop for 8 characters
    CALL    print_alnum
    
    ; Prints the first Array
    LEA     BX, colorConfigs        ; Index to the color attributes' array
    LEA     SI, inputArray          ; Index to the input array
    MOV     [positionConfig], 15Eh  ; Start position in terminal
    CALL    print_array
      
    
    ; Prints the name of the inverse array  
    MOV     BX, 28Ah         ; likewise...
    MOV     DH, 0Fh          ; ...
    LEA     SI, inverse_name ; ...
    MOV     CX, name_len     ; ...
    CALL    print_alnum

    ; Prints the inverse Array
    LEA     BX, colorConfigs+6      ; Index for the color attribute bytes after the first array.
    LEA     SI, inverseArray        ; Index to the inverse array
    MOV     [positionConfig], 29Eh  ; ...
    CALL    print_array
    
    
    ; Prints the name of the prefix-sum array.
    MOV     BX, 3CAh
    MOV     DH, 0Fh
    LEA     SI, prefix_name
    MOV     CX, name_len
    CALL    print_alnum
  
    ; Prints the prefix-sum array.
    LEA     BX, colorConfigs+12
    LEA     SI, prefixSumArray
    MOV     [positionConfig],   3DEh
    CALL    print_array
    
    MOV     AH, 4Ch ; DOS function: Exit program   
    INT     21h     ; DOS interrupt       
    

; Converts WORD to its equivalent ASCII string using divisions by 10.
; Parameters:
;   - [num]: The number to be parsed (is reduced to 0 after function completion)
; Returns:
;   - The parsed WORD, stored in the "stringRepresentation" buffer.
parse_word PROC NEAR
    CLD
    ; Buffer is initialized to values of zero.
    MOV     [stringRepresentation],     0
    MOV     [stringRepresentation+1],   0
    MOV     [stringRepresentation+2],   0
    MOV     [stringRepresentation+3],   0
    MOV     [stringRepresentation+4],   0
    		
	LEA     DI, stringRepresentation    ; Last digit (buffer is inversed).
	MOV     BX, 10                      ; BX holds the denominator.
	MOV     AX, [num]                   ; AX holds the enumerator.
	
; The following loop performs one iteration for every decimal digit 
; of the 16-bit number (5 iterations max as U16INT_MAX is 65535).
build_string:
    MOV     DX,     0                   ; Set DX=0 so that DX:AX = AX
	DIV     BX                          ; Perform division (DX=remainder, AX=quotient)
	MOV     [num],  AX                  ; Store the quotient.
	LEA     SI,     digitsAscii
	ADD     SI,     DX                  ; Retrieve the index of the remainder digit (as ASCII).
	MOV     AL,     [SI]               
	MOV     [DI],   AL                  ; Store the ascii digit in the next character of the buffer.
	INC     DI
    MOV     AX,     [num]               ; Retrieve quotient.
    CMP     AX,     0                   
    JNZ     build_string                ; Terminate if quotient reached 0.    
    RET
parse_word ENDP



; Prints a 16-bit integer to the console (used directly after parse_word).
; Parameters:
;   - stringRepresentation: The buffer of the parsed number.
;   - [colorConfig]: Color attribute byte for the digits
;   - [positionConfig]: Start position of printing in terminal.
print_word PROC NEAR
    LEA     SI, stringRepresentation
    ADD     SI, 4
    MOV     DH, [colorConfig]
    MOV     BX, [positionConfig]
    MOV     CX, 5
    MOV     AX, @data
    MOV     DS, AX
    
skip_nulls:
    MOV     DL, [SI]
    CMP     DL, 0
    JNZ     show_string
    DEC     SI
    LOOP    skip_nulls    
    
show_string:
    MOV     AX, @data
    MOV     DS, AX
    MOV     DL, [SI]
    DEC     SI
    MOV     AX, 0B800h
    MOV     DS, AX
    MOV     [BX], DX
    ADD     BX, 2
    LOOP    show_string
    

    MOV     AX, @data
    MOV     DS, AX
    
    RET                    
print_word ENDP



; Prints a WORD array of size 6 to the console.
;   - SI: Address of the said array.
;   - BX: Address of the first color attribute byte.
;   - [positionConfig]: Start position of printing in terminal.
print_array PROC NEAR
    MOV     CX, 6
    
array_print_loop:
    
    MOV     AX, [SI]
    MOV     [num],  AX
    PUSH    SI
    PUSH    BX
    CALL    parse_word
    POP     BX
    
    PUSH    BX
    PUSH    CX
    MOV     AX, [BX]
    MOV     [colorConfig], AL
    CALL    print_word
    MOV     AX, [positionConfig]
    ADD     AX, 12
    MOV     [positionConfig], AX
    POP     CX
    POP     BX
    POP     SI
    
    ADD     SI, 2
    INC     BL 
    LOOP    array_print_loop
    
    RET   
print_array ENDP


; Prints a string to the terminal
; Parameters:
;   - BX: Start position of printing in terminal.
;   - DH: Color attribute byte.
;   - SI: Address of the first character.
;   - CX: String's length.
print_alnum PROC NEAR
alnum_loop:
    MOV     AX, @data
    MOV     DS, AX
    MOV     DL, [SI]
    MOV     AX, 0B800h
    MOV     DS, AX
    MOV     [BX], DX
    ADD     BX, 2
    INC     SI
    LOOP    alnum_loop
    
    MOV     AX, @data
    MOV     DS, AX
    
    RET
print_alnum ENDP