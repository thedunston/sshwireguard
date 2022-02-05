package main

/** Print messags to the console */

import (
	//"fmt"
	//"log"
	"os"
	"time"

	"github.com/pterm/pterm"
)

// Generic check for errors
func checkErr(theError error, errString string) {

	if theError != nil {

		// Print default error.
		pterm.Error.Println(errString)
		os.Exit(1)
	}

}

func errorMsg(theError string) {

	// Print default error.
	pterm.Error.Println(theError)

}

func successMsg(theSuccess string) {

	// Print default Success
	pterm.Success.Println(theSuccess)

}

func infoMsg(theInfo string) {

	// Print default Info message
	pterm.Info.Println(theInfo)

}

func errorOne() {

	os.Exit(1)
}

func successZero() {

	os.Exit(0)
}

func msgSleep(theMsg string) {

	successMsg(theMsg + " This window will close automatically.")
	time.Sleep(5 * time.Second)
}
