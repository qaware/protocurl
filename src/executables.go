package main

import (
	"fmt"
	"os/exec"
)

const ProtocExecutableName = "protoc"
const CurlExecutableName = "curl"

var foundExecutables = make(map[string]string)

func findProtocExecutable() (string, error) {
	return getExecutablePathOrLookup(CurrentConfig.CustomProtocPath, ProtocExecutableName, true)
}

func findCurlExecutable(force bool) (string, error) {
	return getExecutablePathOrLookup(CurrentConfig.CustomCurlPath, CurlExecutableName, force)
}

func getExecutablePathOrLookup(optionalExecPath string, name string, force bool) (string, error) {
	if optionalExecPath != "" {
		if CurrentConfig.Verbose {
			fmt.Printf("Using custom "+name+" path: %s\n", optionalExecPath)
		}
		return optionalExecPath, nil
	} else {
		return findExecutable(name, force)
	}
}

// Returns the filesystem path for the executable of the given name in the env PATH.
// If force is set, then failure to find the executable will panic. Otherwise, only an error will be returned.
func findExecutable(name string, force bool) (string, error) {
	if foundExecutables[name] != "" {
		return foundExecutables[name], nil
	}

	executable, err := exec.LookPath(name)
	if err != nil {
		if force {
			PanicWithMessageOnError(err, func() string { return "I could not find a '" + name + "' executable. Please check your PATH." })
		} else {
			if CurrentConfig.Verbose {
				fmt.Printf("Did not find executable %s.\n", name)
			}
			return "", err
		}
	}

	foundExecutables[name] = executable

	if CurrentConfig.Verbose {
		fmt.Printf("Found %s: %s\n", name, executable)
	}
	return executable, nil
}
