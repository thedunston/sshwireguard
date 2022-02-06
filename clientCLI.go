package main

// Function to manage commandline arguments passed to sshwireguard client
// stop: Stop sshwireguard client Connection
// start: Starts sshwireguard client Connection
// reauth: Downloads the sshwireguard Configuration and starts the VPN
func ctrlClient(c string) {

	if c == "" {

		errorMsg(cliUsage)
		errorOne()

	}

	switch c {

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

	}

}
