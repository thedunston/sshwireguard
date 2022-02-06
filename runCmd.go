package main

/** Executes the command to manage the Wireguard service or check running status */

import (
	"bytes"
	"io"
	"os/exec"
	"strings"
)

func run_cmd(wg_run string) string {

	// Split the command using spaces to manage the service
	args := strings.Fields(wg_run)

	// Run the wireguard command
	cmd := exec.Command(args[0], args[1:]...)

	// Execute the command
	err := cmd.Run()
	checkErr(err, "Error running command "+wg_run)

	// Ran successfully
	allGood := "Success"
	return allGood
}

func run_cmdPipe(wg_run string, thePipe string) string {

	// Split the command using spaces
	args := strings.Fields(wg_run)

	// Split the command using spaces
	args2 := strings.Fields(thePipe)

	// Execute the commands
	// args[0] runs the main executable
	// args[1:]... gets the options and switches
	cmd1 := exec.Command(args[0], args[1:]...)
	cmd2 := exec.Command(args2[0], args2[1:]...)

	// Create a pipe.
	reader, writer := io.Pipe()

	// First command
	cmd1.Stdout = writer

	// second part of command
	cmd2.Stdin = reader

	// prepare a buffer to capture the output
	// after second command finished executing
	var buff bytes.Buffer

	// Stores the output of the command from Pipe when it finishes.
	cmd2.Stdout = &buff

	// Run the first command: Cmd
	cmd1.Start()

	// Run the second command: Pipe
	cmd2.Start()

	// Waits for the first command to finish running
	cmd1.Wait()

	// Close the writer
	writer.Close()

	// Waits for the second command to complete
	cmd2.Wait()

	// Close the reader
	reader.Close()

	// Converting the command results to a string
	output := buff.String()

	return output

}
