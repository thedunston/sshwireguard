package main

/** Checks the OS and runs the respective command to manage wireguard. */

import (
	"fmt"
	"runtime"
)

func run_results(taskRunMsg string, theTask string) {

	if taskRunMsg == "Success" {

		successMsg("sshwireguard was " + theTask)

	} else {

		errorMsg("sshwireguard was not " + theTask + ". Please try again.")
	}

}

// Function is used to start the sshwireguard service.
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

		if runit == "start" {

			run_cmd("powershell -command start-process 'C:\\Windows\\System32\\sc.exe' -ArgumentList 'start WireGuardTunnel$sshwireguard' -Verb RunAs", "start")
			srvCheck(os, "started")

		} else if runit == "stop" {

			run_cmd("powershell -command start-process 'C:\\Windows\\System32\\sc.exe' -ArgumentList 'stop WireGuardTunnel$sshwireguard' -Verb RunAs", "stop")
			srvCheck(os, "stopped")

		} else {

			errorMsg("Nothing to do")
			errorOne()
		}

	case "darwin":
		fmt.Println("MAC operating system")

	case "linux":

		if runit == "start" {

			run_cmd("sudo wg-quick up "+uHome+wgConfig, "start")
			srvCheck(os, "started")

		} else if runit == "stop" {

			run_cmd("sudo wg-quick down "+uHome+wgConfig, "stop")
			srvCheck(os, "stopped")

		} else {

			errorMsg("Nothing to do!")

		}

	default:

		errorMsg("Nothing to do")
		errorOne()

	}

}
