package wireguard

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

type Cli struct{}

type WgStatus struct {
	Interface   string
	PublicKey   string
	PrivateKey  string
	ListenPort  int
	Address     string
	Peers       []WgPeer
	IsRunning   bool
	IsConnected bool
}

type WgPeer struct {
	PublicKey           string
	Endpoint            string
	AllowedIPs          []string
	LatestHandshake     int64
	TransferRx          int64
	TransferTx          int64
	PersistentKeepalive int
}

func NewCli() *Cli {
	return &Cli{}
}

func (c *Cli) Start() error {
	// Ensure config directory exists
	if err := os.MkdirAll(ConfigDir, 0o700); err != nil {
		return err
	}

	// Use wg-quick to bring up the interface
	// This will load the kernel module automatically
	command := fmt.Sprintf("wg-quick up %s", DefaultInterface)
	return exec.Command("sh", "-c", command).Run()
}

func (c *Cli) Restart() error {
	// Try to stop first, ignore errors if interface is not up
	_ = c.Stop()
	return c.Start()
}

func (c *Cli) Stop() error {
	// Use wg-quick to bring down the interface
	command := fmt.Sprintf("wg-quick down %s", DefaultInterface)
	return exec.Command("sh", "-c", command).Run()
}

func (c *Cli) Up(interfaceName string) error {
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}
	command := fmt.Sprintf("wg-quick up %s", interfaceName)
	return exec.Command("sh", "-c", command).Run()
}

func (c *Cli) Down(interfaceName string) error {
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}
	command := fmt.Sprintf("wg-quick down %s", interfaceName)
	return exec.Command("sh", "-c", command).Run()
}

func (c *Cli) Status(interfaceName string) (*WgStatus, error) {
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}

	status := &WgStatus{
		Interface: interfaceName,
		Peers:     []WgPeer{},
	}

	// Check if interface exists
	cmd := exec.Command("sh", "-c", fmt.Sprintf("ip link show %s", interfaceName))
	if err := cmd.Run(); err != nil {
		status.IsRunning = false
		return status, nil
	}
	status.IsRunning = true

	// Get interface configuration
	cmd = exec.Command("sh", "-c", fmt.Sprintf("wg show %s dump", interfaceName))
	output, err := cmd.CombinedOutput()
	if err != nil {
		return status, err
	}

	// Parse output
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	if len(lines) > 0 {
		// First line is interface info
		fields := strings.Split(lines[0], "\t")
		if len(fields) >= 3 {
			status.PrivateKey = fields[0]
			status.PublicKey = fields[1]
			if fields[2] != "(none)" && fields[2] != "" {
				fmt.Sscanf(fields[2], "%d", &status.ListenPort)
			}
		}

		// Remaining lines are peers
		for i := 1; i < len(lines); i++ {
			fields := strings.Split(lines[i], "\t")
			if len(fields) >= 8 {
				peer := WgPeer{
					PublicKey: fields[0],
				}

				if fields[2] != "(none)" && fields[2] != "" {
					peer.Endpoint = fields[2]
				}

				if fields[3] != "(none)" && fields[3] != "" {
					peer.AllowedIPs = strings.Split(fields[3], ",")
				}

				if fields[4] != "0" {
					fmt.Sscanf(fields[4], "%d", &peer.LatestHandshake)
				}

				fmt.Sscanf(fields[5], "%d", &peer.TransferRx)
				fmt.Sscanf(fields[6], "%d", &peer.TransferTx)

				if fields[7] != "off" && fields[7] != "0" {
					fmt.Sscanf(fields[7], "%d", &peer.PersistentKeepalive)
				}

				status.Peers = append(status.Peers, peer)

				// If we have a recent handshake, consider it connected
				if peer.LatestHandshake > 0 {
					status.IsConnected = true
				}
			}
		}
	}

	// Get interface IP address
	cmd = exec.Command("sh", "-c", fmt.Sprintf("ip -4 addr show %s | grep inet | awk '{print $2}'", interfaceName))
	if output, err := cmd.CombinedOutput(); err == nil {
		status.Address = strings.TrimSpace(string(output))
	}

	return status, nil
}

func (c *Cli) GeneratePrivateKey() (string, error) {
	cmd := exec.Command("sh", "-c", "wg genkey")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func (c *Cli) GeneratePublicKey(privateKey string) (string, error) {
	cmd := exec.Command("sh", "-c", fmt.Sprintf("echo '%s' | wg pubkey", privateKey))
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func (c *Cli) GenerateKeypair() (privateKey string, publicKey string, err error) {
	privateKey, err = c.GeneratePrivateKey()
	if err != nil {
		return "", "", err
	}

	publicKey, err = c.GeneratePublicKey(privateKey)
	if err != nil {
		return "", "", err
	}

	return privateKey, publicKey, nil
}

func (c *Cli) SetConfig(interfaceName string, configPath string) error {
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}
	command := fmt.Sprintf("wg setconf %s %s", interfaceName, configPath)
	return exec.Command("sh", "-c", command).Run()
}

func (c *Cli) SyncConfig(interfaceName string, configPath string) error {
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}
	command := fmt.Sprintf("wg syncconf %s %s", interfaceName, configPath)
	return exec.Command("sh", "-c", command).Run()
}

// GetConfigJSON returns the current WireGuard configuration as JSON
func (c *Cli) GetConfigJSON(interfaceName string) (string, error) {
	status, err := c.Status(interfaceName)
	if err != nil {
		return "", err
	}

	data, err := json.MarshalIndent(status, "", "  ")
	if err != nil {
		return "", err
	}

	return string(data), nil
}
