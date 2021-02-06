package health

import (
	"bufio"
	"errors"
	"fmt"
	ctime "github.com/godano/cardano-lib/time"
	"io"
	"math/big"
	"net/http"
	"strings"
	"time"
)

// Config contains the required information for performing a health check for a certain cardano-node instance.
type Config struct {
	PrometheusURL         string
	TimeSettings          ctime.TimeSettings
	MaxTimeSinceLastBlock time.Duration
	MinPeerConnections    int
}

func buildMap(r io.Reader) (map[string]string, error) {
	pMap := make(map[string]string)
	scanner := bufio.NewScanner(r)
	for scanner.Scan() {
		line := scanner.Text()
		lineArr := strings.Split(line, " ")
		if len(lineArr) == 2 {
			pMap[lineArr[0]] = lineArr[1]
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, errors.New(fmt.Sprintf("error reading response from Prometheus: '%s'", scanner.Err().Error()))
	}
	return pMap, nil
}

func checkMaxTimeSinceLastBlock(maxTimeSinceLastBlock time.Duration, pMap map[string]string,
	settings ctime.TimeSettings) (*bool, error) {
	epochString, foundEpoch := pMap["cardano_node_metrics_epoch_int"]
	slotString, foundSlot := pMap["cardano_node_metrics_slotInEpoch_int"]
	if !foundEpoch || !foundSlot {
		return nil, errors.New("could not find the correct information (epoch, slot) in the Prometheus endpoint")
	}
	epoch, validEpoch := new(big.Int).SetString(epochString, 10)
	slot, validSlot := new(big.Int).SetString(slotString, 10)
	if !validEpoch || !validSlot {
		return nil, errors.New("epoch and slot in Prometheus endpoint are not valid integers")
	}
	slotDate, err := ctime.FullSlotDateFrom(epoch, slot, settings)
	if err != nil {
		panic(fmt.Sprintf("epoch/slot date does not match blockchain details: %s", err.Error()))
	}
	healthy := time.Now().Sub(slotDate.GetEndDateTime()) <= maxTimeSinceLastBlock
	return &healthy, nil
}

// Check checks whether the node with the given Config is healthy. If the node is healthy, then nil will be returned,
// otherwise an error.
func Check(config Config) (*bool, error) {
	client := http.Client{
		Timeout: 5 * time.Second,
	}
	response, err := client.Get(config.PrometheusURL)
	if err != nil {
		return nil, errors.New(fmt.Sprintf("not able to reach prometheus endpoint at '%s':%s",
			config.PrometheusURL, err.Error()))
	}
	if 200 <= response.StatusCode && response.StatusCode < 300 {
		var pMap, err = buildMap(response.Body)
		if err != nil {
			return nil, err
		}
		return checkMaxTimeSinceLastBlock(config.MaxTimeSinceLastBlock, pMap, config.TimeSettings)
	} else {
		return nil, errors.New(fmt.Sprintf("promet heus endpoint reported status code '%s'", response.Status))
	}
}
