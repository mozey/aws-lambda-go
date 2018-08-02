package main

import (
	"log"
	"net/http"
	"github.com/mozey/aws-lambda-go/examples/gateway/internal"
)

func main() {
	internal.InitRoutes()
	log.Print("Using only net/http")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
