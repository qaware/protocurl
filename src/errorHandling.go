package main

import (
	"fmt"
	"log"
)

// AssertSuccess Use, when error indicates bug in code. Otherwise, use the other functions
func AssertSuccess(err error) {
	if err != nil {
		log.Panic(err)
	}
}

func PrintError(err error) {
	if err != nil {
		fmt.Println("Error: " + err.Error())
	}
}

func PanicOnError(err error) {
	if err != nil {
		fmt.Println(err.Error())
		panic(interface{}(err))
	}
}

func PanicWithMessageOnError(err error, lazyMessage func() string) {
	if err != nil {
		fmt.Println(lazyMessage())
		panic(interface{}(err))
	}
}
