; Convention.asm
; Exploration of calling conventions between C++ and x64 assembly. 

; let assembler know this function will be linked in
extern MyCppFunction: proc

.code
ConventionASM proc
	push rbp       ; save base pointer
	mov rbp, rsp   ; set stack frame base
	sub rsp, 30h   ; make space for arguments to next function, including shadow

	; set up the arguments
	mov dword ptr [rbp-8h], 5
	mov dword ptr [rbp-10h], 4
	mov r9, 3
	mov r8, 2
	mov rdx, 1
	mov rcx, 0

	; do the thing 
	call MyCppFunction

	add rsp, 30h ; restore the stack
	pop rbp      ; restore base pointer 
	ret

ConventionASM endp

end
