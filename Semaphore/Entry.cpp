/*
 * Entry.cpp
 * Application entry point. 
 */

#include <Windows.h>
#include <iostream>
#include <thread>

#include "Semaphore.h"

int g_numberOfThreads;
int g_arrivedCount;

MySemaphore barrier;
MySemaphore mutex;

void TestBarrier();

int main()
{
	// set the barrier counts
	g_numberOfThreads = 10;
	g_arrivedCount = 0;

	mutex = MySemaphoreCreate(1, g_numberOfThreads);
	barrier = MySemaphoreCreate(0, g_numberOfThreads);

	if (NULL == mutex || NULL == barrier)
	{
		// failure
		std::cout << "ERROR: creating semaphores" << std::endl;
		std::cin.get();
		return 0;
	}

	// generate the threads
	std::thread** threads = new std::thread *[g_numberOfThreads];
	for (size_t i = 0; i < g_numberOfThreads; ++i)
		threads[i] = new std::thread(TestBarrier);

	std::cin.get();

	// cleanup
	for (size_t i = 0; i < g_numberOfThreads; ++i)
		threads[i]->detach();
	MySemaphoreFree(barrier);
	MySemaphoreFree(mutex);

	return 0;
}

void TestBarrier()
{
	size_t waitTime = rand() % 100;
	for (size_t i = 0; i < waitTime * (size_t)1000000; ++i);

	std::cout << "[" << GetCurrentThreadId() << "] Arrives at Barrier." << std::endl;

	MySemaphoreWait(mutex);
	g_arrivedCount++;
	MySemaphoreSignal(mutex);

	if (g_arrivedCount == g_numberOfThreads)
	{
		std::cout << "ALL THREADS ARRIVED" << std::endl;
		MySemaphoreSignal(barrier);
	}

	MySemaphoreWait(barrier);
	MySemaphoreSignal(barrier);

	std::cout << "[" << GetCurrentThreadId() << "] Through the Barrier." << std::endl;
}