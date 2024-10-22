package main

// SCP to a remote user using 2FA

import (
	"os"
)

func main() {

	// Default terminal window header
	introSSHWireguardScreen()

	// Check if the sshwireguardConf folder exists in the user's
	// home directory.
	_, err := os.Stat(uHome + "/" + dirname)
	if os.IsNotExist(err) {

		createConf()

	} else {

		// Check that there is an argument provided
		if len(os.Args) > 2 || len(os.Args) == 1 {

			infoMsg(cliUsage)

		} else if len(os.Args) == 1 {

			infoMsg(cliUsage)

		} else {

			task := os.Args[1]

			switch task {

			case "init":

				createConf()

			case "stop":

				ctrl_wg("stop")

			case "start":

				ctrl_wg("start")

			case "renew":

				getClientConfigs()

			case "status":

				ctrl_wg("status")

			default:

				infoMsg(cliUsage)
				os.Exit(1)

			}

		}
	}

}
