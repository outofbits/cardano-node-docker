package main

import (
	"errors"
	"flag"
	"fmt"
	ctime "github.com/godano/cardano-lib/time"
	"healthcheck/config"
	"healthcheck/health"
	"io"
	"math/big"
	"os"
	"time"
)

func logf(writer io.Writer, msg string) {
	_,_ = fmt.Fprintf(writer, "[%v][HEALTH CHECK] %s\n",
		time.Now().Format("2006-01-02T15:04:05-07:00"), msg)
}

func getTimeSettings() (*ctime.TimeSettings, error) {
	genesisFilePath := os.Getenv("CN_CHECK_GENESIS_FILE")
	if genesisFilePath == "" {
		return nil, errors.New("you have to specify the path to genesis file with the environment variable 'CN_CHECK_GENESIS_FILE'")
	}
	genesis, err := config.ParseGenesis(genesisFilePath)
	if err != nil {
		return nil, errors.New(fmt.Sprintf("the genesis at '%s' cannot be parsed: %s\n",
			genesisFilePath, err.Error()))
	}
	timeSettings := &ctime.TimeSettings{
		GenesisBlockDateTime: genesis.GenesisBlockCreationTime,
		SlotsPerEpoch:        new(big.Int).SetUint64(genesis.SlotsPerEpoch),
		SlotDuration:         time.Duration(genesis.SlotDurationInS) * time.Second,
	}
	return timeSettings, nil
}

func getPrometheusURL() (string, error) {
	configFilePath := os.Getenv("CN_CHECK_CONFIG_FILE")
	if configFilePath == "" {
		return "", errors.New("you have to specify the path to nodeConfig file with the environment variable 'CN_CHECK_CONFIG_FILE'")
	}
	nodeConfig, err := config.ParseNodeConfig(configFilePath)
	if err != nil {
		return "", errors.New(fmt.Sprintf("the node nodeConfig at '%s' cannot be parsed: %s\n", configFilePath,
			err.Error()))
	}
	return fmt.Sprintf("http://%v:%v/metrics", nodeConfig.Prometheus[0], nodeConfig.Prometheus[1]), nil
}

func main() {
	check := os.Getenv("CN_CHECK")
	if check == "" || check == "false" {
		os.Exit(0)
	}
	timeSettings, err := getTimeSettings()
	if err != nil {
		logf(os.Stderr, err.Error())
		os.Exit(1)
	}
	prometheusURL, err := getPrometheusURL()
	if err != nil {
		logf(os.Stderr, err.Error())
		os.Exit(1)
	}
	maxTimeSinceLastBlock := flag.Duration("max-time-since-last-block", 10*time.Minute,
		"threshold for duration between now and the creation date of the most recently received block")
	flag.Parse()
	cfg := health.Config{
		PrometheusURL:         prometheusURL,
		TimeSettings:          *timeSettings,
		MaxTimeSinceLastBlock: *maxTimeSinceLastBlock,
	}
	healthy, err := health.Check(cfg)
	if err == nil {
		if *healthy {
			logf(os.Stdout, "node is healthy")
			os.Exit(0)
		} else {
			logf(os.Stderr, "node isn't healthy")
			os.Exit(1)
		}
	} else {
		logf(os.Stderr, err.Error())
		os.Exit(1)
	}
}
