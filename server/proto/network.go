package proto

type WakeOnLANReq struct {
	Mac string `form:"mac" validate:"required"`
}

type GetMacRsp struct {
	Macs []string `json:"macs"`
}

type DeleteMacReq struct {
	Mac string `form:"mac" validate:"required"`
}

type TailscaleState string

const (
	TailscaleNotInstall TailscaleState = "notInstall"
	TailscaleNotRunning TailscaleState = "notRunning"
	TailscaleNotLogin   TailscaleState = "notLogin"
	TailscaleStopped    TailscaleState = "stopped"
	TailscaleRunning    TailscaleState = "running"
)

type GetTailscaleStatusRsp struct {
	State   TailscaleState `json:"state"`
	Name    string         `json:"name"`
	IP      string         `json:"ip"`
	Account string         `json:"account"`
}

type LoginTailscaleRsp struct {
	Url string `json:"url"`
}

type GetWifiRsp struct {
	Supported bool `json:"supported"`
	Connected bool `json:"connected"`
}

// WireGuard types

type WireGuardState string

const (
	WireGuardNotInstall    WireGuardState = "notInstall"
	WireGuardNotRunning    WireGuardState = "notRunning"
	WireGuardNotConfigured WireGuardState = "notConfigured"
	WireGuardRunning       WireGuardState = "running"
	WireGuardConnected     WireGuardState = "connected"
)

type WireGuardInterfaceReq struct {
	Interface string `json:"interface"`
}

type GetWireGuardStatusRsp struct {
	State       WireGuardState `json:"state"`
	Interface   string         `json:"interface"`
	PublicKey   string         `json:"publicKey,omitempty"`
	Address     string         `json:"address,omitempty"`
	ListenPort  int            `json:"listenPort,omitempty"`
	PeerCount   int            `json:"peerCount"`
	IsRunning   bool           `json:"isRunning"`
	IsConnected bool           `json:"isConnected"`
}

type GetWireGuardConfigRsp struct {
	Interface string `json:"interface"`
	Config    string `json:"config"`
}

type SaveWireGuardConfigReq struct {
	Interface string `json:"interface"`
	Config    string `json:"config" validate:"required"`
}

type GenerateWireGuardKeysRsp struct {
	PrivateKey string `json:"privateKey"`
	PublicKey  string `json:"publicKey"`
}

type WireGuardPeer struct {
	PublicKey           string   `json:"publicKey"`
	Endpoint            string   `json:"endpoint,omitempty"`
	AllowedIPs          []string `json:"allowedIPs"`
	LatestHandshake     int64    `json:"latestHandshake"`
	TransferRx          int64    `json:"transferRx"`
	TransferTx          int64    `json:"transferTx"`
	PersistentKeepalive int      `json:"persistentKeepalive,omitempty"`
}

type GetWireGuardPeersRsp struct {
	Interface string          `json:"interface"`
	Peers     []WireGuardPeer `json:"peers"`
}
