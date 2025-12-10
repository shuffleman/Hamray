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

// ==================== Tunnel Functions ====================

//export StartTunnel
func StartTunnel(fd C.int, mtu C.int, proxyAddress *C.char) *C.char {
	result := hamray.StartTunnel(int(fd), int(mtu), C.GoString(proxyAddress))
	if result == "" {
		return nil
	}
	return C.CString(result)
}

//export StopTunnel
func StopTunnel() *C.char {
	result := hamray.StopTunnel()
	if result == "" {
		return nil
	}
	return C.CString(result)
}

//export IsTunnelRunning
func IsTunnelRunning() C.int {
	if hamray.IsTunnelRunning() {
		return 1
	}
	return 0
}

// ==================== Combined Functions ====================

//export StartAll
func StartAll(xrayConfigJSON *C.char, tunFD C.int, mtu C.int, proxyAddress *C.char) *C.char {
	result := hamray.StartAll(
		C.GoString(xrayConfigJSON),
		int(tunFD),
		int(mtu),
		C.GoString(proxyAddress),
	)
	if result == "" {
		return nil
	}
	return C.CString(result)
}

//export StopAll
func StopAll() *C.char {
	result := hamray.StopAll()
	if result == "" {
		return nil
	}
	return C.CString(result)
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
