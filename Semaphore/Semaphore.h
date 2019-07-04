/*
 * Semaphore.h
 * Semaphore types and routines. 
 */

#pragma once

typedef void* MySemaphore;

// helper function to get handle to currently executing thread
extern "C" HANDLE GetThreadHandle()
{
	return OpenThread(THREAD_ALL_ACCESS, FALSE, GetCurrentThreadId());
}

extern "C" MySemaphore MySemaphoreCreate(int initialCount, int max);

extern "C" void MySemaphoreFree(MySemaphore s);

extern "C" void MySemaphoreSignal(MySemaphore s);

extern "C" void MySemaphoreWait(MySemaphore s);