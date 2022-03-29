package main

import (
	"google.golang.org/protobuf/encoding/prototext"
	"log"
)

// Use Cobra for CLI: https://github.com/spf13/cobra
// Examples: https://github.com/qaware/go-for-operations/blob/master/workshop/challenge-1/challenge-1.md

func main() {
	bla := prototext.MarshalOptions{}

	log.Println(bla)

	log.Println("hello world")
	log.Fatal("blubb")
}
