package main

/** Checks the OS and runs the respective command to manage wireguard. */

import (
	"fmt"
	"log"
	"os/user"
	"runtime"
)

// Manage the Wireguard service
func ctrl_wg(theCtrl string) {

	os := runtime.GOOS

	runit := theCtrl
	switch os {

	case "windows":

		fmt.Println("Var: ", runit)
		if runit == "start" {

			usr, err := user.Current()
			if err != nil {
				log.Fatal(err)
			}
			//fmt.Println( usr.HomeDir )
			startWireguard = "wireguard.exe /installtunnelservice " + usr.HomeDir + "\\sshwireguardConf\\sshwireguard.conf"
			run_cmd(startWireguard)

		} else {

			// Check if VPN service is running.
			s := run_cmdPipe("sc query", "findstr /i sshwireguard")
			fmt.Println(s)
			if s != "" {

				startWireguard = "wireguard.exe /uninstalltunnelservice sshwireguard"

				run_cmd(startWireguard)

			}

		}

	case "darwin":
		fmt.Println("MAC operating system")

	case "linux":
		fmt.Println("Starting VPN Service...", runit)
		if runit == "start" {

			startWireguard = "wg-quick up ./sshwireguardConf/sshwireguard.conf"
			run_cmd(startWireguard)

			// Check if VPN service is running.
			s := run_cmdPipe("ip a", "grep sshwireguard")
			if s != "" {

				fmt.Println("\n****VPN Service started!****")

			} else {

				fmt.Println("\n****VPN Service was not started!  Please try again.****")

			}

		} else {

			// Check if VPN service is running.
			s := run_cmdPipe("ip a", "grep sshwireguard")
			if s != "" {

				// If so then stop it.
				startWireguard = "wg-quick down ./sshwireguardConf/sshwireguard.conf"

				run_cmd(startWireguard)

			}

		}

	default:

		fmt.Printf("%s.\n", os)

	}

}
