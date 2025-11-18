package wireguard

import (
	"fmt"
	"os"
	"strings"

	log "github.com/sirupsen/logrus"
)

const (
	// Paths - wg and wg-quick are already installed on NanoKVM
	WgPath      = "/usr/bin/wg"
	WgQuickPath = "/usr/bin/wg-quick"
	ConfigDir   = "/etc/wireguard"
	DefaultInterface = "wg0"
)

type WgConfig struct {
	Interface WgInterfaceConfig
	Peers     []WgPeerConfig
}

type WgInterfaceConfig struct {
	PrivateKey string
	Address    string
	ListenPort int
	DNS        string
	MTU        int
}

type WgPeerConfig struct {
	PublicKey           string
	PresharedKey        string
	Endpoint            string
	AllowedIPs          []string
	PersistentKeepalive int
}

// GetConfigPath returns the configuration file path for the interface
func GetConfigPath(interfaceName string) string {
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}
	return fmt.Sprintf("%s/%s.conf", ConfigDir, interfaceName)
}

// LoadConfig reads the WireGuard configuration from file
func LoadConfig(interfaceName string) (string, error) {
	configPath := GetConfigPath(interfaceName)
	data, err := os.ReadFile(configPath)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

// SaveConfig writes the WireGuard configuration to file
func SaveConfig(interfaceName string, config string) error {
	configPath := GetConfigPath(interfaceName)
	
	// Ensure config directory exists
	if err := os.MkdirAll(ConfigDir, 0o700); err != nil {
		log.Errorf("failed to create config directory: %s", err)
		return err
	}

	// Write config file
	if err := os.WriteFile(configPath, []byte(config), 0o600); err != nil {
		log.Errorf("failed to write config file: %s", err)
		return err
	}

	log.Debugf("saved WireGuard config to %s", configPath)
	return nil
}

// DeleteConfig removes the configuration file
func DeleteConfig(interfaceName string) error {
	configPath := GetConfigPath(interfaceName)
	return os.Remove(configPath)
}

// ConfigExists checks if a configuration file exists
func ConfigExists(interfaceName string) bool {
	configPath := GetConfigPath(interfaceName)
	_, err := os.Stat(configPath)
	return err == nil
}

// ParseConfig parses a WireGuard configuration string into a structured format
func ParseConfig(configStr string) (*WgConfig, error) {
	config := &WgConfig{
		Peers: []WgPeerConfig{},
	}

	var currentSection string
	var currentPeer *WgPeerConfig

	lines := strings.Split(configStr, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)

		// Skip empty lines and comments
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Check for section headers
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			currentSection = strings.ToLower(strings.Trim(line, "[]"))
			if currentSection == "peer" {
				currentPeer = &WgPeerConfig{
					AllowedIPs: []string{},
				}
			}
			continue
		}

		// Parse key-value pairs
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])

		switch currentSection {
		case "interface":
			switch strings.ToLower(key) {
			case "privatekey":
				config.Interface.PrivateKey = value
			case "address":
				config.Interface.Address = value
			case "listenport":
				fmt.Sscanf(value, "%d", &config.Interface.ListenPort)
			case "dns":
				config.Interface.DNS = value
			case "mtu":
				fmt.Sscanf(value, "%d", &config.Interface.MTU)
			}
		case "peer":
			if currentPeer != nil {
				switch strings.ToLower(key) {
				case "publickey":
					currentPeer.PublicKey = value
				case "presharedkey":
					currentPeer.PresharedKey = value
				case "endpoint":
					currentPeer.Endpoint = value
				case "allowedips":
					currentPeer.AllowedIPs = strings.Split(value, ",")
					for i := range currentPeer.AllowedIPs {
						currentPeer.AllowedIPs[i] = strings.TrimSpace(currentPeer.AllowedIPs[i])
					}
				case "persistentkeepalive":
					fmt.Sscanf(value, "%d", &currentPeer.PersistentKeepalive)
				}
			}
		}
	}

	// Add last peer if exists
	if currentPeer != nil && currentPeer.PublicKey != "" {
		config.Peers = append(config.Peers, *currentPeer)
	}

	return config, nil
}

// FormatConfig converts a structured config back to WireGuard config format
func FormatConfig(config *WgConfig) string {
	var builder strings.Builder

	// Interface section
	builder.WriteString("[Interface]\n")
	if config.Interface.PrivateKey != "" {
		builder.WriteString(fmt.Sprintf("PrivateKey = %s\n", config.Interface.PrivateKey))
	}
	if config.Interface.Address != "" {
		builder.WriteString(fmt.Sprintf("Address = %s\n", config.Interface.Address))
	}
	if config.Interface.ListenPort > 0 {
		builder.WriteString(fmt.Sprintf("ListenPort = %d\n", config.Interface.ListenPort))
	}
	if config.Interface.DNS != "" {
		builder.WriteString(fmt.Sprintf("DNS = %s\n", config.Interface.DNS))
	}
	if config.Interface.MTU > 0 {
		builder.WriteString(fmt.Sprintf("MTU = %d\n", config.Interface.MTU))
	}

	// Peer sections
	for _, peer := range config.Peers {
		builder.WriteString("\n[Peer]\n")
		if peer.PublicKey != "" {
			builder.WriteString(fmt.Sprintf("PublicKey = %s\n", peer.PublicKey))
		}
		if peer.PresharedKey != "" {
			builder.WriteString(fmt.Sprintf("PresharedKey = %s\n", peer.PresharedKey))
		}
		if peer.Endpoint != "" {
			builder.WriteString(fmt.Sprintf("Endpoint = %s\n", peer.Endpoint))
		}
		if len(peer.AllowedIPs) > 0 {
			builder.WriteString(fmt.Sprintf("AllowedIPs = %s\n", strings.Join(peer.AllowedIPs, ", ")))
		}
		if peer.PersistentKeepalive > 0 {
			builder.WriteString(fmt.Sprintf("PersistentKeepalive = %d\n", peer.PersistentKeepalive))
		}
	}

	return builder.String()
}

// ValidateConfig performs basic validation on a WireGuard configuration
func ValidateConfig(config *WgConfig) error {
	if config.Interface.PrivateKey == "" {
		return fmt.Errorf("interface private key is required")
	}
	if config.Interface.Address == "" {
		return fmt.Errorf("interface address is required")
	}

	for i, peer := range config.Peers {
		if peer.PublicKey == "" {
			return fmt.Errorf("peer %d: public key is required", i)
		}
		if len(peer.AllowedIPs) == 0 {
			return fmt.Errorf("peer %d: at least one allowed IP is required", i)
		}
	}

	return nil
}
