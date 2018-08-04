package main

import (
	"flag"
	"os"
	"log"
	"fmt"
	"encoding/json"
	"strings"
	"path"
	"sort"
	"github.com/mozey/logutil"
	"io/ioutil"
)

type ConfigMap map[string]string

var Config = os.Getenv("APP_CONFIG")

type ArgMap []string

func (a *ArgMap) String() string {
	return strings.Join(*a, ", ")
}

func (a *ArgMap) Set(value string) error {
	*a = append(*a, value)
	return nil
}

var keys ArgMap
var values ArgMap

func main() {
	log.SetFlags(log.Lshortfile)

	flag.Var(&keys, "key", "Set key and print config JSON")
	flag.Var(&values, "value", "Value for last key specified")
	update := flag.Bool("update", false, "Update config.json")
	flag.Parse()

	b, err := ioutil.ReadFile(Config)
	if err != nil {
		logutil.Debugf("Loading config from: %v", Config)
		log.Panic(err)
	}

	// The Config file must have a flat key value structure
	c := ConfigMap{}
	err = json.Unmarshal(b, &c)
	if err != nil {
		log.Panic(err)
	}

	// Set existing config keys
	var configKeys []string
	for k := range c {
		configKeys = append(configKeys, k)
	}
	// Config file must be in app dir
	configKeys = append(configKeys, "APP_DIR")
	c["APP_DIR"] = path.Dir(Config)
	// Sort
	sort.Strings(configKeys)

	if len(keys) > 0 {
		// Set Config key value

		// Validate input
		for i, key := range keys {
			if i > len(values) - 1 {
				log.Panicf("Missing value for key: %v", key)
			}
			value := values[i]

			// Set key value
			c[key] = value
		}

		// Update config
		b, _ := json.MarshalIndent(c, "", "    ")
		if *update {
			logutil.Debugf("Updating %v", Config)
			ioutil.WriteFile(Config, b, 0)
		} else {
			// Print json
			fmt.Print(string(b))
		}

	} else {
		// Print commands to set env
		for _, key := range configKeys {
			fmt.Println(fmt.Sprintf("export %v=%v", key, c[key]))
		}
	}
}
