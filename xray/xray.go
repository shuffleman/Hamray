package xray

import (
	"bytes"
	"fmt"
	"sync"

	xcore "github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf/serial"
)

// XrayProxy manages the Xray-core instance.
type XrayProxy struct {
	mu         sync.RWMutex
	configJSON []byte
	instance   *xcore.Instance
	running    bool
}

// NewWithJSON creates a new XrayProxy instance with JSON configuration.
func NewWithJSON(configJSON string) (*XrayProxy, error) {
	if configJSON == "" {
		return nil, fmt.Errorf("config cannot be empty")
	}
	return &XrayProxy{
		configJSON: []byte(configJSON),
	}, nil
}

// Start starts the Xray-core instance.
func (x *XrayProxy) Start() error {
	x.mu.Lock()
	defer x.mu.Unlock()

	if x.running {
		return fmt.Errorf("xray is already running")
	}

	// Parse JSON config
	jsonConfig, err := serial.DecodeJSONConfig(bytes.NewReader(x.configJSON))
	if err != nil {
		return fmt.Errorf("failed to decode JSON config: %w", err)
	}

	// Build protobuf config
	pbConfig, err := jsonConfig.Build()
	if err != nil {
		return fmt.Errorf("failed to build config: %w", err)
	}

	// Create Xray instance
	instance, err := xcore.New(pbConfig)
	if err != nil {
		return fmt.Errorf("failed to create xray instance: %w", err)
	}

	// Start Xray
	if err := instance.Start(); err != nil {
		return fmt.Errorf("failed to start xray: %w", err)
	}

	x.instance = instance
	x.running = true

	return nil
}

// Stop stops the Xray-core instance.
func (x *XrayProxy) Stop() error {
	x.mu.Lock()
	defer x.mu.Unlock()

	if !x.running {
		return nil
	}

	if x.instance != nil {
		if err := x.instance.Close(); err != nil {
			return fmt.Errorf("failed to close xray instance: %w", err)
		}
		x.instance = nil
	}

	x.running = false
	return nil
}

// IsRunning returns whether Xray is running.
func (x *XrayProxy) IsRunning() bool {
	x.mu.RLock()
	defer x.mu.RUnlock()
	return x.running
}

// UpdateConfig updates configuration and restarts if running.
func (x *XrayProxy) UpdateConfig(configJSON string) error {
	x.mu.Lock()
	wasRunning := x.running
	x.mu.Unlock()

	if wasRunning {
		if err := x.Stop(); err != nil {
			return fmt.Errorf("failed to stop xray: %w", err)
		}
	}

	x.mu.Lock()
	x.configJSON = []byte(configJSON)
	x.mu.Unlock()

	if wasRunning {
		if err := x.Start(); err != nil {
			return fmt.Errorf("failed to restart xray: %w", err)
		}
	}

	return nil
}

// GetInstance returns the underlying Xray instance.
func (x *XrayProxy) GetInstance() *xcore.Instance {
	x.mu.RLock()
	defer x.mu.RUnlock()
	return x.instance
}
