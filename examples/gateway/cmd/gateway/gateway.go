package main

import (
	"log"
	"github.com/apex/gateway"
	"github.com/mozey/aws-lambda-go/examples/gateway/internal"
)

func main() {
	h := internal.NewRouter()
	log.Print("Use net/http compatible wrapper around lambda.Start")
	log.Fatal(gateway.ListenAndServe("", h))
}




