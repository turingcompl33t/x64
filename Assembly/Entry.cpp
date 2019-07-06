/*
 * Entry.cpp
 * Entry point for C++/x64 playground.
 */

#include <Windows.h>
#include <iostream>
#include <time.h>

 /* ----------------------------------------------------------------------------
	 Module Entry Prototypes
 */

void ModuleConvention();
void ModuleSpinlock();
void ModuleLoadEffectiveAddr();

/* ----------------------------------------------------------------------------
	Externally Defined in x64 Modules (Called by C++ Module Entries)
*/

// Convention.asm 
extern "C" int     ConventionASM();
extern "C" HANDLE  SpinlockASM(int *i);
extern "C" DWORD64 LoadEffectiveAddrASM();

/* ----------------------------------------------------------------------------
	Entry Point
*/

int main()
{
	// Swap out call here to run different programs

	//ModuleConvention();
	//ModuleSpinlock();
	ModuleLoadEffectiveAddr();

	return 0;
}

/* ----------------------------------------------------------------------------
	Module Entries
*/

void ModuleConvention()
{
	ConventionASM();
}

void ModuleSpinlock()
{
	int count = 0;
	HANDLE handles[5];

	long startTime = clock();

	// create N threads
	for (int i = 0; i < 5; ++i)
		handles[i] = SpinlockASM(&count);

	// wait until all of the threads are done
	for (int i = 0; i < 5; ++i)
		WaitForSingleObject(handles[i], INFINITE);

	long finishTime = clock();

	std::cout << "GOT RESULT: " << count << std::endl;
	std::cout << "DURATION: " << (finishTime - startTime) << " MS" << std::endl;
}

void ModuleLoadEffectiveAddr()
{
	DWORD64 ret = LoadEffectiveAddrASM();
	std::cout << "GOT RETURN: " << ret << std::endl;
}

/* ----------------------------------------------------------------------------
	Called from x64 Modules 
*/

// Called from Convention.asm 
extern "C" void MyCppFunction(int a, int b, int c, int d, int e, int f)
{
	std::cout << "Got Argument e: " << e << std::endl;
}