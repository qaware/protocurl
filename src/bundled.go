package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

// We're always using path/filepath instead of path for OS-aware path operations

const ProtocurlInternalName = "protocurl-internal"

func getProtocurlInternalPath() (string, error) {
	protocurlPath, err := os.Executable()
	if err != nil {
		return "", err
	}
	protocurlPath, err = normaliseFilePath(protocurlPath)
	if err != nil {
		return "", err
	}

	internalPathErrorMsg := "Cannot find '" + ProtocurlInternalName + "' directory.\n" +
		"Please ensure that you correctly extracted the full protocurl archive.\n" +
		"I was expecting to find a directory '" + ProtocurlInternalName + "' side by side\n" +
		"to the bin directory containing the protocurl executable.\n" +
		"The executable was found at " + protocurlPath + "\n" +
		"Error: "

	// /path/to/pc/bin/protocurl[ext] -> /path/to/pc/protocurl-internal
	unnormalisedProtocurlInternalPath := filepath.Join(filepath.Dir(filepath.Dir(protocurlPath)), ProtocurlInternalName)
	protocurlInternalPath, err := normaliseFilePath(unnormalisedProtocurlInternalPath)
	if err != nil {
		return "", errors.New(internalPathErrorMsg + err.Error())
	}

	if _, err := os.Stat(protocurlInternalPath); !os.IsNotExist(err) {
		return protocurlInternalPath, nil
	} else {
		return "", errors.New(internalPathErrorMsg + err.Error())
	}
}

func getGoogleProtobufIncludePath(useBundled bool) string {
	var includePath string

	if useBundled {
		protocurlInternalPath, err := getProtocurlInternalPath()
		PanicOnError(err)
		includePath = filepath.Join(protocurlInternalPath, "include")
	} else {
		includePath = GlobalGoogleProtobufIncludePath
	}

	if CurrentConfig.Verbose {
		fmt.Printf("Using google protobuf include: %s\n", includePath)
	}

	return includePath
}
