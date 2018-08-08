package internal

import (
	"net/http"
	"encoding/json"
	"fmt"
	"github.com/mozey/logutil"
)

func Bar(w http.ResponseWriter, r *http.Request) {
	logutil.Debug("bar")
	barParam := r.URL.Query().Get("bar")
	if barParam == "" {
		logutil.Debug("Missing bar")
		msg := Response{"Missing bar"}
		json.NewEncoder(w).Encode(msg)
		return
	}
	msg := Response{fmt.Sprintf("bar: %v", barParam)}
	json.NewEncoder(w).Encode(msg)
}

