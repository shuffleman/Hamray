package Hamray

import (
	"Hamray/xray"
	"sync"
)

var (
	globalXray *xray.XrayProxy
	xrayMutex  sync.RWMutex
)

// ==================== Xray Functions ====================

// StartXray starts Xray-core with JSON configuration.
// configJSON: Xray JSON configuration string
// Returns error message or empty string on success.
func StartXray(configJSON string) string {
	xrayMutex.Lock()
	defer xrayMutex.Unlock()

	if globalXray != nil && globalXray.IsRunning() {
		return "xray is already running"
	}

	xray, err := xray.NewWithJSON(configJSON)
	if err != nil {
		return err.Error()
	}

	if err := xray.Start(); err != nil {
		return err.Error()
	}

	globalXray = xray
	return ""
}

// StopXray stops Xray-core.
// Returns error message or empty string on success.
func StopXray() string {
	xrayMutex.Lock()
	defer xrayMutex.Unlock()

	if globalXray == nil {
		return ""
	}

	if err := globalXray.Stop(); err != nil {
		return err.Error()
	}

	globalXray = nil
	return ""
}

// IsXrayRunning returns whether Xray is running.
func IsXrayRunning() bool {
	xrayMutex.RLock()
	defer xrayMutex.RUnlock()

	if globalXray == nil {
		return false
	}
	return globalXray.IsRunning()
}

// Version returns Hamary version.
func Version() string {
	return "1.0.0"
}
