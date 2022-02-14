package main

/** Executes the command to manage the Wireguard service or check running status */

import (
	"os/exec"
	"strings"
	"time"
)

// Function executes the respective command to start or stop
// the service.
// wg_run:  Command to start or stop the sshwireguard
// service.
// taskMsg: String is "start" or "stop"
func run_cmd(os string, wg_run string, taskMsg string) {

	// Split the command using spaces to manage the service
	args := strings.Fields(wg_run)

	// Run the wireguard command
	cmd := exec.Command(args[0], args[1:]...)

	// Execute the command
	_, err := cmd.CombinedOutput()
	checkErr(err, "Error running command: "+wg_run)

	// Pause to give service time to start/stop
	infoMsg("Please wait...")

	// Sleep for 5 seconds
	time.Sleep(5 * time.Second)

	// Check if service is stopped or stopped
	s := check_status(os, taskMsg)

	run_results(s, taskMsg)

}
