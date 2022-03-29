package main

import (
	json2 "encoding/json"
	"fmt"
	"github.com/spf13/cobra"
	"google.golang.org/protobuf/encoding/prototext"
	"log"
	"os"
)

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
			printVersionInfo()
		}

		if CurrentConfig.Verbose {
			fmt.Printf("Adding default header argument to request headers : %s\n", DefaultPrependedHeaderArg)
		}
		CurrentConfig.RequestHeaders = append(CurrentConfig.RequestHeaders)

		if CurrentConfig.Verbose {
			printArgs()
		}

		fmt.Println("<TODO: implement protocurl>")
	},
	Version: versionCommitString,
}

func printArgs() {
	json, err := json2.MarshalIndent(CurrentConfig, "", "  ")
	if err != nil {
		log.Fatalf(err.Error())
	}
	fmt.Printf("Invoked with following default & parsed arguments: %s\n", string(json))
}

func printVersionInfo() {
	fmt.Printf("protocurl version %s\n", versionCommitString)
}

func init() {
	versionCommitString = fmt.Sprintf("%s, build %s", version, commit)

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
		"Mandatory: The payload data in Protobuf text format. See https://github.com/qaware/protocurl")
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
	bla := prototext.MarshalOptions{}
	log.Println(bla)

	AbortIfFailed(rootCmd.Execute())
}
