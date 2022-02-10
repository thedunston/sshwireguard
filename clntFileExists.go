package main

import (
	"fmt"
	"log"
	"os"
)

// Function to check if file exists
func fileExists(filename string, filename2 string, todo string) {

	// Delete the VPN config file
	if todo == "remove" {

		// Stat returns file info. It will return
		// nil if the file does not exist.
		_, err := os.Stat(filename)

		if err == nil {

			fmt.Printf("\nRemoving existing VPN Configs\n")
			err = os.Remove(filename)
			checkErr(err, "")

		}

		_, err = os.Stat(filename2)

		if err == nil {

			err = os.Remove(filename2)
			checkErr(err, "")

		}

	} else if todo == "getCheck" {

		// Stat returns file info. It will return
		// nil if the file does not exist.
		_, err := os.Stat(filename)
		if err == nil {

			fmt.Println("VPN config downloaded.")
		} else {

			fmt.Println("New VPN configuration was not received, please try again.")
			checkErr(err, "VPN Files were not found.")

		}

	} else {

		_, err := os.Stat(filename)
		if err != nil {

			fmt.Println("New VPN configuration was not received, please try again.")
			log.Fatal(err)

		} else {

			fmt.Println("Existing VPN config removed.")
		}

	}

	return
}
