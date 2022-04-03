package main

import (
	"google.golang.org/protobuf/encoding/prototext"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoregistry"
	"google.golang.org/protobuf/types/dynamicpb"
	"strings"
)

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
		text = string(textBytes) // todo. which encoding is used here?
	}

	return text, msg
}
