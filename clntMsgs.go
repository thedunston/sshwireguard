package main

// Print messages to the console for the user.
// Includes a prompt so the user can see the message
// and acknowledge it.

import (
	"bufio"
	"os"

	"github.com/pterm/pterm"
)

// Prompt when messages are printed to allow the user
// to see the message and acknowledge it.
func toContinue() {

	pterm.Info.Println("Press 'Enter' to continue...")
	bufio.NewReader(os.Stdin).ReadBytes('\n')

}

// Generic check for errors
func checkErr(theError error, errString string) {

	if theError != nil {

		// Print default error.
		pterm.Error.Println(errString)
		toContinue()
		os.Exit(1)
	}

}

// Command was not completed successfully
func errorMsg(theError string) {

	// Print default error.
	pterm.Error.Println(theError)

}

// Command completed successfully
func successMsg(theSuccess string) {

	// Print default Success
	pterm.Success.Println(theSuccess)

}

// General Informational message
func infoMsg(theInfo string) {

	// Print default Info message
	pterm.Info.Println(theInfo)

}

// Unsucessful command execution returns 1
func errorOne() {

	os.Exit(1)
}

// Sucessful command execution returns 0
func successZero() {

	os.Exit(0)
}
