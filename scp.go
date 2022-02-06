package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func downloadClientConfig(username string, hostname string, hostport int) {

	// If the hostport is blank then set it to 22.
	if hostport == 0 {

		hostport = 22

	}

	// Start the native scp client and download the configuration files.
	c := fmt.Sprintf("scp -r -P %d %s@%s:%s .", hostport, username, hostname, dirname)
	x := strings.Fields(c)
	cmd := exec.Command(x[0], x[1:]...)

	// Execute the command and provide an interactive shell
	// where users type in their password and 2fa code
	// https://www.reddit.com/r/golang/comments/2nd4pq/how_can_i_open_an_interactive_subprogram_from/
	cmd.Stdout = os.Stdout
	cmd.Stdin = os.Stdin
	cmd.Stderr = os.Stderr
	_ = cmd.Run()

	// Check if the VPN config file download was successful
	fileExists(uHome+wgConfig, clientConfig, "getCheck")

	// Run the appropriate command based on the OS.
	ctrl_wg("start")

}
