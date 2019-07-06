; LoadEffectiveAddr.asm
; A quick exploration of the LoadEffectiveAddress (lea) instructon. 

.data 
GlobalVar qword 32

.code 

; DWORD64 LoadEffectiveAddr()
LoadEffectiveAddrASM proc 
	lea rcx, GlobalVar           ; load address of the data into rcx (aka create a pointer to data) 
	mov rax, qword ptr [rcx]     ; dereference the pointer and move result of dereference into rax 
	ret                          ; return with data in rax
LoadEffectiveAddrASM endp

end