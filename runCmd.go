package main

/** Executes the command to manage the Wireguard service or check running status */

import (
	"fmt"
	"os/exec"
	"regexp"
	"runtime"
	"strings"
	"time"
)

func checkOutput(o string, taskMsg string) string {

	// Check OS for expected output
	// Windows
	if runtime.GOOS == "windows" {

		if taskMsg == "start" {

			taskMsg = "RUNNING"

		} else {

			taskMsg = "STOPPED"

		}

		// *nix
	} else {

		// Output from the ip command has a colon at the end of the interface
		taskMsg = "sshwireguard:"

	}

	// Search for the task being performed STOPPED or RUNNING
	matched, _ := regexp.MatchString(taskMsg, o)

	allGood := ""
	// Check if the task is in the output.
	if matched {

		// Ran successfully
		allGood = "Success"

	} else {

		allGood = "Error"

	}

	return allGood

}

func srvCheck(os string, taskMsg string) string {

	wg_run := ""

	if os == "windows" {

		// Command to check on status of sshwireguard service
		wg_run = "sc query WireGuardTunnel$sshwireguard"

		// *nix
	} else {

		// Command to check on status of sshwireguard service
		wg_run = "ip a show dev sshwireguard"

	}

	// Split the command for execution
	args := strings.Fields(wg_run)

	// Format the command to run
	cmd := exec.Command(args[0], args[1:]...)

	// Execute the command
	results, _ := cmd.CombinedOutput()

	// Get the results
	cmdResults := checkOutput(string(results), taskMsg)

	return cmdResults

}

func run_cmd(wg_run string, taskMsg string) {

	// Split the command using spaces to manage the service
	args := strings.Fields(wg_run)

	// Run the wireguard command
	cmd := exec.Command(args[0], args[1:]...)

	fmt.Println("Please wait...")

	time.Sleep(5 * time.Second)
	// Execute the command
	_, err := cmd.CombinedOutput()
	checkErr(err, "Error running command "+wg_run)

	//	var cmdResults []byte
	//checkOutput(string(output), taskMsg)

	s := srvCheck("windows", "start")

	run_results(s, "started")
	// DEBUG
	//fmt.Println("run_cmd: ", wg_run)

}
