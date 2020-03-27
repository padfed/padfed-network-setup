#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env
IDEMPOTENT=${IDEMPOTENT:-}

red_echo()   { echo -e "\033[1;31m$@\033[0m"; }

green_echo() { echo -e "\033[1;32m$@\033[0m"; } 

check_param_file() {
[[ -f "$2" ]] || { red_echo "ERROR: p$1: File [$2] not found !!!"; usage; }
}

usage() {
  echo "Usage: $0 p1"
  echo "p1: tx_tosign.pb"
  exit 1
}

THIS="$0"

if [[ "$#" -ne 1 ]]; then
   red_echo "ERROR: Unexpected number of params"
   usage
fi

check_param_file 1 "$1" && SIGN_TX_PB="$1"

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/$ORDERER_TLSCA_CRT_FILENAME"
  if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --keyfile /etc/hyperledger/admin/tls/client.key"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --certfile /etc/hyperledger/admin/tls/client.crt"
  fi
fi

readonly CONTAINER="${NODE_NAME}.cli"

readonly SIGN_TX_PB_DOCKER_PATH=/etc/hyperledger/configtx/$(basename $SIGN_TX_PB).pb

echo "Copying to $SIGN_TX_PB ..."

docker cp "$SIGN_TX_PB" $CONTAINER:$SIGN_TX_PB_DOCKER_PATH

echo "Executing docker exec $CONTAINER peer channel update ..."

docker exec $CONTAINER \
   peer channel signconfigtx \
      $PEER_CLI_TLS_PARAMETERS \
      -o $ORDERER_NAME:$ORDERER_PORT \
      -f $SIGN_TX_PB_DOCKER_PATH


docker exec $CONTAINER cat $SIGN_TX_PB_DOCKER_PATH > $(basename $SIGN_TX_PB)_${MSPID}_sgn.pb

echo "########################################"
green_echo "[$THIS] - $(basename $SIGN_TX_PB)_${MSPID}_sgn.pb signed with [${MSPID}]: OK !!!"
echo "########################################"
