package main

import (
	"bufio"
	"bytes"
	"fmt"
	"google.golang.org/protobuf/encoding/prototext"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protodesc"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/reflect/protoregistry"
	"google.golang.org/protobuf/types/descriptorpb"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

/*
Given a directory of .proto files, we use `protoc` to convert these to
an equivalent FileDescriptorSet payload where imports have been resolved.
This FileDescriptorSet is then promoted to a *protoregistry.Files where
messages types given by the user can be looked up - and where payloads of these types
can be created.

See:
	FileDescriptorSet: https://github.com/protocolbuffers/protobuf/blob/main/src/google/protobuf/descriptor.proto
	https://pkg.go.dev/google.golang.org/protobuf/reflect/protoreflect
	https://pkg.go.dev/google.golang.org/protobuf/reflect/protodesc
	https://pkg.go.dev/google.golang.org/protobuf/reflect/protoregistry
*/

// Read the given proto file as a FileDescriptorSet so that we work with it within Go's SDK.
// protoc --include_imports -o/out.bin -I /proto new-file.proto
func convertProtoFilesToProtoRegistryFiles() *protoregistry.Files {
	protocPath, isBundled := findProtocExecutable()

	tmpDir, errTmp := ioutil.TempDir(os.TempDir(), "protocurl-temp-*")
	PanicOnError(errTmp)
	defer func() { _ = os.RemoveAll(tmpDir) }()

	inputFileBinPath := filepath.Join(tmpDir, "inputfile.bin")
	protoDir := CurrentConfig.ProtoFilesDir

	googleProtobufInclude := getGoogleProtobufIncludePath(isBundled)

	protocArgs := []string{
		protocPath,
		"--include_imports",
		"-o", inputFileBinPath,
		"-I", googleProtobufInclude,
		"-I", protoDir,
		filepath.Join(protoDir, CurrentConfig.ProtoInputFilePath),
	}

	protocErr := bytes.NewBuffer([]byte{})

	protocCmd := exec.Cmd{
		Path:   protocPath,
		Args:   protocArgs,
		Stderr: bufio.NewWriter(protocErr),
	}
	err := protocCmd.Run()

	actionDescription := "convert input .proto to FileDescriptorSet"

	PanicWithMessageOnError(err, func() string {
		return "Failed to " + actionDescription + ". Error: " + err.Error() + "\nprotoc stderr:\n" + protocErr.String()
	})

	if protocErr.Len() != 0 {
		_, _ = fmt.Fprintln(os.Stderr, "Encountered errors while attempting to "+actionDescription+" via protoc:\n"+protocErr.String())
	}

	inputFileBin, err := ioutil.ReadFile(inputFileBinPath)
	PanicOnError(err)

	protoFileDescriptorSet := descriptorpb.FileDescriptorSet{}
	err = proto.Unmarshal(inputFileBin, &protoFileDescriptorSet)
	PanicOnError(err)

	if CurrentConfig.Verbose {
		fmt.Printf("%s .proto descriptor %s\n%s\n", VISUAL_SEPARATOR, VISUAL_SEPARATOR, strings.TrimSpace(prototext.Format(&protoFileDescriptorSet)))
	}

	protoRegistryFiles, err := protodesc.NewFiles(&protoFileDescriptorSet)
	PanicOnError(err)

	return protoRegistryFiles
}

func resolveMessageByName(messageType string, registry *protoregistry.Files) *protoreflect.MessageDescriptor {
	descriptor, err := registry.FindDescriptorByName(protoreflect.FullName(messageType))
	requestDescriptor := descriptor.(protoreflect.MessageDescriptor)
	EnsureMessageDescriptorIsResolved(requestDescriptor, messageType, err)
	return &requestDescriptor
}
