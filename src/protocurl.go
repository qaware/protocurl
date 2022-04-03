package main

import (
	"bufio"
	"bytes"
	"encoding/hex"
	"fmt"
	"github.com/spf13/cobra"
	"google.golang.org/protobuf/reflect/protoregistry"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"strings"
)

const GithubRepositoryLink = "https://github.com/qaware/protocurl"
const ProtocExecutableName = "protoc"
const CurlExecutableName = "curl"

type Config struct {
	ProtoFilesDir            string
	ProtoInputFilePath       string
	RequestType              string
	ResponseType             string
	Url                      string
	DataText                 string
	DisplayBinaryAndHttp     bool
	BinaryDisplayHexDumpArgs string
	RequestHeaders           []string
	AdditionalCurlArgs       string
	Verbose                  bool
	ShowOutputOnly           bool
}

var commit = "todo"
var version = "todo"

var DefaultPrependedHeaderArgs = []string{"-H", "'Content-Type: application/x-protobuf'"}

// todo. ^ document this in Usage.

var CurrentConfig = Config{}

func main() {
	PanicOnError(rootCmd.Execute())
}

func init() {
	setAndShowVersion()

	intialiseFlags()
}

/*
NOTE REGARDING DISTRIBUTION

It's not an issue to ensure that the user has the exact same protobuf version as the Go Protobuf SDK.
We can simply use the protoc in the users context. Since protobuf relies on backwards compatability
we only need ot check in CI, that the protoCURL CLI (with its implicit Protobuf Go SDK version)
is compatible with all existing protoc binaries when processing .proto files.

Recommendation: Use your own integrated protoc compiler (bundled) and provide option --protoc-path
for the users to override it.
*/

var rootCmd = &cobra.Command{
	Short:                 "Send and receive Protobuf messages over HTTP via `curl` and interact with it using human-readable text formats.",
	Use:                   "protocurl [flags] -f proto-file -i request-type -o response-type -u url -d request-text",
	Example:               "  protocurl -I my-protos -f messages.proto -i package.path.Req -o package.path.Resp -u http://foo.com/api -d \"myField: true, otherField: 1337\"",
	Args:                  cobra.OnlyValidArgs,
	DisableFlagsInUseLine: true,
	Run: func(cmd *cobra.Command, args []string) {
		propagateFlags()

		printVersionInfoVerbose(cmd)

		addDefaultHeaderArgument()

		printArgsVerbose()

		runProtocurlWorkflow()
	},
}

func runProtocurlWorkflow() {
	protoRegistryFiles := convertProtoFilesToProtoRegistryFiles()

	requestBinary := encodeToBinary(CurrentConfig.RequestType, CurrentConfig.DataText, protoRegistryFiles)

	responseBinary, responseHeaders := invokeCurlRequest(requestBinary)

	decodeResponse(responseBinary, responseHeaders, protoRegistryFiles)
}

func encodeToBinary(requestType string, text string, registry *protoregistry.Files) []byte {
	requestBinary, _ := protoTextToMsgAndBinary(requestType, text, registry)

	reconstructedRequestText, _ := protoBinaryToMsgAndText(requestType, requestBinary, true, registry)

	fmt.Printf("%s Request Text     %s %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, SEND, reconstructedRequestText)

	if CurrentConfig.DisplayBinaryAndHttp {
		fmt.Printf("%s Request Binary   %s %s\n%s", VISUAL_SEPARATOR, VISUAL_SEPARATOR, SEND, hex.Dump(requestBinary))
	}

	return requestBinary
}

func invokeCurlRequest(requestBinary []byte) ([]byte, string) {
	curlPath := findExecutable(CurlExecutableName)

	tmpDir, err := ioutil.TempDir(os.TempDir(), "protocurl-temp-*")
	PanicOnError(err)
	defer func(path string) {
		_ = os.RemoveAll(path)
	}(tmpDir)

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
	// curlArgs = append(curlArgs, CurrentConfig.AdditionalCurlArgs)
	//todo. need to apply bash-like splitting of arguments.
	// This might be what we need here: https://github.com/kballard/go-shellquote/blob/master/unquote_test.go#L36
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
	PanicWithMessageOnError(err, func() string { return "Encountered an error while running curl. Error: " + err.Error() })

	if curlStdOut.Len() != 0 {
		fmt.Printf("%s CURL Output      %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, string(curlStdOut.Bytes()))
	}

	if curlStdErr.Len() != 0 {
		fmt.Printf("%s CURL ERROR       %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, string(curlStdErr.Bytes()))
	}

	responseBinary, err := ioutil.ReadFile(responseBinaryFile)
	responseHeaders, err := ioutil.ReadFile(responseHeadersTextFile)

	return responseBinary, strings.TrimSpace(string(responseHeaders))
}

func decodeResponse(responseBinary []byte, responseHeaders string, registry *protoregistry.Files) {
	if CurrentConfig.DisplayBinaryAndHttp {
		fmt.Printf("%s Response Headers %s %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, RECV, responseHeaders)

		fmt.Printf("%s Response Binary  %s %s\n%s", VISUAL_SEPARATOR, VISUAL_SEPARATOR, RECV, hex.Dump(responseBinary))
	}

	responseText, _ := protoBinaryToMsgAndText(CurrentConfig.ResponseType, responseBinary, true, registry)

	fmt.Printf("%s Response Text    %s %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, RECV, responseText)
}

var foundExecutables = make(map[string]string)

func findExecutable(name string) string {
	if foundExecutables[name] != "" {
		return foundExecutables[name]
	}

	executable, err := exec.LookPath(name)
	PanicWithMessageOnError(err, func() string { return "I could not find a '" + name + "' executable. Please check your PATH." })

	foundExecutables[name] = executable

	if CurrentConfig.Verbose {
		fmt.Printf("Found %s: %s\n", name, executable)
	}
	return executable
}

func addDefaultHeaderArgument() {
	if CurrentConfig.Verbose {
		fmt.Printf("Adding default header argument to request headers : %s\n", DefaultPrependedHeaderArgs)
	}
	CurrentConfig.RequestHeaders = append(DefaultPrependedHeaderArgs, CurrentConfig.RequestHeaders...)
}

func setAndShowVersion() {
	rootCmd.Version = fmt.Sprintf("%s, build %s", version, commit)
	rootCmd.SetHelpTemplate("protocurl {{.Version}}\n\n" + rootCmd.HelpTemplate())
}
