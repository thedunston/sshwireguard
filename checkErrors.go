package main

import (
	"fmt"
	"log"
)

// Generic check for errors
func checkErr(theError error, errString string) {

	if theError != nil {

		fmt.Println(errString)
		log.Fatal(theError)

	}

}
