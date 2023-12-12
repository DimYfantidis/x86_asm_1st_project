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
;   - 01/12/2023: Completed remaining comments.
; Date: 01/12/2023

.model flat, stdcall
.stack 4096

.data
; Input array and its length
inputArray  DW  12000, 600, 34, 8, 21, 4      ; My random array with 6 words
lengthInBytes = ($-inputArray)
len = 6


; Output arrays
inverseArray DW  0, 0, 0, 0, 0, 0
prefixSumArray  DW  0, 0, 0, 0, 0, 0
; Note: Ideally the prefix-sum array should have DWORD elements and not WORD 
; to avoid overflow (computed with ADD, ADC instructions) but there are no EAX 
; nor EDX registers. Thus division between a DWORD and a WORD should likely result 
; in overflow (quotient should usually be larger than 0xFFFF and wouldn't fit 
; in AX). As a consequence, I can't seem to find a way to parse a DWORD to print it 
; on the screen in decimal form.


; Variables for WORD to string conversion
; Buffer String
stringRepresentation    DW  0, 0, 0, 0, 0
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
input_name      DB  "INPUT:", 0
inverse_name    DB  "INVERSE:", 0
prefix_name     DB  "PR. SUM:", 0



.code
_start: 
    MOV AX, @data
    MOV DS, AX		; Initialize data segment                            
                                                         
	CLD 
	LEA SI, inputArray  ; Index to Source memory is the input array
	LEA DI, inverseArray	; Index to Destination memory is set to the transposed arry
	ADD DI, lengthInBytes	; It is incremented to point to the end of array
	ADD DI, -2		; Decremented by 2 to point to the final element of the transposed array
	MOV CX, len		; Set counter to loop 6 times

inverse_loop:
	MOV		AX, [SI]	; Copy the first element of the input array to AX
	MOV		[DI], AX	; Copy AX to the last element of the transposed
	ADD		SI, 2		; Traverse input array forward
	ADD		DI, -2		; Traverse output array backwards
	LOOP	inverse_loop		; Repeat 6 times
inverse_loop_end:      

	CLD
	LEA		SI, inputArray		; Index to Source memory is the input array
	LEA		DI, prefixSumArray	; Index to Destination memory is set to the prefix-sum array
	MOV		AX, 0			; Sum (AX) set to 0
	MOV		CX, len
	
prefixSum_loop:
	ADD		AX, [SI]		; AX stores the sum of the previous array cells
	MOV		[DI], AX		; Store the sum to the prefix-sum array
	ADD		SI, 2			; Traverse input array forward
	ADD		DI, 2			; Traverse prefix-sum array forward
	LOOP	prefixSum_loop
prefixSum_loop_end:

	; Prints the name of the input array
	MOV     BX, 14Ah        ; Start position in terminal
	MOV     DH, 0Fh         ; white-on-black (color attribute byte)
	LEA     SI, input_name  ; Index to the name array
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
;   - stringRepresentation: The buffer of the parsed number (reversed).
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

; Skip missing digits in the front
; e.g. when printing 13, the first 3 digits should be skipped (00013).
skip_nulls:
	MOV     DL, [SI]
	CMP     DL, 0
	JNZ     show_string
	DEC     SI
	LOOP    skip_nulls    

show_string:
	MOV     AX, @data
	MOV     DS, AX
	MOV     DL, [SI]    ; Store character in DL.
	DEC     SI          ; Point SI to next digit.
	MOV     AX, 0B800h
	MOV     DS, AX      ; Point DS to video memory.
	MOV     [BX], DX    ; Print character on the screen.
	ADD     BX, 2       ; Move cursor to next character.
	LOOP    show_string 


	MOV     AX, @data
	MOV     DS, AX      ; Restore DS.

	RET                    
print_word ENDP



; Prints a WORD array of size 6 to the console.
; Parameters:
;   - SI: Address of the said array.
;   - BX: Address of the first color attribute byte.
;   - [positionConfig]: Start position of printing in terminal.
; Returns:
;   Nothing
print_array PROC NEAR
	MOV     CX, 6

array_print_loop:
    ; Precursor protocol for "parse_word" function call
	MOV     AX, [SI]    ; get next number
	MOV     [num],  AX  ; store it to [num]
	PUSH    SI
	PUSH    BX
	; Convert [num] to text.
	CALL    parse_word
	POP     BX
	
	; Precursor protocol for "print_word" function call
	PUSH    BX
	PUSH    CX
	MOV     AL, [BX]                ; Get next attribute byte
	MOV     [colorConfig], AL       ; Move it to the parameter variable
	; Print number on screen
	CALL    print_word
	MOV     AX, [positionConfig]    ; Restore cursor initial position.
	ADD     AX, 12
	MOV     [positionConfig], AX    ; Move cursor by 6 characters 
	POP     CX
	POP     BX
	POP     SI

	ADD     SI, 2   ; Point to the next WORD in array.
	INC     BX 
	LOOP    array_print_loop

	RET   
print_array ENDP


; Prints a string to the terminal
; Parameters:
;   - BX: Start position of printing in terminal.
;   - DH: Color attribute byte.
;   - SI: Address of the first character.
; Returns:
;   Nothing
print_alnum PROC NEAR
	; Push registers that aren't parameters to avoid breaking them.
	PUSH    AX
	PUSH    DX
alnum_loop:
	MOV     AX, @data
	MOV     DS, AX      ; Set the Data Segment to where the string is situated.
	MOV     DL, [SI]    ; Load next character.
	CMP     DL, 0
	JZ      alnum_end   ; Null character terminates the string.
	MOV     AX, 0B800h
	MOV     DS, AX      ; Point DS to Video Memory.
	MOV     [BX], DX    ; Print character in the given position.
	ADD     BX, 2       ; Move cursor to the next character.
	INC     SI
	JMP    alnum_loop

alnum_end:
	; Fetch the pushed registers and 
	POP     DX
	POP     AX    
	RET
print_alnum ENDP