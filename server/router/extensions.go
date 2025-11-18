package router

import (
	"NanoKVM-Server/middleware"
	"NanoKVM-Server/service/extensions/tailscale"
	"NanoKVM-Server/service/extensions/wireguard"

	"github.com/gin-gonic/gin"
)

func extensionsRouter(r *gin.Engine) {
	api := r.Group("/api/extensions").Use(middleware.CheckToken())

	// Tailscale routes
	ts := tailscale.NewService()

	api.POST("/tailscale/install", ts.Install)     // install tailscale
	api.POST("/tailscale/uninstall", ts.Uninstall) // uninstall tailscale
	api.GET("/tailscale/status", ts.GetStatus)     // get tailscale status
	api.POST("/tailscale/up", ts.Up)               // run tailscale up
	api.POST("/tailscale/down", ts.Down)           // run tailscale down
	api.POST("/tailscale/login", ts.Login)         // tailscale login
	api.POST("/tailscale/logout", ts.Logout)       // tailscale logout
	api.POST("/tailscale/start", ts.Start)         // tailscale start
	api.POST("/tailscale/stop", ts.Stop)           // tailscale stop
	api.POST("/tailscale/restart", ts.Restart)     // tailscale restart

	// WireGuard routes - Using native kernel support
	wg := wireguard.NewService()

	api.GET("/wireguard/status", wg.GetStatus)       // get wireguard status
	api.POST("/wireguard/start", wg.Start)           // start wireguard
	api.POST("/wireguard/stop", wg.Stop)             // stop wireguard
	api.POST("/wireguard/restart", wg.Restart)       // restart wireguard
	api.POST("/wireguard/up", wg.Up)                 // bring interface up
	api.POST("/wireguard/down", wg.Down)             // bring interface down
	api.GET("/wireguard/config", wg.GetConfig)       // get wireguard config
	api.POST("/wireguard/config", wg.SaveConfig)     // save wireguard config
	api.POST("/wireguard/genkey", wg.GenerateKeys)   // generate keypair
	api.GET("/wireguard/peers", wg.GetPeers)         // get peers
}
