package internal

import (
	"net/http"
	"github.com/gorilla/mux"
	"io/ioutil"
	"io"
	"log"
	"encoding/json"
	"fmt"
	"net/url"
)

type Route struct {
	Path        string
	HandlerFunc http.HandlerFunc
}

type Routes []Route

var routes = Routes{
	Route{
		"/", Index,
	},

	Route{
		"/foo{ignore:.*}", Foo,
	},
	Route{
		"/bar{ignore:.*}", Bar,
	},

	// Echo request when no match
	Route{
		"/{everything:.*}", Echo,
	},
}

type RequestBody struct {
	String string
}

// Request is the same as http.Request minus the bits that break json.Marshall
type Request struct {
	Method           string
	URL              *url.URL
	Proto            string // "HTTP/1.0"
	ProtoMajor       int    // 1
	ProtoMinor       int    // 0
	Header           http.Header
	Body             RequestBody
	ContentLength    int64
	TransferEncoding []string
	Host             string
	//Form url.Values
	//PostForm url.Values
	//MultipartForm *multipart.Form
	Trailer    http.Header
	RemoteAddr string
	RequestURI string
	//TLS *tls.ConnectionState
}

// Response contains a simple message response.
type Response struct {
	Message string `json:"message"`
}

const megabytes = 1048576

// Echo the http request
func Echo(w http.ResponseWriter, r *http.Request) {
	e := Request{}
	e.Method = r.Method
	e.URL = r.URL
	e.Proto = r.Proto
	e.ProtoMajor = r.ProtoMajor
	e.ProtoMinor = r.ProtoMinor
	e.Header = r.Header
	e.Body = RequestBody{}
	body, err := ioutil.ReadAll(io.LimitReader(r.Body, 1*megabytes))
	if err != nil {
		log.Fatal(err)
	}
	if err := r.Body.Close(); err != nil {
		log.Fatal(err)
	}
	e.Body.String = string(body)
	e.ContentLength = r.ContentLength
	e.TransferEncoding = r.TransferEncoding
	e.Host = r.Host
	e.Trailer = r.Trailer
	e.RemoteAddr = r.RemoteAddr
	e.RequestURI = r.RequestURI

	b, err := json.Marshal(e)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Fprint(w, string(b))
}

func NewRouter() *mux.Router {
	// StrictSlash must be false otherwise index is not loaded consistently
	router := mux.NewRouter().StrictSlash(false)
	for _, route := range routes {
		var handler http.Handler
		handler = route.HandlerFunc
		// TODO Logger
		//handler = logger(handler)
		router.
			// Paths should not be case sensitive
			Path(route.Path).
			// Don't allow duplicate paths in the routes definition
			Name(route.Path).
			Handler(handler)
	}
	return router
}
