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
	cliUsage = "Usage: sshwireguard [init|stop|start|reauth]\n"

	// sshwireguardConf
	uHome = userHome()

	// Used in ctrlWireguard.go
	manageWgClient string

	// Used in ctrlClient.go
	//clientTask string
)

func userHome() string {

	// Checking if current user information is unavailable
	homedir, err := os.UserHomeDir()
	checkErr(err, "User's Home Dir environment variable is not set.")

	return homedir

}
