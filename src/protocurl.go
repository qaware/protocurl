package main

import (
	"encoding/hex"
	"fmt"
	"github.com/spf13/cobra"
	"google.golang.org/protobuf/reflect/protoregistry"
)

const GithubRepositoryLink = "https://github.com/qaware/protocurl"

type Config struct {
	ProtoFilesDir        string
	ProtoInputFilePath   string
	RequestType          string
	ResponseType         string
	CustomProtocPath     string
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
}

var commit = "todo"
var version = "todo"

var DefaultPrependedHeaderArgs = []string{"-H", "'Content-Type: application/x-protobuf'"}

// todo. ^ document this in Usage.

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
		"If no curl executable was found in the path, it will fall back to an internal non-configurable http request.",
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
		fmt.Printf("Adding default header argument to request headers : %s\n", DefaultPrependedHeaderArgs)
	}
	CurrentConfig.RequestHeaders = append(DefaultPrependedHeaderArgs, CurrentConfig.RequestHeaders...)
}

func setAndShowVersion() {
	rootCmd.Version = fmt.Sprintf("%s, build %s", version, commit)
	rootCmd.SetHelpTemplate("protocurl {{.Version}}\n\n" + rootCmd.HelpTemplate())
}
