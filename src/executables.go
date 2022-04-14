package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

// We're always using path/filepath instead of path for OS-aware path operations

const ProtocExecutableName = "protoc" // You may want to wrap it within osAwareExecutableName
const CurlExecutableName = "curl"     // You may want to wrap it within osAwareExecutableName

const GlobalGoogleProtobufIncludePath = "/usr/bin/include"

var extensions = map[string]string{"windows": ".exe"}
var currentOsExt = (extensions)[runtime.GOOS]

var foundExecutables = make(map[string]string)

func findProtocExecutable() (string, bool /* true, if bundled protoc is used */) {
	if !CurrentConfig.GlobalProtoc {
		protocPath, err := getInternalProtocExec()
		PanicOnError(err)
		return protocPath, true
	} else {
		if CurrentConfig.Verbose {
			fmt.Printf("GlobalProtoc is set, hence bundled protoc will be ignored.\n")
		}
	}
	protocPath, _ := getExecutablePathOrLookup(CurrentConfig.CustomProtocPath, ProtocExecutableName, true)
	return protocPath, false
}

func findCurlExecutable(force bool) (string, error) {
	return getExecutablePathOrLookup(CurrentConfig.CustomCurlPath, CurlExecutableName, force)
}

func getExecutablePathOrLookup(optionalExecPath string, name string, force bool) (string, error) {
	if optionalExecPath != "" {
		execPathWithExt := osAwareExecutableName(optionalExecPath)
		if CurrentConfig.Verbose {
			fmt.Printf("Using custom "+name+" path: %s\n", optionalExecPath)
		}
		return execPathWithExt, nil
	} else {
		return findExecutable(osAwareExecutableName(name), force)
	}
}

//goland:noinspection GoBoolExpressions
func osAwareExecutableName(path string) string {
	if runtime.GOOS == "windows" && !strings.HasSuffix(path, currentOsExt) {
		var newPath = path + currentOsExt
		if CurrentConfig.Verbose {
			fmt.Printf("Path after os extension (%s): %s\n", currentOsExt, newPath)
		}
		return newPath
	}
	return path
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

func getInternalProtocExec() (string, error) {
	protocName := osAwareExecutableName(ProtocExecutableName)
	protocurlInternalPath, err := getProtocurlInternalPath()
	if err != nil {
		return "", err
	}
	protocInternalPath := filepath.Join(protocurlInternalPath, "bin", protocName)

	_, err = os.Stat(protocInternalPath)
	if os.IsNotExist(err) {
		return "", errors.New("Could not find bundled executable " + protocName + " \nError: " + err.Error())
	} else if err != nil {
		return "", err
	}

	if CurrentConfig.Verbose {
		fmt.Printf("Found bundled protoc at %s\n", protocInternalPath)
	}

	return protocInternalPath, nil
}

func normaliseFilePath(filePath string) (string, error) {
	filePath, err := filepath.Abs(filePath)
	if err != nil {
		return "", err
	}
	filePath, err = filepath.EvalSymlinks(filePath)
	if err != nil {
		return "", err
	}
	filePath, err = filepath.Abs(filePath)
	if err != nil {
		return "", err
	}
	return filePath, nil
}
