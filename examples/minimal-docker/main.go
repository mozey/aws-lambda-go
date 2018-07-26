package main

import (
	"io/ioutil"
	"net/http"
	"log"
)

func main() {
	log.SetFlags(log.Ldate | log.Ltime | log.LUTC | log.Lshortfile)

	resp, err := http.Get("https://google.com")
	if err != nil {
		log.Fatal(err)
	}
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatal(err)
	}
	log.Print("body length: ", len(body))
}

