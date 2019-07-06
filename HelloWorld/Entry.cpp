/*
 * Entry.cpp
 * Sample entry point for C++ application using assembly language module.
 */

#include <cstdio>

// defined in assembly module 
extern "C" void HelloWorldWrapper();

// called from assembly module 
extern "C" void HelloWorld()
{
	printf("Hello, World!\n");
}

int main()
{
	HelloWorldWrapper();	
	return 0;
}
