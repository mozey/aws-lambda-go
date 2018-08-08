package internal

import (
	"net/http"
	"encoding/json"
	"github.com/mozey/logutil"
)

func Index(w http.ResponseWriter, r *http.Request) {
	logutil.Debug("root")
	msg := Response{"It works!"}
	json.NewEncoder(w).Encode(msg)
}

