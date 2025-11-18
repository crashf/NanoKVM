package wireguard

import (
	"NanoKVM-Server/utils"
	"fmt"
	"io"
	"net/http"
	"os"

	log "github.com/sirupsen/logrus"
)

const (
	// TODO: Replace with actual hosted URL after building binaries
	OriginalURL = "https://github.com/YOUR_USERNAME/wireguard-riscv64/releases/latest/download/wireguard_riscv64.tgz"
	Workspace   = "/root/.wireguard"
)

func isInstalled() bool {
	_, err1 := os.Stat(WireGuardGoPath)
	_, err2 := os.Stat(WgPath)
	_, err3 := os.Stat(WgQuickPath)

	return err1 == nil && err2 == nil && err3 == nil
}

func install() error {
	_ = os.MkdirAll(Workspace, 0o755)
	defer func() {
		_ = os.RemoveAll(Workspace)
	}()

	tarFile := fmt.Sprintf("%s/wireguard_riscv64.tgz", Workspace)

	// download
	if err := download(tarFile); err != nil {
		log.Errorf("failed to download WireGuard: %s", err)
		return err
	}

	// decompress
	dir, err := utils.UnTarGz(tarFile, Workspace)
	if err != nil {
		log.Errorf("failed to decompress WireGuard: %s", err)
		return err
	}

	// move wireguard-go
	wireguardGoPath := fmt.Sprintf("%s/wireguard-go", dir)
	err = utils.MoveFile(wireguardGoPath, WireGuardGoPath)
	if err != nil {
		log.Errorf("failed to move wireguard-go: %s", err)
		return err
	}

	// move wg
	wgPath := fmt.Sprintf("%s/wg", dir)
	err = utils.MoveFile(wgPath, WgPath)
	if err != nil {
		log.Errorf("failed to move wg: %s", err)
		return err
	}

	// move wg-quick
	wgQuickPath := fmt.Sprintf("%s/wg-quick", dir)
	err = utils.MoveFile(wgQuickPath, WgQuickPath)
	if err != nil {
		log.Errorf("failed to move wg-quick: %s", err)
		return err
	}

	// create config directory
	_ = os.MkdirAll("/etc/wireguard", 0o700)

	// create sysctl config for IP forwarding
	err = createSysctlConfig()
	if err != nil {
		log.Errorf("failed to create sysctl config: %s", err)
		// non-fatal error, continue
	}

	log.Debugf("install WireGuard successfully")
	return nil
}

func download(target string) error {
	url, err := getDownloadURL()
	if err != nil {
		log.Errorf("failed to get WireGuard download url: %s", err)
		return err
	}

	resp, err := http.Get(url)
	if err != nil {
		log.Errorf("failed to download WireGuard: %s", err)
		return err
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	out, err := os.Create(target)
	if err != nil {
		log.Errorf("failed to create file: %s", err)
		return err
	}
	defer func() {
		_ = out.Close()
	}()

	_, err = io.Copy(out, resp.Body)
	if err != nil {
		log.Errorf("failed to copy response body to file: %s", err)
		return err
	}

	log.Debugf("download WireGuard successfully")
	return nil
}

func getDownloadURL() (string, error) {
	resp, err := (&http.Client{}).Get(OriginalURL)
	if err != nil {
		return "", err
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusFound {
		return "", fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	return resp.Request.URL.String(), nil
}

func createSysctlConfig() error {
	configContent := `# WireGuard sysctl configuration
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
`

	err := os.WriteFile(SysctlConfigPath, []byte(configContent), 0o644)
	if err != nil {
		return err
	}

	log.Debugf("created sysctl config successfully")
	return nil
}
