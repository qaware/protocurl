package main

import (
	"bufio"
	"bytes"
	"encoding/hex"
	json2 "encoding/json"
	"errors"
	"fmt"
	"github.com/spf13/cobra"
	"google.golang.org/protobuf/encoding/prototext"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protodesc"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/reflect/protoregistry"
	"google.golang.org/protobuf/types/descriptorpb"
	"google.golang.org/protobuf/types/dynamicpb"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
	"strings"
)

const GITHUB_REPOSITORY_LINK = "https://github.com/qaware/protocurl"

// protoc --include_imports -o/out.bin -I /proto new-file.proto

// protoc -I /proto --go_out=out --go_opt=Mpath/to/new-file.proto=package.local/proto/path/to/new-file new-file.proto

// Use Cobra for CLI: https://github.com/spf13/cobra
// Examples: https://github.com/qaware/go-for-operations/blob/master/workshop/challenge-1/challenge-1.md

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

const DefaultPrependedHeaderArg = "'Content-Type: application/x-protobuf'"
const VISUAL_SEPARATOR = "==========================="
const SEND = ">>>"
const RECV = "<<<"

var CurrentConfig = Config{}

var PROTOC string

var rootCmd = &cobra.Command{
	Short:                 "Send and receive Protobuf messages over HTTP via `curl` and interact with it using human-readable text formats.",
	Use:                   "protocurl [flags] -f proto-file -i request-type -o response-type -u url -d request-text",
	Example:               "  protocurl -I my-protos -f messages.proto -i package.path.Req -o package.path.Resp -u http://foo.com/api -d \"myField: true, otherField: 1337\"",
	Args:                  cobra.OnlyValidArgs,
	DisableFlagsInUseLine: true,
	Run: func(cmd *cobra.Command, args []string) {
		if CurrentConfig.Verbose {
			CurrentConfig.DisplayBinaryAndHttp = true
			printVersionInfo(cmd)
		}

		if CurrentConfig.Verbose {
			fmt.Printf("Adding default header argument to request headers : %s\n", DefaultPrependedHeaderArg)
		}
		CurrentConfig.RequestHeaders = append(CurrentConfig.RequestHeaders)

		if CurrentConfig.Verbose {
			printArgs()
		}

		protoInputFileDescriptorSetMessage := convertProtoInputFileToDescriptorSet()

		if CurrentConfig.Verbose {
			fmt.Println("Using .proto descriptor:" + prototext.Format(protoInputFileDescriptorSetMessage))
		}

		protoRegistryFiles, err := protodesc.NewFiles(protoInputFileDescriptorSetMessage)
		PanicOnError(err)

		requestBinary, _ := protoTextToMsgAndBinary(CurrentConfig.RequestType, CurrentConfig.DataText, protoRegistryFiles)

		reconstructedRequestText, _ := protoBinaryToMsgAndText(CurrentConfig.RequestType, requestBinary, true, protoRegistryFiles)

		fmt.Printf("%s Request Text   %s %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, SEND, reconstructedRequestText)

		if CurrentConfig.DisplayBinaryAndHttp {
			fmt.Printf("%s Request Binary %s %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, RECV, hex.Dump(requestBinary))
		}

		log.Println("<todo: implement>")
	},
}

func resolveMessageByName(messageType string, registry *protoregistry.Files) *protoreflect.MessageDescriptor {
	descriptor, err := registry.FindDescriptorByName(protoreflect.FullName(messageType))
	requestDescriptor := descriptor.(protoreflect.MessageDescriptor)
	EnsureMessageDescriptorIsResolved(requestDescriptor, messageType, err)
	return &requestDescriptor
}

func EnsureMessageDescriptorIsResolved(descriptor protoreflect.Descriptor, requestType string, err error) {
	if descriptor == nil {
		PanicOnError(errors.New(
			"I couldn't find any Protobuf message for the message package-path " + requestType + ".\n" +
				"Did you correctly -I (include) your proto files directory?\n" +
				"Did you correctly specify the full message package-path to your Protobuf message type?\n" +
				"Try again with -v (verbose).\n" +
				"Error: " + err.Error(),
		))
	}
}

// Read the given proto file as a FileDescriptorSet so that we work with it within Go's SDK.
// protoc --include_imports -o/out.bin -I /proto new-file.proto
func convertProtoInputFileToDescriptorSet() *descriptorpb.FileDescriptorSet {
	PROTOC = findProtocExec()

	protoDir := CurrentConfig.ProtoFilesDir
	protoIncludeArgs := []string{
		path.Join(protoDir, CurrentConfig.ProtoInputFilePath),
		"-I",
		protoDir,
	}

	currentDir, errWd := os.Getwd()
	PanicOnError(errWd)

	tmpDir, errTmp := ioutil.TempDir(currentDir, "protocurl-temp-*")
	PanicOnError(errTmp)
	defer func(path string) {
		_ = os.RemoveAll(path)
	}(tmpDir)

	inputFileBinPath := path.Join(tmpDir, "inputfile.bin")
	actionDescription := "convert input .proto to FileDescriptorSet"

	protocErr := bytes.NewBuffer([]byte{})
	moreArgs := []string{"--include_imports", "-o", inputFileBinPath}

	protocCmd := exec.Cmd{
		Path:   PROTOC,
		Args:   append([]string{PROTOC}, append(moreArgs, protoIncludeArgs...)...),
		Stderr: bufio.NewWriter(protocErr),
	}
	err := protocCmd.Run()

	PanicWithMessageOnError(err, "Failed to "+actionDescription+". Error:\n"+protocErr.String())

	if protocErr.Len() != 0 {
		fmt.Println("Encountered errors while attempting to " + actionDescription + " via protoc:\n" + protocErr.String())
	}

	inputFileBin, err := ioutil.ReadFile(inputFileBinPath)
	PanicOnError(err)

	mutableFileDescriptorSet := descriptorpb.FileDescriptorSet{}

	err = proto.Unmarshal(inputFileBin, &mutableFileDescriptorSet)
	PanicOnError(err)

	return &mutableFileDescriptorSet
}

func protoTextToMsgAndBinary(messageType string, text string, registry *protoregistry.Files) ([]byte, *dynamicpb.Message) {
	messageDescriptor := resolveMessageByName(messageType, registry)
	msg := dynamicpb.NewMessage(*messageDescriptor)

	err := prototext.Unmarshal([]byte(text), msg) // todo. which encoding is used here?
	PanicOnError(err)

	binary, err := proto.Marshal(msg)
	PanicOnError(err)

	return binary, msg
}

func protoBinaryToMsgAndText(messageType string, binary []byte, prettyFormat bool, registry *protoregistry.Files) (string, *dynamicpb.Message) {
	messageDescriptor := resolveMessageByName(messageType, registry)
	msg := dynamicpb.NewMessage(*messageDescriptor)

	err := proto.Unmarshal(binary, msg)
	PanicOnError(err)

	var text string
	if prettyFormat {
		text = prototext.Format(msg)
		text = strings.TrimSuffix(text, "\n")
	} else {
		textBytes, err := prototext.Marshal(msg)
		PanicOnError(err)
		text = string(textBytes)
	}

	return text, msg // todo. which encoding is used here?
}

var alreadyReportedProtoc = false

func findProtocExec() (protocExec string) {
	protocExec, err := exec.LookPath("protoc")
	PanicWithMessageOnError(err, "I could not find a 'protoc' executable. Please check your PATH.")
	if CurrentConfig.Verbose && !alreadyReportedProtoc {
		fmt.Println("Found protoc: " + protocExec)
		alreadyReportedProtoc = true
	}
	return
}

func printArgs() {
	fmt.Println("Invoked with following default & parsed arguments:")
	printAsJson(CurrentConfig)
}

func printAsJson(obj interface{}) {
	json, err := json2.MarshalIndent(obj, "", "  ")
	PanicOnError(err)
	fmt.Println(json)
}

func printVersionInfo(cmd *cobra.Command) {
	fmt.Printf("protocurl %s\n", cmd.Version)
}

func init() {

	setAndShowVersion()

	var flags = rootCmd.Flags()

	flags.StringVarP(&CurrentConfig.ProtoFilesDir, "proto-dir", "I", "/proto",
		"Uses the specified directory to find the proto-file.")

	flags.StringVarP(&CurrentConfig.ProtoInputFilePath, "proto-file", "f", "",
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

	flags.BoolVarP(&CurrentConfig.DisplayBinaryAndHttp, "display-binary-and-http", "D", false,
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

func PanicOnError(err error) {
	if err != nil {
		fmt.Printf(err.Error())
		panic(err)
	}
}

func PanicWithMessageOnError(err error, message string) {
	if err != nil {
		fmt.Printf(message)
		panic(err)
	}
}

func main() {
	AssertSuccess(rootCmd.Execute())
}
