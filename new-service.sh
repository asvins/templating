#!/bin/bash
SERVICE_NAME="$1"
DEST="$2"

CONFIG_GCFG=`cat <<EOF
; Config file
[server]
addr = 127.0.0.1
port = 8080

[service]
env = development
EOF`

SERVER_FILE=`cat <<EOF
package main

import (
	"fmt"
	"net/http"

	"log"

	// "github.com/asvins/common_db/postgres"
	"github.com/asvins/utils/config"
)

var ServerConfig *Config = new(Config)
// var DatabaseConfig *postgres.Config

// function that will run before main
func init() {
	fmt.Println("[INFO] Initializing server")
	err := config.Load("${SERVICE_NAME}_config.gcfg", ServerConfig)
	if err != nil {
		log.Fatal(err)
	}

	// DatabaseConfig = postgres.NewConfig(ServerConfig.Database.User, ServerConfig.Database.DbName, ServerConfig.Database.SSLMode)
	fmt.Println("[INFO] Initialization Done!")
}

func main() {
	fmt.Println("[INFO] Server running on port:", ServerConfig.Server.Port)
	r := DefRoutes()
	http.ListenAndServe(":"+ServerConfig.Server.Port, r)
}
EOF`

ROUTER_FILE=`cat <<EOF
package main

import (
	"strings"
	"net/http"

  "github.com/asvins/router"
	"github.com/unrolled/render"
	"github.com/asvins/common_interceptors/logger"
)

func DiscoveryHandler(w http.ResponseWriter, req *http.Request) {
  prefix := strings.Join([]string{ServerConfig.Server.Addr, ServerConfig.Server.Port}, ":")
  r := render.New()

	//add discovery links here
  discoveryMap := map[string]string {"discovery": prefix+"/api/discovery"}

	r.JSON(w, http.StatusOK, discoveryMap)
}

func DefRoutes() *router.Router {  
  r := router.NewRouter()

	r.AddRoute("/api/discovery", router.GET, DiscoveryHandler)

	// interceptors
	r.AddBaseInterceptor("/", logger.NewLogger())
	return r
}
EOF`

CONFIG_FILE=`cat <<EOF
package main

// Config struct for this service
type Config struct {
	Server struct {
		Addr string
		Port string
	}
	Service struct {
	  Env string
  }
	// Database struct {
	//   User    string
	//   DbName  string
	//   SSLMode string
	// }
}
EOF`

README_FILE=`cat <<EOF
# ${SERVICE_NAME}
A fresh new service for asvins

## Usage
EOF`


mkdir -p "${DEST}/${SERVICE_NAME}"
echo "${ROUTER_FILE}" > "${DEST}/${SERVICE_NAME}/router.go"
echo "${CONFIG_GCFG}" > "${DEST}/${SERVICE_NAME}/${SERVICE_NAME}_config.gcfg"
echo "${CONFIG_FILE}" > "${DEST}/${SERVICE_NAME}/config.go"
echo "${SERVER_FILE}" > "${DEST}/${SERVICE_NAME}/server.go"
echo "${README_FILE}" > "${DEST}/${SERVICE_NAME}/README.md"
