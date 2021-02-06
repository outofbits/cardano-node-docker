package config

import (
    "encoding/json"
    "io/ioutil"
    "os"
    "time"
)

// Genesis configuration details that are needed by this health check application.
type Genesis struct {
    GenesisBlockCreationTime time.Time `json:"systemStart"`
    SlotsPerEpoch            uint64    `json:"epochLength"`
    SlotDurationInS          uint64    `json:"slotLength"`
}

// ParseGenesis parses the Genesis file at the given filepath. Returns the Genesis, if the parsing was successful.
// Otherwise an error will be returned.
func ParseGenesis(genesisFilePath string) (*Genesis, error) {
    genesisFile, err := os.Open(genesisFilePath)
    if err != nil {
        return nil, err
    }
    genesisData, err := ioutil.ReadAll(genesisFile)
    if err != nil {
        return nil, err
    }
    var genesis Genesis
    err = json.Unmarshal(genesisData, &genesis)
    if err != nil {
        return nil, nil
    }
    return &genesis, nil
}
