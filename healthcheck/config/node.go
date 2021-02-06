package config

import (
    "encoding/json"
    "io/ioutil"
    "os"
)

// Node maintains the information needed to monitor the health of a node.
type Node struct {
    Prometheus []interface{} `json:"hasPrometheus"`
}

// ParseNodeConfig parses the Node configuration at the given filepath. Returns Node with the information about the
// Prometheus endpoint.
func ParseNodeConfig(configFilePath string) (*Node, error) {
    configFile, err := os.Open(configFilePath)
    configFileData, err := ioutil.ReadAll(configFile)
    if err != nil {
        return nil, err
    }
    var nodeConfig Node
    err = json.Unmarshal(configFileData, &nodeConfig)
    if err != nil {
        return nil, err
    }
    return &nodeConfig, nil
}
