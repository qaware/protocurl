package main

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httputil"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/kballard/go-shellquote"
)

const publicReadPermissions os.FileMode = 0644

func invokeInternalHttpRequest(requestBinary []byte) ([]byte, string) {
	if CurrentConfig.Verbose {
		fmt.Println("Invoking internal http request.")
	}

	if usingUnsupportedNonDefaultHeaders() {
		PanicDueToUnsupportedHeadersWhenInternalHttp(CurrentConfig.RequestHeaders)
	}

	httpResponse, err := http.Post(CurrentConfig.Url, DefaultContentType, bytes.NewReader(requestBinary))
	PanicWithMessageOnError(err, func() string { return "Failed internal HTTP request. Error: " + err.Error() })
	defer func() { _ = httpResponse.Body.Close() }()

	body, err := ioutil.ReadAll(httpResponse.Body)
	PanicOnError(err)

	headers, err := httputil.DumpResponse(httpResponse, false)
	headersString := string(headers)

	ensureStatusCodeIs2XX(headersString)

	return body, strings.TrimSpace(headersString)
}

func usingUnsupportedNonDefaultHeaders() bool {
	usingNonDefaultHeaders := len(CurrentConfig.RequestHeaders) != 1 || CurrentConfig.RequestHeaders[0] != DefaultHeaders[0]
	return CurrentConfig.NoDefaultHeaders || usingNonDefaultHeaders
}

func invokeCurlRequest(requestBinary []byte, curlPath string) ([]byte, string) {
	if CurrentConfig.Verbose {
		fmt.Println("Invoking curl http request.")
	}

	tmpDir, err := ioutil.TempDir(os.TempDir(), "protocurl-temp-*")
	PanicOnError(err)
	defer func() { _ = os.RemoveAll(tmpDir) }()

	requestBinaryFile := filepath.Join(tmpDir, "request.bin")
	err = ioutil.WriteFile(requestBinaryFile, requestBinary, publicReadPermissions)
	PanicOnError(err)

	responseBinaryFile := filepath.Join(tmpDir, "response.bin")
	responseHeadersTextFile := filepath.Join(tmpDir, "response-headers.txt")

	curlArgs := []string{
		curlPath,
		"-s",
		"-X", "POST",
		"--data-binary", "@" + requestBinaryFile,
		"--output", responseBinaryFile,
		"--dump-header", responseHeadersTextFile,
	}
	for _, header := range CurrentConfig.RequestHeaders {
		curlArgs = append(curlArgs, "-H", header)
	}

	individualAdditionalCurlArgs, err := shellquote.Split(CurrentConfig.AdditionalCurlArgs)
	PanicOnError(err)
	if CurrentConfig.Verbose {
		fmt.Printf("Understood additional curl args: %+q\n", individualAdditionalCurlArgs)
	}
	curlArgs = append(curlArgs, individualAdditionalCurlArgs...)

	curlArgs = append(curlArgs, CurrentConfig.Url)

	if CurrentConfig.Verbose {
		fmt.Printf("Total curl args:\n  %s\n", strings.Join(curlArgs[1:], "\n  "))
	}

	curlStdOut := bytes.NewBuffer([]byte{})
	curlStdErr := bytes.NewBuffer([]byte{})
	curlCmd := exec.Cmd{
		Path:   curlPath,
		Args:   curlArgs,
		Stdout: bufio.NewWriter(curlStdOut),
		Stderr: bufio.NewWriter(curlStdErr),
	}

	err = curlCmd.Run()

	if !CurrentConfig.ShowOutputOnly && curlStdOut.Len() != 0 {
		fmt.Printf("%s CURL Output      %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, string(curlStdOut.Bytes()))
	}

	if !CurrentConfig.ShowOutputOnly && curlStdErr.Len() != 0 {
		fmt.Printf("%s CURL ERROR       %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, string(curlStdErr.Bytes()))
	}

	PanicWithMessageOnError(err, func() string { return "Encountered an error while running curl. Error: " + err.Error() })

	responseBinary, err := ioutil.ReadFile(responseBinaryFile)
	responseHeaders, err := ioutil.ReadFile(responseHeadersTextFile)
	responseHeadersText := strings.TrimSpace(string(responseHeaders))

	ensureStatusCodeIs2XX(responseHeadersText)

	return responseBinary, responseHeadersText
}

func ensureStatusCodeIs2XX(headers string) {
	httpStatusLine := strings.Split(headers, "\n")[0]
	matches, err := regexp.MatchString("HTTP/.* 2[0-9][0-9] .*", httpStatusLine)
	AssertSuccess(err)

	if !matches {
		err := errors.New("Request was unsuccessful. Received response status code outside of 2XX. Got: " + httpStatusLine)
		PanicOnError(err)
	}
}
