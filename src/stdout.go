package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/spf13/cobra"
	"google.golang.org/protobuf/reflect/protoreflect"
)

const VISUAL_SEPARATOR = "==========================="
const SEND = ">>>"
const RECV = "<<<"

func EnsureMessageDescriptorIsResolved(descriptor protoreflect.Descriptor, requestType string, err error) {
	if descriptor == nil {
		PanicOnError(errors.New(
			"I couldn't find any Protobuf message for the message package-path " + requestType + ".\n" +
				"Did you correctly -I (include) your proto files directory?\n" +
				"Did you correctly specify the full message package-path to your Protobuf message type?\n" +
				"Try again with -v (verbose).\n" +
				"Error: " + err.Error(),
		))
	}
}

func printArgsVerbose() {
	if !CurrentConfig.ShowOutputOnly && CurrentConfig.Verbose {
		fmt.Println("Invoked with following default & parsed arguments:")
		printAsJson(CurrentConfig)
	}
}

func printVersionInfoVerbose(cmd *cobra.Command) {
	if !CurrentConfig.ShowOutputOnly && CurrentConfig.Verbose {
		fmt.Printf("protocurl %s\n", cmd.Version)
	}
}

func printAsJson(obj interface{}) {
	jsonBytes, err := json.MarshalIndent(obj, "", "  ")
	PanicOnError(err)
	fmt.Println(string(jsonBytes))
}
