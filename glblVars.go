package main

import (
	"os"
)

const (
	dirname      = "sshwireguardConf"
	wgConfig     = "/sshwireguardConf/sshwireguard.conf"
	clientConfig = "/sshwireguardConf/config.yaml"
)

/** Global variables */
var (
	cliUsage = `
Usage: sshwireguard [init|stop|start|status|renew]
sshwireguard init - Creates a new WireGuard VPN configuration directory
sshwireguard start - Starts the VPN Service
sshwireguard stop -  Stops the VPN Service
sshwireguard status - Checks if the VPN service is stopped or running
sshwireguard renew - Downloads a new VPN configuration
`

	// sshwireguardConf
	uHome = userHome()

	// Used in ctrlWireguard.go
	manageWgClient string

	// Used in ctrlClient.go
	//clientTask string
)

// Get user's home directory
func userHome() string {

	// Checking if current user information is unavailable
	homedir, err := os.UserHomeDir()
	checkErr(err, "User's Home Dir environment variable is not set.")

	return homedir

}
