package main

import (
	"log"
	"net/http"
	"github.com/apex/gateway"
	"os"
	"encoding/json"
	"fmt"
)

func main() {
	http.HandleFunc("/", root)
	http.HandleFunc("/foo", foo)

	ApexGatewayDisabled := os.Getenv("APEX_GATEWAY_DISABLED")
	if ApexGatewayDisabled == "true" {
		log.Print("Using only net/http")
		log.Fatal(http.ListenAndServe(":3000", nil))
	} else {
		log.Print("Use net/http compatible wrapper around lambda.Start")
		log.Fatal(gateway.ListenAndServe(":3000", nil))
	}
}

// Message contains a simple message response.
type Message struct {
	Message string `json:"message"`
}

func root(w http.ResponseWriter, r *http.Request) {
	log.Print("root")
	msg := Message{"It works!"}
	json.NewEncoder(w).Encode(msg)
}

func foo(w http.ResponseWriter, r *http.Request) {
	log.Print("foo")
	fooParam := r.URL.Query().Get("foo")
	//if fooParams == nil {
	if fooParam == "" {
		log.Print("Missing foo")
		msg := Message{"Missing foo"}
		json.NewEncoder(w).Encode(msg)
		return
	}
	//msg := Message{fmt.Sprintf("%v bar", fooParams[0])}
	msg := Message{fmt.Sprintf("%v bar", fooParam)}
	json.NewEncoder(w).Encode(msg)
}

