#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env
IDEMPOTENT=${IDEMPOTENT:-}

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.pem"
  if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
    PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
  fi
fi

CONTAINER="${PEER_NAME}.${BLOCKCHAIN_NETWORK_NAME}.${ENVIRONMENT}.${ORG_NAME}.${ORGS_NETWORK_DOMAIN_NAME}.cli"

docker exec $CONTAINER \
   peer channel update \
      $PEER_CLI_TLS_PARAMETERS \
      -o ${ORDERER_HOSTNAME}.${ORDERER_DOMAIN_NAME}.${ENVIRONMENT}.${ORDERER_NETWORK_DOMAIN_NAME}:${ORDERER_PORT} \
      -c ${CHANNEL_NAME} \
      -f /etc/hyperledger/configtx/${ORG_NAME}_anchors.tx
