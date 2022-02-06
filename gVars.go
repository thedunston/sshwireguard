package main

const (
	dirname      = "sshwireguardConf"
	wgConfig     = "/sshwireguardConf/sshwireguard.conf"
	clientConfig = "/sshwireguardConf/config.yaml"
	//wgConfig_win     = "\\sshwireguardConf\\sshwireguard.conf"
	//clientConfig_win = "\\sshwireguardConf\\config.yaml"
)

/** Global variables */
var (
	cliUsage = "Usage: sshwireguard [init|stop|start|reauth]\n"

	// sshwireguardConf
	uHome = userHome()

	// Used in ctrlWireguard.go
	manageWgClient string

	// Used in ctrlClient.go
	clientTask string
)
