#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

./cli_fabric_setup.sh tribfed_crypto-config.yaml tribfed_configtx.yaml
