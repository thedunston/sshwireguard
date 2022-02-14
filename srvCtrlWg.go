package main

/** Checks the OS and runs the respective command to manage wireguard. */

import (
	"fmt"
	"runtime"
)

// Function is used to manage the sshwireguard service.
// The arguments can have one or two parameters.
// If no pipe is needed to check for the service running set the arg_2 parameter to "None"
//
// Example: srvStart(ip addr show dev sshwireguard, "", wg-quick up sshwireguardConf/sshwireguard.conf)
//
// If the service requires a Pipe then don't include the pipe, but the text after the pipe.
//
// Example: srvStart("sc query", "findstr sshwireguard", "wireguard.exe /uninstalltunnelservice ireguard.exe /installtunnelservice " + uHome + "\\sshwireguardConf\\sshwireguard.conf"")
//
// would be the same as:
//
// sc query | findstr sshwireguard
//
// The above line will return output and that is checked to determine if the service is running.
// Manage the Wireguard service
func ctrl_wg(runit string) {

	os := runtime.GOOS

	switch os {

	case "windows":

		// Invoke Powershell to start and stop the sshwireguard Tunnel and elevate to admin.
		if runit == "start" {

			run_cmd(os, "powershell -command start-process 'C:\\Windows\\System32\\sc.exe' -ArgumentList 'start WireGuardTunnel$sshwireguard' -Verb RunAs", "started")

		} else if runit == "stop" {

			run_cmd(os, "powershell -command start-process 'C:\\Windows\\System32\\sc.exe' -ArgumentList 'stop WireGuardTunnel$sshwireguard' -Verb RunAs", "stopped")

		} else if runit == "status" {

			s := check_status(os, "status")

			run_results(s, "status")

		} else {

			errorMsg("Nothing to do")
			errorOne()
		}

	case "darwin":
		fmt.Println("MAC operating system")

	case "linux":

		if runit == "start" {

			// Sudo is used to start and stop the service
			run_cmd(os, "sudo wg-quick up "+uHome+wgConfig, "started")

		} else if runit == "stop" {

			run_cmd(os, "sudo wg-quick down "+uHome+wgConfig, "stopped")

		} else if runit == "status" {

			s := check_status(os, "status")

			run_results(s, "status")

		} else {

			errorMsg("Nothing to do!")

		}

	default:

		errorMsg("Nothing to do")
		errorOne()

	}

}
