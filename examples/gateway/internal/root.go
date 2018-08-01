package internal

import (
	"net/http"
	"log"
	"encoding/json"
)

func Root(w http.ResponseWriter, r *http.Request) {
	log.Print("root")
	msg := Message{"It works!"}
	json.NewEncoder(w).Encode(msg)
}

