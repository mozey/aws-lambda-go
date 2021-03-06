package main

import (
	"fmt"
	"log"
	"net/http"
	"flag"
	"path/filepath"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func main() {
	certs := flag.String("certs", "", "path to certs")
	dataDir := flag.String("dataDir", "", "path to data dir")
	flag.Parse()

	http.HandleFunc("/", handler)
	crt := filepath.Join(*certs, "localhost.crt")
	key := filepath.Join(*certs, "localhost.key")

	http.Handle("/data/", http.StripPrefix(
		"/data/", http.FileServer(http.Dir(*dataDir))))

	log.Fatal(http.ListenAndServeTLS(":8080", crt, key, nil))
}