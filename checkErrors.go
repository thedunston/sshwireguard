package main

import (
	//"fmt"
	//"log"
	"github.com/pterm/pterm"
	"os"
)

// Generic check for errors
func checkErr(theError error, errString string) {

	if theError != nil {

		// Print default error.
		pterm.Error.Println(errString)
		//log.Fatal(theError)
		os.Exit(1)
	}

}
