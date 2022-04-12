package main

func intialiseFlags() {
	var flags = rootCmd.Flags()

	// Note. If the long / short name of the arguments are changed, then the Usage and Docs need to be checked for the argument.
	// It may be mentioned there and their mention needs to be updated.

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
		"Mandatory: The payload data in Protobuf text format. See "+GithubRepositoryLink)
	AssertSuccess(rootCmd.MarkFlagRequired("data-text"))

	flags.StringArrayVarP(&CurrentConfig.RequestHeaders, "request-header", "H", []string{},
		"Adds the `string` header to the invocation of cURL. E.g. -H 'MyHeader: FooBar'")

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
		"Suppresses all output except response Protobuf as text."+
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

	if len(CurrentConfig.AdditionalCurlArgs) != 0 || CurrentConfig.CustomCurlPath != "" {
		CurrentConfig.ForceCurl = true
	}

	if CurrentConfig.CustomProtocPath != "" {
		CurrentConfig.GlobalProtoc = true
	}

	if CurrentConfig.ForceCurl && CurrentConfig.ForceNoCurl {
		PanicWithMessage("Both --curl and --no-curl are active.\nI cannot use and not use curl.\nPlease check the supplied and implied arguments via -v.")
	}
}
