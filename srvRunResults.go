package main

import "fmt"

// Function displays whether the service task was pwerformed
// successfully or unsuccessfully
func run_results(taskRunMsg string, theTask string) {

	fmt.Println(taskRunMsg + " " + theTask)
	// Print message based on the status of running the command
	switch taskRunMsg {
	case "Success":

		if theTask == "status" {

			infoMsg("sshwireguard is running")

		} else {

			successMsg("sshwireguard was " + theTask)

		}

	case "Error":

		if theTask == "status" {

			infoMsg("sshwireguard is not running")

			// Message when manually stopping the VPN service
		} else if theTask == "stopped" {

			successMsg("sshwireguard was stopped")

			// Message when the VPN service was running, but did not stop
		} else {

			errorMsg("sshwireguard was not " + theTask + ". Please try again.")

		}

	default:

		infoMsg("Nothing to do!rr")
		errorOne()

	}
}
