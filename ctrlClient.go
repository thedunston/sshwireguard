package main

import "flag"

func ctrlClient(clientTask string) {

	flag.StringVar(&clientTask, "stop", "", "Stop sshwireguard client Connection")
	flag.StringVar(&clientTask, "start", "", "Starts sshwireguard client Connection")
	flag.StringVar(&clientTask, "restart", "", "Restarts sshwireguard client Connection")
	flag.StringVar(&clientTask, "reauth", "", "Downloads the sshwireguard Configuration and starts the VPN")
	flag.Parse()

	switch clientTask {

	case "stop":

		ctrl_wg("stop")

	case "start":

		ctrl_wg("start")

	case "restart":

		ctrl_wg("restart")

	case "reauth":

	default:

	}

}
