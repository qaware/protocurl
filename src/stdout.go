package main

import (
	"encoding/json"
	"fmt"
	"github.com/spf13/cobra"
)

const VISUAL_SEPARATOR = "==========================="
const SEND = ">>>"
const RECV = "<<<"

func EnsureMessageDescriptorIsResolved(requestType string, err error) {
	PanicWithMessageOnError(err, func() string {
		return "I couldn't find any Protobuf message for the message package-path " + requestType + ".\n" +
			"Did you correctly -I (include) your proto files directory?\n" +
			"Did you correctly specify the full message package-path to your Protobuf message type?\n" +
			"Try again with -v (verbose)."
	})
}

func printArgsVerbose() {
	if CurrentConfig.Verbose {
		fmt.Println("Invoked with following default & parsed arguments:")
		printAsJson(CurrentConfig)
	}
}

func printVersionInfoVerbose(cmd *cobra.Command) {
	if CurrentConfig.Verbose {
		fmt.Printf("protocurl %s\n", cmd.Version)
	}
}

func printAsJson(obj interface{}) {
	jsonBytes, err := json.MarshalIndent(obj, "", "  ")
	PanicOnError(err)
	fmt.Println(string(jsonBytes))
}
