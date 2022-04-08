package main

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"github.com/kballard/go-shellquote"
	"io/ioutil"
	"net/http"
	"net/http/httputil"
	"os"
	"os/exec"
	"path"
	"regexp"
	"strings"
)

func invokeInternalHttpRequest(requestBinary []byte) ([]byte, string) {
	if CurrentConfig.Verbose {
		fmt.Println("Invoking internal http request.")
	}

	httpResponse, err := http.Post(CurrentConfig.Url, "application/x-protobuf", bytes.NewReader(requestBinary)) // todo. additional headers
	PanicWithMessageOnError(err, func() string { return "Failed internal HTTP request. Error: " + err.Error() })
	defer func() { _ = httpResponse.Body.Close() }()

	body, err := ioutil.ReadAll(httpResponse.Body)
	PanicOnError(err)

	headers, err := httputil.DumpResponse(httpResponse, false)
	headersString := string(headers)

	ensureStatusCodeIs2XX(headersString)

	return body, strings.TrimSpace(headersString)
}

func invokeCurlRequest(requestBinary []byte, curlPath string) ([]byte, string) {
	if CurrentConfig.Verbose {
		fmt.Println("Invoking curl http request.")
	}

	tmpDir, err := ioutil.TempDir(os.TempDir(), "protocurl-temp-*")
	PanicOnError(err)
	defer func() { _ = os.RemoveAll(tmpDir) }()

	requestBinaryFile := path.Join(tmpDir, "request.bin")
	err = ioutil.WriteFile(requestBinaryFile, requestBinary, 0)
	PanicOnError(err)

	responseBinaryFile := path.Join(tmpDir, "response.bin")
	responseHeadersTextFile := path.Join(tmpDir, "response-headers.txt")

	curlArgs := []string{
		curlPath,
		"-s",
		"-X", "POST",
		"--data-binary", "@" + requestBinaryFile,
		"--output", responseBinaryFile,
		"--dump-header", responseHeadersTextFile,
	}
	curlArgs = append(curlArgs, CurrentConfig.RequestHeaders...)

	individualAdditionalCurlArgs, err := shellquote.Split(CurrentConfig.AdditionalCurlArgs)
	PanicOnError(err)
	if CurrentConfig.Verbose {
		fmt.Printf("Understood additional curl args: %+q\n", individualAdditionalCurlArgs)
	}
	curlArgs = append(curlArgs, individualAdditionalCurlArgs...)

	curlArgs = append(curlArgs, CurrentConfig.Url)

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
