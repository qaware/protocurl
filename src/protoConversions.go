package main

import (
	"google.golang.org/protobuf/encoding/prototext"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoregistry"
	"google.golang.org/protobuf/types/dynamicpb"
	"strings"
)

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
