#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env
IDEMPOTENT=${IDEMPOTENT:-}

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/$ORDERER_TLSCA_CRT_FILENAME"
  if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --keyfile /etc/hyperledger/admin/tls/client.key"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --certfile /etc/hyperledger/admin/tls/client.crt"
  fi
fi

readonly CONTAINER="${NODE_NAME}.cli"

if test -z "$IDEMPOTENT" || ! docker exec $CONTAINER peer channel fetch 0 $PEER_CLI_TLS_PARAMETERS -c $CHANNEL_NAME $CHANNEL_NAME.block; then
  docker exec $CONTAINER \
    peer channel create \
      $PEER_CLI_TLS_PARAMETERS \
      -o $ORDERER_NAME:$ORDERER_PORT \
      -c $CHANNEL_NAME \
      -f /etc/hyperledger/configtx/createchannel.tx
fi

if test -z "$IDEMPOTENT" || ! (docker exec $CONTAINER peer channel list $PEER_CLI_TLS_PARAMETERS | grep -q $CHANNEL_NAME); then
  docker exec $CONTAINER \
    peer channel join \
      $PEER_CLI_TLS_PARAMETERS \
      -b $CHANNEL_NAME.block
fi
