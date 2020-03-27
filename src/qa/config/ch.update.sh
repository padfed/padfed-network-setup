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
  echo "p1: update_tx_signed.pb" 
  exit 1
}

THIS="$0"

if [[ "$#" -ne 1 ]]; then
   red_echo "ERROR: Unexpected number of params"
   usage
fi

check_param_file 1 "$1" && UPDATE_TX_PB="$1"

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.pem"
  if [[ -v TLS_CLIENT_AUTH_REQUIRED ]] && [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
    PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
  fi
fi

CONTAINER="${PEER_NAME}.${BLOCKCHAIN_NETWORK_NAME}.${ENVIRONMENT}.${ORG_NAME}.${ORGS_NETWORK_DOMAIN_NAME}.cli"

MD5=$(md5sum "$UPDATE_TX_PB" | cut -d' ' -f1)

UPDATE_TX_PB_DOCKER_PATH=/etc/hyperledger/configtx/$(basename ${UPDATE_TX_PB}).$MD5.pb

echo "Copying to $UPDATE_TX_PB_DOCKER_PATH ..."

docker cp "$UPDATE_TX_PB" $CONTAINER:$UPDATE_TX_PB_DOCKER_PATH

echo "Executing docker exec $CONTAINER peer channel update ..."

docker exec $CONTAINER \
   peer channel update \
      $PEER_CLI_TLS_PARAMETERS \
      -o ${ORDERER_HOSTNAME}.${ORDERER_DOMAIN_NAME}.${ENVIRONMENT}.${ORDERER_NETWORK_DOMAIN_NAME}:${ORDERER_PORT} \
      -c ${CHANNEL_NAME} \
      -f $UPDATE_TX_PB_DOCKER_PATH

echo "########################################"
green_echo "[${THIS}] - ${CHANNEL} updated with [${UPDATE_TX_PB}]: OK !!!"
echo "########################################"
