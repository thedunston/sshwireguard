package main

/** Checks the OS and runs the respective command to manage wireguard. */

import (
	"fmt"
	"os"
	"runtime"
)

func userHome() string {

	// Checking if current user information is unavailable
	homedir, err := os.UserHomeDir()
	checkErr(err, "User's Home Dir environment variable is not set.")

	return homedir

}

// Function is used to stop the sshwireguard service.
// The arguments can have one or two parameters.
// If no pipe is needed to check for the service running set the arg_2 parameter to "None"
//
// Example: srvStop(ip addr show dev sshwireguard, "", wg-quick down sshwireguardConf/sshwireguard.conf)
//
// If the service requires a Pipe then don't include the pipe, but the text after the pipe.
//
// Example: srvStop("sc query", "findstr sshwireguard", "wireguard.exe /uninstalltunnelservice sshwireguard")
//
// would be the same as:
//
// sc query | findstr sshwireguard
//
// Windows returns a multiline error if sshwireguard is not running so the above query will return no
// information if it is not running.
func srvStop(arg_1 string, arg_2 string, stopCmd string) {

	var s string

	if arg_2 == "None" {

		s = run_cmd(arg_1)

	} else {

		// Check if VPN service is running.
		s = run_cmdPipe(arg_1, arg_2)

	}

	if s != "" {

		// If so then stop it.
		manageWgClient = stopCmd

		// Execute the command
		s := run_cmd(manageWgClient)

		if s == "Success" {

			successMsg("sshwireguard was stopped.")

		} else {

			errorMsg("sshwireguard was not stopped.  Please try again")
		}

	} else {

		infoMsg("sshwireguard is not running.")
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
func srvStart(arg_1 string, arg_2 string, startCmd string) {

	var s string

	if arg_2 == "None" {

		s = run_cmd(arg_1)

	} else {

		// Check if sshwireguard service is running.
		s = run_cmdPipe(arg_1, arg_2)

	}

	if s == "" {

		// Start command for windows
		manageWgClient = startCmd

		// Execute the command
		s := run_cmd(manageWgClient)

		// Check run status
		if s == "Success" {

			successMsg("VPN Started!")
			successZero()

		} else {

			errorMsg("The service did not start properly.  Please try again!")
			errorOne()

		}

	} else {

		infoMsg("sshwireguard is already running.")

	}

}

// Manage the Wireguard service
func ctrl_wg(runit string) {

	os := runtime.GOOS

	switch os {

	case "windows":

		if runit == "start" {

			srvStart("sc query", "findstr sshwireguard", "wireguard.exe /installtunnelservice "+uHome+wgConfig)

		} else if runit == "stop" {

			srvStop("sc query", "findstr /i sshwireguard", "wireguard.exe /uninstalltunnelservice sshwireguard")

		} else {

			errorMsg("Nothing to do")
			errorOne()
		}

	case "darwin":
		fmt.Println("MAC operating system")

	case "linux":

		if runit == "start" {

			srvStart("ip a", "grep sshwireguard", "sudo wg-quick up "+uHome+wgConfig)

		} else if runit == "stop" {

			srvStop("ip a", "grep sshwireguard", "sudo wg-quick down "+uHome+wgConfig)

		} else {

			errorMsg("Nothing to do!")

		}

	default:

		errorMsg("Nothing to do")
		errorOne()

	}

}
