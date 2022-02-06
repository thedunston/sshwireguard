package main

// Creates the sshwiregard configuration directory and default config file.
// After the user authenticates to the SSH server, their admin provided
// WireGuard VPN configuration file and config file will be downloaded.

import (
	"fmt"
)

func createConf() {

	var username string
	var hostname string
	var port int

	infoMsg("Creating a new sshwireguard configuration...")

	// Username
	fmt.Print("Enter your username on the VPN server: ")
	fmt.Scanf("%s", &username)

	// hostname
	fmt.Print("Enter the IP or Hostname of the VPN server: ")
	fmt.Scanf("%s", &hostname)

	// port, if other than 22
	fmt.Print("Enter the port number. [Default: 22] ")
	fmt.Scanf("%s", &port)

	// Get the VPN client configuration
	downloadClientConfig(username, hostname, port)

}
