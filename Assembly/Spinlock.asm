; Spinlock.asm
; Implementing a spinlock in x64 assembly.
;
; Implements mutual exclusion in a couple different ways so we can compare performance:
;	- DoWorkLocked just uses the atomic increment instruction in raw form
;	- DoWorkSpin implements a spinlock via a mutex

; there is an external procedure that we want to call
extern CreateThread: proc

.data
MUTEX dw 0  ; mutex for spinlock

.code

; create a thread and have it do work
; HANDLE SpinlockASM(int *i)
SpinlockASM proc
	push rbp       ; save caller's rbp
	mov rbp, rsp   ; set up the stack frame  

	push 0        ; thread id
	push 0        ; creation flags, start immediately
	sub rsp, 20h  ; make space for the call

	mov r9, rcx           ; move *i to r9
	mov rcx, 0            ; security attributes
	mov rdx, 0            ; use same stack size as calling thread
	mov r8, DoWorkLocked  ; creation routine 

	call CreateThread

	mov rsp, rbp   ; clean up the stack 
	pop rbp        ; restore caller's rbp

	ret 
SpinlockASM endp

; thread execution function
; increment shared variable with interlocked instruction 
DoWorkLocked proc
	mov rax, 10000   ; each thread loops N times 
WorkLoop:
	lock inc dword ptr [rcx]
	dec rax
	jnz WorkLoop
	
	ret
DoWorkLocked endp

; thread creation function
; increment shared variable with spinlock
DoWorkSpin proc
	mov rax, 10000      ; thread loops N times

SpinLoop:
	lock bts MUTEX, 0   ; test bit at position 0
	jc SpinLoop

	; critical section entry, do all the work
WorkLoop:
	inc dword ptr [rcx]
	dec rax
	jnz WorkLoop

	mov MUTEX, 0                 ; release mutex
	; critical section exit
	
	ret
DoWorkSpin endp

end