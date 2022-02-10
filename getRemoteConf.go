package main

import (
	"bytes"
	"os"

	"github.com/spf13/viper"
)

// Function to get the remote WireGuard configuration file
// The WireGuard configuration file is read from the user's
// home directory in the directory sshwireguardConf.
// It is also the location of the config file provided
// by the admin for the client.
func getClientConfigs() {

	// Read in the YAML configuration file
	data, err := os.ReadFile(uHome + clientConfig)

	checkErr(err, "Could not read sshwireguard configuration file.")

	// Convert YAML strings to bytes
	var _config = []byte(data)

	// Set config type to YAML
	viper.SetConfigType("yaml")
	viper.ReadConfig(bytes.NewBuffer(_config))

	// Get the values from the yaml file:
	username := viper.Get("username").(string)
	hostname := viper.Get("hostname").(string)
	hostport := viper.Get("hostport").(int)

	// Stop the currently running VPN sessions
	ctrl_wg("stop")

	// Remove the existing configurations
	wgConf := uHome + wgConfig
	clientConf := uHome + clientConfig
	fileExists(uHome+wgConf, uHome+clientConf, "remove")

	// Download the sshwireguard configuration files
	downloadClientConfig(username, hostname, hostport)

}
