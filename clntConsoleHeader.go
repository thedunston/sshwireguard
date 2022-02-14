package main

import (
	"github.com/pterm/pterm"
)

// Using the pterm package for cross-platform terminal colors
// and status messages.
func introSSHWireguardScreen() {

	credit := "#########################################\nSSHWireguard - Golang VPN client\nDuane Dunston - dunston@champlain.edu\n#########################################"
	pterm.DefaultCenter.Print(pterm.DefaultHeader.WithFullWidth().WithBackgroundStyle(pterm.NewStyle(pterm.BgLightBlue)).WithMargin(10).Sprint(credit))

}
