package internal

import (
	"net/http"
	"log"
	"encoding/json"
	"fmt"
)

func Foo(w http.ResponseWriter, r *http.Request) {
	log.Print("foo")
	fooParam := r.URL.Query().Get("foo")
	if fooParam == "" {
		log.Print("Missing foo")
		msg := Message{"Missing foo"}
		json.NewEncoder(w).Encode(msg)
		return
	}
	//msg := Message{fmt.Sprintf("%v bar", fooParam)}
	msg := Message{fmt.Sprintf("%v baz", fooParam)}
	json.NewEncoder(w).Encode(msg)
}

