.data
dividend QWORD 8 
divisor  QWORD 3

.code
func proc
	xor rdx, rdx
	mov rax, dividend
	mov rbx, divisor
	div rbx
	ret
func endp

end
