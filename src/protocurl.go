package main

import (
	json2 "encoding/json"
	"fmt"
	"github.com/spf13/cobra"
	"log"
	"os"
)

const GITHUB_REPOSITORY_LINK = "https://github.com/qaware/protocurl"

// Use Cobra for CLI: https://github.com/spf13/cobra
// Examples: https://github.com/qaware/go-for-operations/blob/master/workshop/challenge-1/challenge-1.md

type Config struct {
	ProtoFilesDir            string
	ProtoFilePath            string
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

var versionCommitString string

const DefaultPrependedHeaderArg = "'Content-Type: application/x-protobuf'"

var CurrentConfig = Config{}

var DisplayBinary = false
var DisplayResponseHeaders = false

var rootCmd = &cobra.Command{
	Short:                 "Send and receive Protobuf messages over HTTP via `curl` and interact with it using human-readable text formats.",
	Use:                   "protocurl [flags] -f proto-file -i request-type -o response-type -u url request-text",
	Example:               "  protocurl -I my-protos -f messages.proto -i package.path.Req -o package.path.Resp -u http://foo.com/api \"myField: true, otherField: 1337\"",
	Args:                  cobra.OnlyValidArgs,
	DisableFlagsInUseLine: true,
	Run: func(cmd *cobra.Command, args []string) {
		if CurrentConfig.Verbose {
			printVersionInfo(cmd)
		}

		if CurrentConfig.Verbose {
			fmt.Printf("Adding default header argument to request headers : %s\n", DefaultPrependedHeaderArg)
		}
		CurrentConfig.RequestHeaders = append(CurrentConfig.RequestHeaders)

		if CurrentConfig.Verbose {
			printArgs()
		}

		fmt.Println("<TODO: implement protocurl>")
		// Next, we need to use these packages here now: https://github.com/protocolbuffers/protobuf-go

		//log.Println(proto.Float64(0.23213))
		//log.Println(prototext.Unmarshal([]byte(CurrentConfig.DataText), nil))
		// todo. how might we use protobuf correctly here?

		/**	We want to use https://pkg.go.dev/google.golang.org/protobuf/reflect/protodesc
				and convert a given set of .proto files to it's protobuf descriptor messages.
			These messages can then be converted with the protodesc package such that we can use
		it to work with the proper payload values.
		For that, we need to add descriptor.proto into this repository and work with it's generated
		go code.

		But for this, we would need the protoc anways, as we would need to convert
		the .proto files to the file descriptor messages:
		https://stackoverflow.com/a/70653310

		But if we need protoc in the first place... Then we may not need to use the protobuf package that much...

		If using c++, we need this here:
		https://developers.google.com/protocol-buffers/docs/reference/cpp/google.protobuf.compiler.importer#Importer
		*/
	},
}

func printArgs() {
	json, err := json2.MarshalIndent(CurrentConfig, "", "  ")
	if err != nil {
		log.Fatalf(err.Error())
	}
	fmt.Printf("Invoked with following default & parsed arguments: %s\n", string(json))
}

func printVersionInfo(cmd *cobra.Command) {
	fmt.Printf("protocurl %s\n", cmd.Version)
}

func init() {

	setAndShowVersion()

	var flags = rootCmd.Flags()

	flags.StringVarP(&CurrentConfig.ProtoFilesDir, "proto-dir", "I", "/proto",
		"Uses the specified directory to find the proto-file.")

	flags.StringVarP(&CurrentConfig.ProtoFilePath, "proto-file", "f", "",
		"Uses the specified file path to find the Protobuf definition of the message types within 'proto-dir' (relative file path).")
	AssertSuccess(rootCmd.MarkFlagRequired("proto-file"))

	flags.StringVarP(&CurrentConfig.RequestType, "request-type", "i", "",
		"Mandatory: Package path of the Protobuf request type. E.g. mypackage.MyRequest")
	AssertSuccess(rootCmd.MarkFlagRequired("request-type"))

	flags.StringVarP(&CurrentConfig.ResponseType, "response-type", "o", "",
		"Mandatory: Package path of the Protobuf response type. E.g. mypackage.MyResponse")
	AssertSuccess(rootCmd.MarkFlagRequired("response-type"))

	flags.StringVarP(&CurrentConfig.Url, "URL", "u", "",
		"Mandatory: The url to send the request to")
	AssertSuccess(rootCmd.MarkFlagRequired("URL"))

	flags.StringVarP(&CurrentConfig.DataText, "data-text", "d", "",
		"Mandatory: The payload data in Protobuf text format. See "+GITHUB_REPOSITORY_LINK)
	AssertSuccess(rootCmd.MarkFlagRequired("data-text"))

	flags.StringArrayVarP(&CurrentConfig.RequestHeaders, "request-header", "H", []string{},
		"Adds the `string` header to the invocation of cURL. E.g. -H 'MyHeader: FooBar'")

	flags.StringVarP(&CurrentConfig.AdditionalCurlArgs, "curl-args", "C", "",
		"Additional cURL args which will be passed on to cURL during request invocation.")

	flags.BoolVarP(&CurrentConfig.Verbose, "verbose", "v", false,
		"Prints version and enables verbose output. Also activates D.")

	flags.BoolVarP(&CurrentConfig.DisplayBinaryAndHttp, "display-request-info", "D", false,
		"Displays the binary request and response as well as the non-binary response headers.")

	flags.StringVarP(&CurrentConfig.BinaryDisplayHexDumpArgs, "binary-hexdump-args", "b", "-C",
		"Arguments passed to Linux hexdump for formatting the display of binary protobuf payload. See 'man hexdump'")

	flags.BoolVarP(&CurrentConfig.ShowOutputOnly, "show-output-only", "q", false,
		"This feature is UNTESTED: Suppresses the display of the request and only displays the text output. Deactivates -v and -D.")

}

func setAndShowVersion() {
	rootCmd.Version = fmt.Sprintf("%s, build %s", version, commit)
	rootCmd.SetHelpTemplate("protocurl {{.Version}}\n\n" + rootCmd.HelpTemplate())
}

// AssertSuccess Use, when error indicates bug in code. Otherwise, use AbortIfFailed
func AssertSuccess(err error) {
	if err != nil {
		log.Panic(err)
	}
}

func AbortIfFailed(err error) {
	if err != nil {
		fmt.Printf("%s\n", err.Error())
		os.Exit(1)
	}
}

func main() {
	AbortIfFailed(rootCmd.Execute())
}
