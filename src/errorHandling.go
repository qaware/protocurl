package main

import (
	"errors"
	"fmt"
	"log"
	"os"
)

// AssertSuccess Use, when error indicates bug in code. Otherwise, use the other functions
func AssertSuccess(err error) {
	if err != nil {
		log.Panic(err)
	}
}

func PrintError(err error) {
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, "Error: "+err.Error())
	}
}

func PanicOnError(err error) {
	if err != nil {
		panic(interface{}(err))
	}
}

func PanicWithMessage(message string) {
	panic(interface{}(errors.New(message)))
}

func PanicWithMessageOnError(err error, lazyMessage func() string) {
	if err != nil {
		panic(interface{}(lazyMessage() + "\nUnderlying error: " + err.Error()))
	}
}
