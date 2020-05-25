#include <stdio.h>

extern "C"
{
	void aprintf(const char*, ...); 									
}									
									
int main()							
{
	int ans = 5;
	
	aprintf("hello 2+2 =%d! %oo, %hh%%", -ans, -32, -64);
	return 0;
}
