package main

import (
	"flag"
	"log"
	"fmt"
	"encoding/json"
	"strings"
	"path"
	"sort"
	"github.com/mozey/logutil"
	"io/ioutil"
	"os"
)

type ConfigMap map[string]string

// AppDir is the application root
var AppDir string
// ConfigEnv can be used for multiple deployments
var ConfigEnv string

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

	// If not compiled with ldflags see if APP_DIR is set on env
	if AppDir == "" {
		AppDir = os.Getenv("APP_DIR")
	}

	var config string
	// If not compiled with ldflags see if APP_CONFIG_ENV is set on env
	if ConfigEnv == "" {
		ConfigEnv = os.Getenv("APP_CONFIG_ENV")
	}
	// By default only use a single config file
	if ConfigEnv == "" {
		config = path.Join(AppDir, "config.json")
	} else {
		config = path.Join(AppDir, fmt.Sprintf("config.%v.json", ConfigEnv))
	}

	flag.Var(&keys, "key", "Set key and print config JSON")
	flag.Var(&values, "value", "Value for last key specified")
	update := flag.Bool("update", false, "Update config.json")
	flag.Parse()

	b, err := ioutil.ReadFile(config)
	if err != nil {
		logutil.Debugf("Loading config from: %v", config)
		log.Panic(err)
	}

	// The config file must have a flat key value structure
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
	c["APP_DIR"] = path.Dir(config)
	// Sort
	sort.Strings(configKeys)

	if len(keys) > 0 {
		// Set config key value

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
			logutil.Debugf("%v", config)
			fmt.Println("Config updated")
			ioutil.WriteFile(config, b, 0)
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
