package main

// SCP to a remote user using 2FA

import (

	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/viper"
)

func main() {

	// Read in the YAML configuration file
	data, err := os.ReadFile("config.yaml")

	// Convert YAML strings to bytes
	var _config = []byte(data)

	// Set config type to YAML
	viper.SetConfigType("yaml")
	viper.ReadConfig(bytes.NewBuffer(_config))

	// Get the triblets:
	username := viper.Get("username").(string)
	//authType := viper.Get("authType").(string)
	hostname := viper.Get("hostname").(string)
	hostport := viper.Get("hostport").(int)
	//type2fa := viper.Get("type2fa").(string)

	// Filename to retrieve
	filename := "sshwireguardConf"

	// Stop the currently running VPN sessions
	ctrl_wg("stop")
	// Remove the existing configurations
	f := "sshwireguardConf/sshwireguard.conf"
	g := "sshwireguardConf/config.yaml"
	fileExists(f, g, "remove")

	fmt.Println("###############################")
	fmt.Println("#     SSHWireguard Login      #")
	fmt.Println("###############################")
	c := fmt.Sprintf("scp -r -P %d %s@%s:%s .", hostport, username, hostname, filename)
	x := strings.Fields(c)
	cmd := exec.Command(x[0], x[1:]...)

	// Execute the command and provide an interactive shell
	// where users type in their password and 2fa code
	// https://www.reddit.com/r/golang/comments/2nd4pq/how_can_i_open_an_interactive_subprogram_from/
	cmd.Stdout = os.Stdout
	cmd.Stdin = os.Stdin
	cmd.Stderr = os.Stderr
	err = cmd.Run()

	// Check if the VPN config file download was successful
	fileExists(f, g, "getCheck")

	/**
	  to start: "c:\Program Files\WireGuard\wireguard.exe" /installtunnelservice c:\wg0.conf

	  to stop: "c:\Program Files\WireGuard\wireguard.exe" /uninstalltunnelservice wg0

	  to display other possible command line options: "c:\Program Files\WireGuard\wireguard.exe" -h

	*/

	// Run the appropriate command based on the OS.
	ctrl_wg("start")

	checkErr(err, "Starting the VPN failed.")

}
