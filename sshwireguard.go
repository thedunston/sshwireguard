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
		if len(os.Args) > 2 {

			errorMsg(cliUsage)
			errorOne()
		}

		task := os.Args[1]

		switch task {

		case "init":

			createConf()

		case "stop":

			ctrl_wg("stop")

		case "start":

			ctrl_wg("start")

		case "reauth":

			getClientConfigs()

		default:

			errorMsg(cliUsage)
			os.Exit(1)

		}
	}

}
