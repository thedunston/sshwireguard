package main

/** Checks the OS and runs the respective command to manage wireguard. */

import (
	"fmt"
	"log"
	"os"
	"runtime"
	"time"
)

// Manage the Wireguard service
func ctrl_wg(theCtrl string) {

	os := runtime.GOOS

	runit := theCtrl
	switch os {

	case "windows":

		// Start the service
		if runit == "start" {

			// Checking if current user information is unavailable
			uHome, err := os.UserHomeDir()
			if err != nil {
				log.Fatal(err)
			}
			
			infoMsg("Starting sshwireguard...")
			
			// Start command for windows
			manageWgClient = "wireguard.exe /installtunnelservice " + uHome + "\\sshwireguardConf\\sshwireguard.conf"
			s :=run_cmd(manageWgClient)

			if (s == "Success") {

				successMsg("VPN Started!")
				msgSleep()
				successZero()

			} else {

				errorMsg("The service did not start properly.  Please try again!")
				msgSleep()
				errorOne()

			}

		} else if runit == "stop" {

			// Check if VPN service is running.
			s := run_cmdPipe("sc query", "findstr /i sshwireguard")
			fmt.Println(s)
			if s != "" {

				manageWgClient = "wireguard.exe /uninstalltunnelservice sshwireguard"
				s = run_cmd(startWireguard)
				if (s == "Success") {

					successMsg(("sshwireguad stopped.")
					msgSleep()
				}
			} else {

				infoMsg("sshwireguard Service is not running.")
				msgSleep()
				successZero()

			}

		} else if runit == "restart" {

			// Stop the VPN Service
			manageWgClient = "wireguard.exe /uninstalltunnelservice sshwireguard"
			s := run_cmd(startWireguard)
			
			if s == "Success" {

				// Start the VPN Service
				manageWgClient = "wireguard.exe /installtunnelservice " + uHome + "\\sshwireguardConf\\sshwireguard.conf"
				run_cmd(startWireguard)

			} else {

				infoMsg("sshwireguard Service is not running.")

			}


		} else {

				errorMsg("Nothing to do")
				os.Exit(1)
		}

	case "darwin":
		fmt.Println("MAC operating system")

	case "linux":
		fmt.Println("Starting VPN Service...", runit)
		if runit == "start" {

			manageWgClient = "wg-quick up ./sshwireguardConf/sshwireguard.conf"
			run_cmd(manageWgClient)

			// Check if VPN service is running.
			s := run_cmdPipe("ip a", "grep sshwireguard")
			if s != "" {

				successMsg("\n****VPN Service started!****")

			} else {

				errorMsg("\n****VPN Service was not started!  Please try again.****")


			}

		} else {

			// Check if VPN service is running.
			s := run_cmdPipe("ip a", "grep sshwireguard")
			if s != "" {

				// If so then stop it.
				manageWgClient = "wg-quick down ./sshwireguardConf/sshwireguard.conf"

				run_cmd(manageWgClient)

			}

		}

	default:

		errorMsg("Nothing to do")
		errorOne()

	}

}
