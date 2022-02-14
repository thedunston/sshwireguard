package main

import (
	"os/exec"
	"strings"
)

// Function checks the status to determine if the sshwireguard Tunnel is running
// or not running.
func check_status(os string, taskMsg string) string {

	wg_run := ""

	if os == "windows" {

		// Command to check on status of sshwireguard service
		wg_run = "sc query WireGuardTunnel$sshwireguard"

		// *nix
	} else {

		// Command to check on status of sshwireguard service
		wg_run = "ip a show dev sshwireguard"

	}

	// Split the command for execution
	args := strings.Fields(wg_run)

	// Format the command to run
	cmd := exec.Command(args[0], args[1:]...)

	// Execute the command
	results, _ := cmd.CombinedOutput()

	// Get the results
	cmdResults := check_output(string(results), taskMsg)

	return cmdResults

}
