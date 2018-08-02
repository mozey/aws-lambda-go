package internal

import "net/http"

func InitRoutes() {
	http.HandleFunc("/", Root)
	http.HandleFunc("/foo", Foo)
}