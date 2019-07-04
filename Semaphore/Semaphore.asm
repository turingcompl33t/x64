; Semaphore.asm
; Semaphore type and routines.

; external functions
extern malloc:          proc
extern free:            proc
extern abort:           proc
extern SuspendThread:   proc
extern ResumeThread:    proc
extern GetThreadHandle: proc 

; -----------------------------------------------------------------------------
; MySemaphore Data Structure 

; MySemaphore structure definition
MySemaphore struct
	count        dd ?   ; current count of the semaphore
	maxThreads   dd ?   ; maximum number of waiters 
	queueMutex   dd ?   ; mutex on the internal semaphore queue 
	queueCount   dd ?   ; number of waiters in the internal queue 
	queueNext    dd ?   ; index of head of internal queue 
	dummyPadding dd ?
	; queue data follows here:
	; a circular array of queueCount 64-bit handles
MySemaphore ends 

.code

; -----------------------------------------------------------------------------
; MySemaphore Routines 

; Allocate and initialize a new semaphore. 
; MySemaphore MySemaphoreCreate(int initialCount = rcx, int max = rdx)
MySemaphoreCreate proc
	; validate the params
	cmp ecx, edx  ; is initialCount > max?
	jg AllocationError

	cmp edx, 0    ; is max <= 0?
	jle AllocationError 

	cmp ecx, 0    ; is initialCount negative?
	jl AllocationError

	push rcx
	push rdx

	; allocate 24 bytes for semaphore header, and then
	; 8 bytes for each item (pointer) in the queue of waiters (max*8)
	shl rdx, 3     ; bytes = max*3
	add rdx, 20    ; bytes += 20

	sub rsp, 20h   ; make call to malloc()
	xchg rcx, rdx
	call malloc
	add rsp, 20h

	pop rdx        ; restore the inital values we clobbered 
	pop rcx 

	; returned pointer from malloc() in rax 
	; initialize our semaphore with initial data 

	mov dword ptr [rax].MySemaphore.count, ecx       ; s.count = initialCount
	mov dword ptr [rax].MySemaphore.maxThreads, edx  ; s.maxThreads = max
	mov dword ptr [rax].MySemaphore.queueMutex, 0    ; s.queueMutex = 0
	mov dword ptr [rax].MySemaphore.queueCount, 0    ; s.queueCount = 0
	mov dword ptr [rax].MySemaphore.queueNext, 0     ; s.queueNext = 0

	; returns with pointer to initialized semaphore in rax 
	ret

AllocationError:
	mov rax, 0
	ret

MySemaphoreCreate endp

; Deallocate an existing semaphore. 
; void MySemaphoreDelete(MySemaphore s = rcx)
MySemaphoreFree proc
	sub rsp, 20h 
	call free
	add rsp, 20h 
	ret 
MySemaphoreFree endp 

; Have thread wait on semaphore. 
; void MySemaphoreWait(MySemaphore s = rcx)
MySemaphoreWait proc

	; acquire the semaphore mutex 
MutexLoop:
	lock bts dword ptr [rcx].MySemaphore.queueMutex, 0
	jc MutexLoop

	; decrement the counter 
	dec dword ptr [rcx].MySemaphore.count 

	; if decrement results in negative for count, enqueue this thread
	cmp dword ptr [rcx].MySemaphore.count, 0
	jge Finished

	; the count was made negative, need to enqueue 
	call EnqueueThisThread

	; release the mutex
	mov dword ptr [rcx].MySemaphore.queueMutex, 0

	; put the thread to sleep, indefinitely
	sub rsp, 20h
	mov rcx, rdx
	call SuspendThread
	add rsp, 20h 

	ret

	; count was not made negative by decrement 
	; release the mutex and return
Finished:
	mov dword ptr [rcx].MySemaphore.queueMutex, 0 
	ret 
MySemaphoreWait endp 

; Have thread signal on semaphore. 
; void MySemaphoreSignal(MySemaphore s = rcx)
MySemaphoreSignal proc
	
; acquire the mutex 
MutexLoop:
	lock bts dword ptr [rcx].MySemaphore.queueMutex, 0
	jc MutexLoop

	; increment the counter
	inc dword ptr [rcx].MySemaphore.count

	; after increment, check if sleeping threads on queue
	call DequeueNextThread
	cmp rax, 0
	je NoThreadsToWake

	; there is a thread to wake, and we now have a handle to this thread
	; wake this thread
ThreadWakeLoop:
	push rcx
	push rax 
	
	sub rsp, 20h 
	mov rcx, rax 
	call ResumeThread
	add rsp, 20h 

	; ResumeThread tells us if thread was asleep 
	mov rdx, rax 
	pop rax 
	pop rcx 

	; was the thread asleep?
	cmp rdx, 0 
	je ThreadWakeLoop

NoThreadsToWake:
	mov [rcx].MySemaphore.queueMutex, 0
	ret
MySemaphoreSignal endp

; -----------------------------------------------------------------------------
; Helper Functions 
; (Do not implement standard calling convetion!)

; Enqueue the invoking thread on semaphore queue.
; void EnqueueThisThread(MySemaphore s = rcx)
EnqueueThisThread proc
	push rbx

	push rcx              ; save pointer to semaphore 
	call GetThreadHandle
	mov rdx, rax 
	pop rcx               ; restore pointer to semaphore 

	; read the current state values from semaphore 
	mov eax, dword ptr [rcx].MySemaphore.maxThreads 
	mov ebx, dword ptr [rcx].MySemaphore.queueCount 
	mov r8d, dword ptr [rcx].MySemaphore.queueNext

	cmp rbx, rax     ; is the queue full?
	je QueueIsFull 

	; TODO: I think this algorithm for circular queue is incorrect 
	; add the count and last, taking the mod of max from this sum
	add r8d, ebx     ; add count and last 
	mov r9d, r8d     ; copy sum to r9 
	sub r9d, eax     ; subtract max from sum in r9 
	cmp r8d, eax     ; see if its greater than max 
	cmovge r8d, r9d  ; conditionally move the mod if it is 

	mov qword ptr [(rcx+24)+(r8*8)], rdx 

	; increment the counter  
	inc dword ptr [rcx].MySemaphore.queueCount 

	pop rbx 
	ret 

QueueIsFull:
	call abort     ; panic and die 

	pop rbx        ; never reached 
	ret 

EnqueueThisThread endp 

; Dequeue the next thread from semaphore queue. 
; void DequeueNextThread(MySemaphore s = rcx)
DequeueNextThread proc
	push rbx

	mov r9d, dword ptr [rcx].MySemaphore.maxThreads  ; r9d = s.maxThreads
	mov ebx, dword ptr [rcx].MySemaphore.queueCount  ; ebx = s.queueCount
	mov r8d, dword ptr [rcx].MySemaphore.queueNext   ; r8d = s.queueNext 

	cmp rbx, 0
	je QueueIsEmpty

	; decrement the current count
	; apparently dec works directyly on memory values 
	dec dword ptr [rcx].MySemaphore.queueCount

	; read the handle from the queue 
	mov rax, qword ptr [(rcx+20)+(r8*8)]

	; TODO: I think this algorithm for circular queue is incorrect
	; increment the queueNex value, wrapping if needed
	inc r8          ; queueNext += 1
	mov r10, r8     ; queueNextCopy 
	sub r10, r9     ; queueNextCopy = queueNextCopy - max
	cmp r8, r9 
	cmovge r8, r10  ; queueNext = queueNextCopy >= max ? 
					;	queueNextCopy : queueNext 

	mov qword ptr [rcx].MySemaphore.queueNext, r8 

	; return with handle of thread to awaken in rax 
	pop rbx 
	ret 

QueueIsEmpty:
	mov rax, 0
	pop rbx
	ret 
DequeueNextThread endp

end
