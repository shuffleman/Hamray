// Package main provides CGO exports for hamrayOS.
package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"hamray/pkg/hamray"
	"unsafe"
)

// ==================== Xray Functions ====================

//export StartXray
func StartXray(configJSON *C.char) *C.char {
	result := hamray.StartXray(C.GoString(configJSON))
	if result == "" {
		return nil
	}
	return C.CString(result)
}

//export StopXray
func StopXray() *C.char {
	result := hamray.StopXray()
	if result == "" {
		return nil
	}
	return C.CString(result)
}

//export IsXrayRunning
func IsXrayRunning() C.int {
	if hamray.IsXrayRunning() {
		return 1
	}
	return 0
}

// ==================== Utility Functions ====================

//export GetVersion
func GetVersion() *C.char {
	return C.CString(hamray.Version())
}

//export FreeString
func FreeString(s *C.char) {
	if s != nil {
		C.free(unsafe.Pointer(s))
	}
}

func main() {}
