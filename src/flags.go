package main

import (
	"fmt"
	"strings"
)

type InTextType string

const (
	IText = "text"
	IJson = "json"
)

type OutTextType string

const (
	OText       = "text"
	OJsonDense  = "json"
	OJsonPretty = "json:pretty"
)

var DisplayType = map[string]string{
	IText:       "Text",
	IJson:       "JSON",
	OJsonPretty: "JSON",
}

func displayIn(inText InTextType) string {
	return DisplayType[string(inText)]
}

func displayOut(outText OutTextType) string {
	return DisplayType[string(outText)]
}

var explicitlySupportedMethods = map[string]bool{
	"GET":  true,
	"POST": true,
}

var tmpInTextType string
var tmpOutTextType string
var tmpDataTextInferredType InTextType

const inferredMessagePathPrefix = ".."

func intialiseFlags() {
	var flags = rootCmd.Flags()

	// Note. If the long / short name of the arguments are changed, then the Usage and Docs need to be checked for the argument.
	// It may be mentioned there and their mention needs to be updated.

	flags.StringVarP(&CurrentConfig.ProtoFilesDir, "proto-dir", "I", "/proto",
		"Uses the specified directory to find the proto-file.")

	flags.StringVarP(&CurrentConfig.ProtoInputFilePath, "proto-file", "f", "",
		"Uses the specified file path to find the Protobuf definition of the message types within 'proto-dir' (relative file path).")

	flags.BoolVarP(&CurrentConfig.InferProtoFiles, "infer-files", "F", false,
		"Infer the correct files containing the relevant protobuf messages. All proto files in the proto directory provided by -I will be used. If no -f <file> is provided, this -F is set and the files are inferred.")

	flags.StringVarP(&CurrentConfig.Method, "method", "X", "POST",
		"HTTP request method. POST and GET are explicitly supported. Other methods are passed on on to curl optimistically.")

	flags.StringVarP(&CurrentConfig.RequestType, "request-type", "i", "",
		"Message name or full package path of the Protobuf request type. The path can be shortened to '..', if the name of the request message is unique. Mandatory for POST requests. E.g. mypackage.MyRequest or ..MyRequest")

	flags.StringVarP(&CurrentConfig.ResponseType, "response-type", "o", "",
		"The Protobuf response type. See -i <request-type>. Overrides --decode-raw. If not set, then --decode-raw is used.")

	flags.BoolVar(&CurrentConfig.DecodeRawResponse, "decode-raw", false,
		"Decode the response into textual format without the schema by only showing field numbers and inferred field types. Types may be incorrect. Only output format "+string(OText)+" is supported. Use -o <response-type> to see correct contents.")

	flags.StringVar(&tmpInTextType, "in", "",
		"Specifies, in which format the input -d should be interpreted in. 'text' (default) uses the Protobuf text format and 'json' uses JSON. "+
			"The type is inferred as JSON if the first token is a '{'.")

	flags.StringVar(&tmpOutTextType, "out", "",
		"Produces the output in the specified format. 'text' (default) produces Protobuf text format. 'json' produces dense JSON and "+
			"'json:pretty' produces pretty-printed JSON. "+
			"The produced JSON always uses the original Protobuf field names instead of lowerCamelCasing them.")

	flags.StringVarP(&CurrentConfig.Url, "url", "u", "",
		"Mandatory: The url to send the request to")
	AssertSuccess(rootCmd.MarkFlagRequired("url"))

	flags.StringVarP(&CurrentConfig.DataText, "data-text", "d", "",
		"The payload data in Protobuf text format or JSON. "+
			"It is inferred from the input as JSON if the first token is a '{'. "+
			"The format can be set explicitly via --in. Mandatory if request-type is provided."+
			"See "+GithubRepositoryLink)

	flags.BoolVarP(&CurrentConfig.NoDefaultHeaders, "no-default-headers", "n", false,
		"Default headers (e.g. \"Content-Type\") will not be passed to curl. Assumes --curl. Use \"-n -H 'Content-Type: FooBar'\" to override the default content type.")

	flags.StringArrayVarP(&CurrentConfig.RequestHeaders, "request-header", "H", []string{},
		"Adds the `string` header to the invocation of cURL. This option is not supported when --no-curl is active. E.g. -H 'MyHeader: FooBar'.")

	flags.BoolVar(&CurrentConfig.GlobalProtoc, "protoc", false,
		"Forces the use of a global protoc executable found in PATH or via --protoc-path instead of using the bundled one. If none was found, then exits with an error.")

	flags.StringVar(&CurrentConfig.CustomProtocPath, "protoc-path", "",
		"Uses the given path to invoke protoc instead of searching for "+ProtocExecutableName+" in PATH. Also activates --protoc.")

	flags.BoolVar(&CurrentConfig.ForceCurl, "curl", false,
		"Forces the use of curl executable found in PATH. If none was found, then exits with an error.")

	flags.StringVar(&CurrentConfig.CustomCurlPath, "curl-path", "",
		"Uses the given path to invoke curl instead of searching for "+CurlExecutableName+" in PATH. Also activates --curl.")

	flags.BoolVar(&CurrentConfig.ForceNoCurl, "no-curl", false,
		"Forces the use of the built-in internal http request instead of curl.")

	flags.StringVarP(&CurrentConfig.AdditionalCurlArgs, "curl-args", "C", "",
		"Additional cURL args which will be passed on to cURL during request invocation for further configuration. Also activates --curl.")

	flags.BoolVarP(&CurrentConfig.Verbose, "verbose", "v", false,
		"Prints version and enables verbose output. Also activates -D.")

	flags.BoolVarP(&CurrentConfig.DisplayBinaryAndHttp, "display-binary-and-http", "D", false,
		"Displays the binary request and response as well as the non-binary response headers.")

	flags.BoolVarP(&CurrentConfig.ShowOutputOnly, "show-output-only", "q", false,
		"Suppresses all output except response Protobuf as text. "+
			"Overrides and deactivates -v and -D. Errors are still printed to stderr.")
}

func propagateFlags() {

	if CurrentConfig.Verbose {
		CurrentConfig.DisplayBinaryAndHttp = true
	}

	if CurrentConfig.ShowOutputOnly {
		CurrentConfig.Verbose = false
		CurrentConfig.DisplayBinaryAndHttp = false
	}

	if CurrentConfig.ResponseType == "" && !CurrentConfig.DecodeRawResponse {
		CurrentConfig.DecodeRawResponse = true
		if CurrentConfig.Verbose {
			fmt.Println("Response type (-o) was not provided, hence --decode-raw will be used.")
		}

	} else if CurrentConfig.ResponseType != "" && CurrentConfig.DecodeRawResponse {
		CurrentConfig.DecodeRawResponse = false
		if CurrentConfig.Verbose {
			fmt.Println("Response type (-o) was provided, hence --decode-raw will be overidden.")
		}
	}

	if !explicitlySupportedMethods[CurrentConfig.Method] && CurrentConfig.Verbose {
		fmt.Printf("Got method %s which is not explicitly supported. Proceeding optimistically.", CurrentConfig.Method)
	}

	if CurrentConfig.Method == "POST" {
		if CurrentConfig.RequestType == "" {
			PanicWithMessage("With method POST, a request type and the data text is needed. However, request type was not provided. Aborting.")
		}
	}

	if CurrentConfig.DataText != "" && CurrentConfig.RequestType == "" {
		PanicWithMessage("Non-empty data-body as provided, but no request type was given. Hence, encoding of data-body is not possible.")
	}

	if strings.HasPrefix(strings.TrimSpace(CurrentConfig.DataText), "{") {
		tmpDataTextInferredType = IJson
	} else {
		tmpDataTextInferredType = IText
	}
	if CurrentConfig.Verbose {
		fmt.Printf("Inferred input text type as %s.\n", tmpDataTextInferredType)
	}

	if tmpInTextType == IText {
		CurrentConfig.InTextType = IText
	} else if tmpInTextType == IJson {
		CurrentConfig.InTextType = IJson
	} else if tmpInTextType != "" {
		PanicWithMessage(fmt.Sprintf("Unknown input format %s. Expected %s or %s for --in", tmpInTextType, IText, IJson))
	} else {
		CurrentConfig.InTextType = tmpDataTextInferredType
	}

	if CurrentConfig.InTextType != tmpDataTextInferredType {
		PanicWithMessage(fmt.Sprintf("Specified input format %s is different from inferred format %s. "+
			"Please check your arguments.", CurrentConfig.InTextType, tmpDataTextInferredType))
	}

	if tmpOutTextType == OText {
		CurrentConfig.OutTextType = OText
	} else if tmpOutTextType == OJsonDense {
		CurrentConfig.OutTextType = OJsonDense
	} else if tmpOutTextType == OJsonPretty {
		CurrentConfig.OutTextType = OJsonPretty
	} else if tmpOutTextType != "" {
		PanicWithMessage(fmt.Sprintf("Unknown output format %s. Expected %s, %s or %s for --out", tmpOutTextType, OText, OJsonDense, OJsonPretty))
	} else {
		CurrentConfig.OutTextType = OutTextType(tmpDataTextInferredType)
	}

	if len(CurrentConfig.AdditionalCurlArgs) != 0 || CurrentConfig.CustomCurlPath != "" {
		CurrentConfig.ForceCurl = true
	}

	if CurrentConfig.CustomProtocPath != "" {
		CurrentConfig.GlobalProtoc = true
	}

	if CurrentConfig.ForceCurl && CurrentConfig.ForceNoCurl {
		PanicWithMessage("Both --curl and --no-curl are active.\nI cannot use and not use curl.\nPlease check the supplied and implied arguments via -v.")
	}

	if CurrentConfig.InferProtoFiles && CurrentConfig.ProtoInputFilePath != "" {
		PanicWithMessage("Both -F is set and -f <file> is provided. Please provide only one of these.")
	}

	if CurrentConfig.ProtoInputFilePath == "" {
		CurrentConfig.InferProtoFiles = true
		if CurrentConfig.Verbose {
			fmt.Printf("Infering proto files (-F), since -f <file> was not provided.\n")
		}
	}

	if CurrentConfig.DecodeRawResponse && (strings.Contains(string(CurrentConfig.OutTextType), "json")) {
		PanicWithMessage("Decoding of raw messages is not supported with output format " + string(CurrentConfig.OutTextType) + ". Please use " + string(OText) + " instead.")
	}

	if CurrentConfig.ForceNoCurl && len(CurrentConfig.RequestHeaders) != 0 {
		PanicDueToUnsupportedHeadersWhenInternalHttp(CurrentConfig.RequestHeaders)
	}
}

func PanicDueToUnsupportedHeadersWhenInternalHttp(headers []string) {
	PanicWithMessage(fmt.Sprintf("Non-default or custom headers are not supported when  using internal http. Please provide curl in path and avoid using --no-curl. Found headers: %+q", headers))
}
