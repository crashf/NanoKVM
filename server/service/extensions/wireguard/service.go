package wireguard

import (
	"NanoKVM-Server/proto"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type Service struct{}

func NewService() *Service {
	return &Service{}
}

// Install/Uninstall not needed - WireGuard is built into the kernel
// and wg utility is already installed on NanoKVM

func (s *Service) Start(c *gin.Context) {
	var rsp proto.Response

	err := NewCli().Start()
	if err != nil {
		rsp.ErrRsp(c, -1, "start failed")
		log.Errorf("failed to start WireGuard: %s", err)
		return
	}

	rsp.OkRsp(c)
	log.Debugf("WireGuard start successfully")
}

func (s *Service) Restart(c *gin.Context) {
	var rsp proto.Response

	err := NewCli().Restart()
	if err != nil {
		rsp.ErrRsp(c, -1, "restart failed")
		log.Errorf("failed to restart WireGuard: %s", err)
		return
	}

	rsp.OkRsp(c)
	log.Debugf("WireGuard restart successfully")
}

func (s *Service) Stop(c *gin.Context) {
	var rsp proto.Response

	err := NewCli().Stop()
	if err != nil {
		rsp.ErrRsp(c, -1, "stop failed")
		log.Errorf("failed to stop WireGuard: %s", err)
		return
	}

	rsp.OkRsp(c)
	log.Debugf("WireGuard stop successfully")
}

func (s *Service) Up(c *gin.Context) {
	var req proto.WireGuardInterfaceReq
	var rsp proto.Response

	if err := c.ShouldBindJSON(&req); err != nil {
		rsp.ErrRsp(c, -1, "invalid request")
		return
	}

	err := NewCli().Up(req.Interface)
	if err != nil {
		rsp.ErrRsp(c, -1, "wireguard up failed")
		log.Errorf("failed to run wireguard up: %s", err)
		return
	}

	rsp.OkRsp(c)
	log.Debugf("run wireguard up successfully")
}

func (s *Service) Down(c *gin.Context) {
	var req proto.WireGuardInterfaceReq
	var rsp proto.Response

	if err := c.ShouldBindJSON(&req); err != nil {
		rsp.ErrRsp(c, -1, "invalid request")
		return
	}

	err := NewCli().Down(req.Interface)
	if err != nil {
		rsp.ErrRsp(c, -1, "wireguard down failed")
		log.Errorf("failed to run wireguard down: %s", err)
		return
	}

	rsp.OkRsp(c)
	log.Debugf("run wireguard down successfully")
}

func (s *Service) GetStatus(c *gin.Context) {
	var rsp proto.Response

	interfaceName := c.Query("interface")
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}

	// WireGuard is built into NanoKVM kernel - no need to check if installed
	status, err := NewCli().Status(interfaceName)
	if err != nil {
		log.Debugf("failed to get WireGuard status: %s", err)
		rsp.OkRspWithData(c, &proto.GetWireGuardStatusRsp{
			State:     proto.WireGuardNotRunning,
			Interface: interfaceName,
		})
		return
	}

	state := proto.WireGuardNotRunning
	if status.IsRunning {
		if status.IsConnected {
			state = proto.WireGuardConnected
		} else if ConfigExists(interfaceName) {
			state = proto.WireGuardRunning
		} else {
			state = proto.WireGuardNotConfigured
		}
	}

	data := proto.GetWireGuardStatusRsp{
		State:       state,
		Interface:   status.Interface,
		PublicKey:   status.PublicKey,
		Address:     status.Address,
		ListenPort:  status.ListenPort,
		PeerCount:   len(status.Peers),
		IsRunning:   status.IsRunning,
		IsConnected: status.IsConnected,
	}

	rsp.OkRspWithData(c, &data)
	log.Debugf("get WireGuard status successfully")
}

func (s *Service) GetConfig(c *gin.Context) {
	var rsp proto.Response

	interfaceName := c.Query("interface")
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}

	config, err := LoadConfig(interfaceName)
	if err != nil {
		rsp.ErrRsp(c, -1, "failed to load config")
		log.Errorf("failed to load config: %s", err)
		return
	}

	rsp.OkRspWithData(c, &proto.GetWireGuardConfigRsp{
		Interface: interfaceName,
		Config:    config,
	})
	log.Debugf("get WireGuard config successfully")
}

func (s *Service) SaveConfig(c *gin.Context) {
	var req proto.SaveWireGuardConfigReq
	var rsp proto.Response

	if err := c.ShouldBindJSON(&req); err != nil {
		rsp.ErrRsp(c, -1, "invalid request")
		return
	}

	interfaceName := req.Interface
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}

	// Validate configuration
	parsedConfig, err := ParseConfig(req.Config)
	if err != nil {
		rsp.ErrRsp(c, -2, "invalid config format")
		log.Errorf("failed to parse config: %s", err)
		return
	}

	if err := ValidateConfig(parsedConfig); err != nil {
		rsp.ErrRsp(c, -3, err.Error())
		log.Errorf("config validation failed: %s", err)
		return
	}

	// Save configuration
	if err := SaveConfig(interfaceName, req.Config); err != nil {
		rsp.ErrRsp(c, -4, "failed to save config")
		log.Errorf("failed to save config: %s", err)
		return
	}

	rsp.OkRsp(c)
	log.Debugf("save WireGuard config successfully")
}

func (s *Service) GenerateKeys(c *gin.Context) {
	var rsp proto.Response

	cli := NewCli()
	privateKey, publicKey, err := cli.GenerateKeypair()
	if err != nil {
		rsp.ErrRsp(c, -1, "failed to generate keys")
		log.Errorf("failed to generate keys: %s", err)
		return
	}

	rsp.OkRspWithData(c, &proto.GenerateWireGuardKeysRsp{
		PrivateKey: privateKey,
		PublicKey:  publicKey,
	})
	log.Debugf("generate WireGuard keys successfully")
}

func (s *Service) GetPeers(c *gin.Context) {
	var rsp proto.Response

	interfaceName := c.Query("interface")
	if interfaceName == "" {
		interfaceName = DefaultInterface
	}

	status, err := NewCli().Status(interfaceName)
	if err != nil {
		rsp.ErrRsp(c, -1, "failed to get peers")
		log.Errorf("failed to get peers: %s", err)
		return
	}

	peers := make([]proto.WireGuardPeer, 0, len(status.Peers))
	for _, peer := range status.Peers {
		peers = append(peers, proto.WireGuardPeer{
			PublicKey:           peer.PublicKey,
			Endpoint:            peer.Endpoint,
			AllowedIPs:          peer.AllowedIPs,
			LatestHandshake:     peer.LatestHandshake,
			TransferRx:          peer.TransferRx,
			TransferTx:          peer.TransferTx,
			PersistentKeepalive: peer.PersistentKeepalive,
		})
	}

	rsp.OkRspWithData(c, &proto.GetWireGuardPeersRsp{
		Interface: interfaceName,
		Peers:     peers,
	})
	log.Debugf("get WireGuard peers successfully")
}
