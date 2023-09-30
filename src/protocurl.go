package main

import (
	"encoding/hex"
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"google.golang.org/protobuf/reflect/protoregistry"
)

const GithubRepositoryLink = "https://github.com/qaware/protocurl"
const EnhancementsAndBugsLink = "https://github.com/qaware/protocurl/issues"

type Config struct {
	ProtoFilesDir        string
	ProtoInputFilePath   string
	RequestType          string
	ResponseType         string
	Url                  string
	Method               string
	DataText             string
	InTextType           InTextType
	OutTextType          OutTextType
	DecodeRawResponse    bool
	DisplayBinaryAndHttp bool
	NoDefaultHeaders     bool
	RequestHeaders       []string
	CustomCurlPath       string
	AdditionalCurlArgs   string
	Verbose              bool
	ShowOutputOnly       bool
	ForceNoCurl          bool
	ForceCurl            bool
	GlobalProtoc         bool
	CustomProtocPath     string
	InferProtoFiles      bool
}

var commit string
var version string

var DefaultContentType = "application/x-protobuf"
var DefaultHeaders = []string{"Content-Type: " + DefaultContentType} // first element needs to be content type, for checks in httpRequest.go

var CurrentConfig = Config{}

func main() {
	defer func() {
		if err := recover(); err != nil {
			PrintError(fmt.Errorf("%v", err))
			os.Exit(1)
		}
	}()
	PanicOnError(rootCmd.Execute())
}

func init() {
	setAndShowVersion()
	intialiseFlags()
}

var rootCmd = &cobra.Command{
	Short: "protoCURL is cURL for Protobuf: The command-line tool for interacting with Protobuf over HTTP REST endpoints using human-readable text formats.",
	Use: "protocurl [flags] -I proto-dir -i request-type -o response-type -u url -d request-text\n\n" +
		"It uses '" + CurlExecutableName + "' from PATH. If none was found, it will fall back to an internal non-configurable http request.\n" +
		"It uses a bundled '" + ProtocExecutableName + "' (by default) which is used to parse the .proto files.\n" +
		"The bundle also includes the well-known Google Protobuf files necessary to create FileDescriptorSet payloads via '" + ProtocExecutableName + "'.\n" +
		"If the bundled '" + ProtocExecutableName + "' is used, then these .proto files are included. Otherwise .proto files from the system-wide include are used.\n" +
		"The Header 'Content-Type: application/x-protobuf' is set as a request header by default. (disable via -n)\n" +
		"When converting between binary and text, the encoding UTF-8 is always used.\n" +
		"When the correct response type is unknown or being debugged, omitting -o <response-type> will attempt to show the response in raw format.\n\n" +
		"Enhancements and bugs: " + EnhancementsAndBugsLink,
	Example:               "  protocurl -I my-protos -i package.path.Req -o package.path.Resp -u http://example.com/api -d \"myField: true, otherField: 1337\"",
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
	requestBinary, _ := textToMsgAndBinary(requestType, text, registry)

	reconstructedRequestText, _ := protoBinaryToMsgAndText(
		requestType,
		requestBinary,
		OutTextType(CurrentConfig.InTextType),
		registry,
	)

	if !CurrentConfig.ShowOutputOnly {
		// todo. remove one space here for aligned output
		fmt.Printf("%s %s Request %s    %s %s\n%s\n",
			VISUAL_SEPARATOR, CurrentConfig.Method, displayIn(CurrentConfig.InTextType), VISUAL_SEPARATOR,
			SEND, reconstructedRequestText)
	}

	if !CurrentConfig.ShowOutputOnly && CurrentConfig.DisplayBinaryAndHttp {
		fmt.Printf("%s %s Request Binary %s %s\n%s", VISUAL_SEPARATOR, CurrentConfig.Method, VISUAL_SEPARATOR, SEND, hex.Dump(requestBinary))
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
		fmt.Printf("%s %s Response Headers %s %s\n%s\n", VISUAL_SEPARATOR, CurrentConfig.Method, VISUAL_SEPARATOR, RECV, responseHeaders)

		fmt.Printf("%s %s Response Binary  %s %s\n%s", VISUAL_SEPARATOR, CurrentConfig.Method, VISUAL_SEPARATOR, RECV, hex.Dump(responseBinary))
	}

	responseMessageType := properResponseTypeIfProvidedOrEmptyType()

	responseText, _ := protoBinaryToMsgAndText(responseMessageType, responseBinary, CurrentConfig.OutTextType, registry)

	if !CurrentConfig.ShowOutputOnly {
		fmt.Printf("%s %s Response %s    %s %s\n",
			VISUAL_SEPARATOR, CurrentConfig.Method, displayOut(CurrentConfig.OutTextType), VISUAL_SEPARATOR, RECV)
	}
	fmt.Printf("%s\n", responseText)
}

func properResponseTypeIfProvidedOrEmptyType() string {
	if CurrentConfig.ResponseType != "" {
		return CurrentConfig.ResponseType
	} else {
		if CurrentConfig.Verbose {
			fmt.Printf("Decoding response against %s as no response type was provided.\n", WellKnownEmptyMessageType)
		}
		return WellKnownEmptyMessageType
	}
}

func addDefaultHeaderArgument() {
	if CurrentConfig.NoDefaultHeaders {
		return
	}

	if CurrentConfig.Verbose {
		fmt.Printf("Adding default header argument to request headers : %s\n", DefaultHeaders)
	}
	CurrentConfig.RequestHeaders = append(DefaultHeaders, CurrentConfig.RequestHeaders...)
}

func setAndShowVersion() {
	rootCmd.Version = fmt.Sprintf("%s, build %s, %s", version, commit[:6], GithubRepositoryLink)
	rootCmd.SetHelpTemplate("protocurl {{.Version}}\n\n" + rootCmd.HelpTemplate())
}
