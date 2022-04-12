package main

import (
	"google.golang.org/protobuf/encoding/prototext"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoregistry"
	"google.golang.org/protobuf/types/dynamicpb"
	"strings"
)

/*
Given a *protoregistry.Files corresponding to the provided .proto files, we can
resolve the protobuf message descriptor given its name and use dynamicpb.NewMessage
to create a message of that message type without needing to generate go code at runtime.

Given a message, simple converters in prototext can be used for the conversion between binary and text format.

See:
	https://pkg.go.dev/google.golang.org/protobuf/encoding/prototext
	https://pkg.go.dev/google.golang.org/protobuf/types/dynamicpb
	https://pkg.go.dev/google.golang.org/protobuf/reflect/protoregistry

*/

var binaryMarshalOptions = proto.MarshalOptions{
	Deterministic: true, // stabilises test output
}

var textFormatOptions = prototext.MarshalOptions{
	Multiline: true,
	Indent:    "  ",
}

func protoTextToMsgAndBinary(messageType string, text string, registry *protoregistry.Files) ([]byte, *dynamicpb.Message) {
	messageDescriptor := resolveMessageByName(messageType, registry)
	msg := dynamicpb.NewMessage(*messageDescriptor)

	err := prototext.Unmarshal([]byte(text), msg) // todo. which encoding is used here?
	PanicOnError(err)

	binary, err := binaryMarshalOptions.Marshal(msg)
	PanicOnError(err)

	return binary, msg
}

func protoBinaryToMsgAndText(messageType string, binary []byte, registry *protoregistry.Files) (string, *dynamicpb.Message) {
	messageDescriptor := resolveMessageByName(messageType, registry)
	msg := dynamicpb.NewMessage(*messageDescriptor)

	err := proto.Unmarshal(binary, msg)
	PanicOnError(err)

	textBytes, err := textFormatOptions.Marshal(msg)
	PanicOnError(err)
	text := string(textBytes) // todo. which encoding is used here?
	text = strings.TrimSuffix(text, "\n")

	return text, msg
}
