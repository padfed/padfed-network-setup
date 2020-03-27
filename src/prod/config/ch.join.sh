#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/$ORDERER_TLSCA_CRT_FILENAME"
  if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --keyfile /etc/hyperledger/admin/tls/client.key"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --certfile /etc/hyperledger/admin/tls/client.crt"
  fi
fi

readonly CONTAINER="${NODE_NAME}.cli"

docker exec $CONTAINER \
       peer channel fetch 0 \
       $PEER_CLI_TLS_PARAMETERS \
       -o $ORDERER_NAME:$ORDERER_PORT \
       -c $CHANNEL_NAME \
       $CHANNEL_NAME.block

docker exec $CONTAINER \
       peer channel join \
       $PEER_CLI_TLS_PARAMETERS \
       -b $CHANNEL_NAME.block
