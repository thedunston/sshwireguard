package main

import (
	"fmt"
	"regexp"
	"runtime"
)

func check_output(o string, taskMsg string) string {

	// Search string
	toSearch := ""

	// Check OS for expected output
	// Windows
	if runtime.GOOS == "windows" {

		switch taskMsg {

		case "started":

			toSearch = "RUNNING"
		case "stopped":

			toSearch = "STOPPED"

		case "status":

			fmt.Println(0)
			matched, _ := regexp.MatchString("RUNNING", o)

			// Check if STOPPED or RUNNING is in the output
			if matched {

				taskMsg = "Success"

			} else {

				taskMsg = "Error"

			}

			return taskMsg

		default:

			infoMsg("Nothing to do!")
			errorOne()

		}

		// *nix
	} else {

		if taskMsg == "status" {

			fmt.Println(o)

			matched, _ := regexp.MatchString(" sshwireguard: ", o)

			// Check if STOPPED or RUNNING is in the output
			if matched {

				taskMsg = "Success"

			} else {

				taskMsg = "Error"

			}

			return taskMsg
		}
		// Output from the ip command has a colon at the end of the interface
		toSearch = "sshwireguard:"

	}

	// Search for the task being performed STOPPED or RUNNING
	matched, _ := regexp.MatchString(toSearch, o)

	allGood := ""
	// Check if the task is in the output.
	if matched {

		// The printed message is the same for checking on the status.
		// Ran successfully
		allGood = "Success"

	} else {

		// The printed message is the same for checking on the status.
		// Ran successfully
		allGood = "Error"

	}

	return allGood

}
