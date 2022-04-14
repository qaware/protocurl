package main

import (
	"encoding/hex"
	"fmt"
	"github.com/spf13/cobra"
	"google.golang.org/protobuf/reflect/protoregistry"
)

const GithubRepositoryLink = "https://github.com/qaware/protocurl"
const BugReportsLink = "https://github.com/qaware/protocurl/issues"

type Config struct {
	ProtoFilesDir        string
	ProtoInputFilePath   string
	RequestType          string
	ResponseType         string
	Url                  string
	DataText             string
	DisplayBinaryAndHttp bool
	RequestHeaders       []string
	CustomCurlPath       string
	AdditionalCurlArgs   string
	Verbose              bool
	ShowOutputOnly       bool
	ForceNoCurl          bool
	ForceCurl            bool
	GlobalProtoc         bool
	CustomProtocPath     string
}

var commit string
var version string

var DefaultContentType = "application/x-protobuf"
var DefaultHeaders = []string{"Content-Type: " + DefaultContentType} // first element needs to be content type, for checks in httpRequest.go

var CurrentConfig = Config{}

func main() {
	PrintError(rootCmd.Execute())
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
	Short: "Send and receive Protobuf messages over HTTP via `curl` and interact with it using human-readable text formats.",
	Use: "protocurl [flags] -f proto-file -i request-type -o response-type -u url -d request-text\n\n" +
		"It uses '" + CurlExecutableName + "' from PATH. If none was found, it will fall back to an internal non-configurable http request.\n" +
		"It uses a bundled '" + ProtocExecutableName + "' (by default) which is used to parse the .proto files.\n" +
		"The bundle also includes the google protobuf .proto files necessary to create FileDescriptorSet payloads via '" + ProtocExecutableName + "'.\n" +
		"If the bundled '" + ProtocExecutableName + "' is used, then these .proto files are included. Otherwise .proto files from the system-wide include are used.\n" +
		"The Header 'Content-Type: application/x-protobuf' is set as a request header by default.\n" +
		"When converting between binary and text, the encoding UTF-8 is always used.\n\n" +
		"Bug reports: " + BugReportsLink,
	Example:               "  protocurl -I my-protos -f messages.proto -i package.path.Req -o package.path.Resp -u http://example.com/api -d \"myField: true, otherField: 1337\"",
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

	responseBinary, responseHeaders := invokeHttpRequestBasedOnConfig(requestBinary)

	decodeResponse(responseBinary, responseHeaders, protoRegistryFiles)
}

func encodeToBinary(requestType string, text string, registry *protoregistry.Files) []byte {
	requestBinary, _ := protoTextToMsgAndBinary(requestType, text, registry)

	reconstructedRequestText, _ := protoBinaryToMsgAndText(requestType, requestBinary, registry)

	if !CurrentConfig.ShowOutputOnly {
		fmt.Printf("%s Request Text     %s %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, SEND, reconstructedRequestText)
	}

	if !CurrentConfig.ShowOutputOnly && CurrentConfig.DisplayBinaryAndHttp {
		fmt.Printf("%s Request Binary   %s %s\n%s", VISUAL_SEPARATOR, VISUAL_SEPARATOR, SEND, hex.Dump(requestBinary))
	}

	return requestBinary
}

func invokeHttpRequestBasedOnConfig(requestBinary []byte) ([]byte, string) {
	if CurrentConfig.ForceNoCurl {
		if CurrentConfig.Verbose {
			fmt.Println("Using internal http request due to forced avoidance of curl.")
		}
		return invokeInternalHttpRequest(requestBinary)
	}

	if CurrentConfig.ForceCurl {
		if CurrentConfig.Verbose {
			fmt.Println("Expecting to find curl executable due to forced use of curl.")
		}
		curlPath, _ := findCurlExecutable(true)
		return invokeCurlRequest(requestBinary, curlPath)
	} else {
		curlPath, err := findCurlExecutable(false)
		if err != nil {
			return invokeInternalHttpRequest(requestBinary)
		} else {
			return invokeCurlRequest(requestBinary, curlPath)
		}
	}
}

func decodeResponse(responseBinary []byte, responseHeaders string, registry *protoregistry.Files) {
	if !CurrentConfig.ShowOutputOnly && CurrentConfig.DisplayBinaryAndHttp {
		fmt.Printf("%s Response Headers %s %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, RECV, responseHeaders)

		fmt.Printf("%s Response Binary  %s %s\n%s", VISUAL_SEPARATOR, VISUAL_SEPARATOR, RECV, hex.Dump(responseBinary))
	}

	responseText, _ := protoBinaryToMsgAndText(CurrentConfig.ResponseType, responseBinary, registry)

	if !CurrentConfig.ShowOutputOnly {
		fmt.Printf("%s Response Text    %s %s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, RECV)
	}
	fmt.Printf("%s\n", responseText)
}

func addDefaultHeaderArgument() {
	if CurrentConfig.Verbose {
		fmt.Printf("Adding default header argument to request headers : %s\n", DefaultHeaders)
	}
	CurrentConfig.RequestHeaders = append(DefaultHeaders, CurrentConfig.RequestHeaders...)
}

func setAndShowVersion() {
	rootCmd.Version = fmt.Sprintf("%s, build %s, %s", version, commit[:6], GithubRepositoryLink)
	rootCmd.SetHelpTemplate("protocurl {{.Version}}\n\n" + rootCmd.HelpTemplate())
}
