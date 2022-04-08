package main

import (
	"fmt"
	"os/exec"
)

var foundExecutables = make(map[string]string)

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
