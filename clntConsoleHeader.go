package main

import (
	"github.com/pterm/pterm"
)

func introSSHWireguardScreen() {
	//ptermLogo, _ := pterm.DefaultBigText.WithLetters(
	//pterm.NewLettersFromStringWithStyle("SSHwireguard", pterm.NewStyle(pterm.BgLightBlue))).
	//Srender()

	//pterm.DefaultCenter.Print(ptermLogo)

	credit := "#########################################\nSSHWireguard - Golang VPN client\nDuane Dunston - dunston@champlain.edu\n#########################################"
	pterm.DefaultCenter.Print(pterm.DefaultHeader.WithFullWidth().WithBackgroundStyle(pterm.NewStyle(pterm.BgLightBlue)).WithMargin(10).Sprint(credit))

}
