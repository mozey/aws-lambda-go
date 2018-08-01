package internal

import "net/http"

func Init() {
	http.HandleFunc("/", Root)
	http.HandleFunc("/foo", Foo)
}