package internal

import (
	"net/http"
	"encoding/json"
	"fmt"
	"github.com/mozey/logutil"
)

func Foo(w http.ResponseWriter, r *http.Request) {
	logutil.Debug("foo")
	fooParam := r.URL.Query().Get("foo")
	if fooParam == "" {
		logutil.Debug("Missing foo")
		msg := Response{"Missing foo"}
		json.NewEncoder(w).Encode(msg)
		return
	}
	msg := Response{fmt.Sprintf("foo: %v", fooParam)}
	json.NewEncoder(w).Encode(msg)
}

