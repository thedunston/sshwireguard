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

		ctrlClient("init")

	} else {

		// Check that there is an argument provided
		if len(os.Args) < 2 {

			errorMsg(cliUsage)
			errorOne()
		}

		// Get first argument from CLI
		ctrlClient(os.Args[1])

	}

}
