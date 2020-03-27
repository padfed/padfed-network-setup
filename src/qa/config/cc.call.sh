#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env

OP=$1
shift

ARGS='{"Args":[]}'
ARGS=$(jq <<<$ARGS -c ".function=\"$1\"")
shift

for ARG in "$@"
do
  ARG=$(jq -c <<<$ARG . || echo $ARG)
  ARGS=$(jq <<<$ARGS -c '.Args+=[$a]' --arg a $ARG)
done

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.pem"
  if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
    PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
  fi
fi

OP=${OP/invoke/invoke --waitForEvent}

CONTAINER="${PEER_NAME}.${BLOCKCHAIN_NETWORK_NAME}.${ENVIRONMENT}.${ORG_NAME}.${ORGS_NETWORK_DOMAIN_NAME}.cli"

docker exec $CONTAINER \
  peer chaincode $OP \
    $PEER_CLI_TLS_PARAMETERS \
    -o $ORDERER_HOSTNAME.$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME:$ORDERER_PORT \
    -C $CHANNEL_NAME \
    -n $CHAINCODE_NAME \
    -c "$ARGS"
