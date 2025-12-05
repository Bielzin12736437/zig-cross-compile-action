package main

/*
#include <stdio.h>
#include <stdlib.h>

void myprint(char* s) {
	printf("%s\n", s);
}
*/
import "C"
import "unsafe"

func main() {
	cs := C.CString("Hello from CGO Cross-Compile!")
	C.myprint(cs)
	C.free(unsafe.Pointer(cs))
}
