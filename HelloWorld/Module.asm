; Module.asm 
; Sample assembly language module. 

; tell the assembler this function will be externally linked
extern HelloWorld: proc 

.code 

; void HelloWorldWrapper()
HelloWorldWrapper proc 
	sub rsp, 20h      ; allocate shadow space on stack 
	call HelloWorld   ; make the call 
	add rsp, 20h      ; clean up the stack
	ret 
HelloWorldWrapper endp

end