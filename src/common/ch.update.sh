#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

readonly BASE=$(dirname $(readlink -f $0))

. "$BASE/lib.sh"

echo_running

if [[ -r $PWD/.env ]]; then
   echo "Setting from PWD/.env ... "
   source $PWD/.env
elif [[ -r $BASE/.env ]]; then
   echo "Setting from BASE/.env ... "
   source $BASE/.env
else
   echo "WARN: Running without .env ... "
fi

usage() {
   echo "usage: $0 [-c <channel_name>] [-t <update tx protobuf>]"
}

UPDATE_TX_PB="none"

case "$#" in
0 ) echo_red "ERROR: $# unexpected number of params"
    usage
    exit 1
    ;;
1 ) UPDATE_TX_PB="$1"
    ;;
* ) while getopts "h?c:t:" opt; do
          case "$opt" in
          h|\?) usage
                exit 0
                ;;
          c) CHANNEL_NAME=${OPTARG,,} ;;
          t) UPDATE_TX_PB=$OPTARG ;;
          esac
    done
    ;;
esac

if [[ $UPDATE_TX_PB == "none" ]]; then
   echo_red "ERROR: -t <update tx protobuf> is mandatory"
   exit 1
fi
if [[ ! -s $UPDATE_TX_PB ]]; then
   echo_red "ERROR: -t [$UPDATE_TX_PB] does not exist or is empty"
   exit 1
fi

echo "ENVIRONMENT [${ENVIRONMENT:="dev"}]"
echo "CHANNEL_NAME [${CHANNEL_NAME:="padfedchannel"}]"
echo "TLS_ENABLED [${TLS_ENABLED:="true"}]"
echo "TLS_CLIENT_AUTH_REQUIRED [${TLS_CLIENT_AUTH_REQUIRED:=$TLS_ENABLED}]"
echo "ORDERER_NAME [${ORDERER_NAME:="none"}]"
echo "ORDERER_PORT [${ORDERER_PORT:=7050}]"
echo "ORDERER_TLSCA_CRT_FILENAME [${ORDERER_TLSCA_CRT_FILENAME:="tlsca.pem"}]"

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/$ORDERER_TLSCA_CRT_FILENAME"
  if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --keyfile /etc/hyperledger/admin/tls/client.key"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --certfile /etc/hyperledger/admin/tls/client.crt"
  fi
fi

case $ENVIRONMENT in
dev )  readonly CLI="peer0_afip_cli" ;;
prod | homo ) 
       readonly CLI="${NODE_NAME}.cli" ;;
testnet ) 
       readonly CLI="${PEER_NAME}.${BLOCKCHAIN_NETWORK_NAME}.${ENVIRONMENT}.${ORG_NAME}.${ORGS_NETWORK_DOMAIN_NAME}.cli" ;;
* ) echo_red "ERROR: unknow [$ENVIRONMENT] - expetected [dev | prod | homo | testnet]"
    exit 1
esac
echo "CLI [$CLI]"

readonly CLI_IS_RUNNING=$( docker ps -q --filter name="$CLI" --filter status=running )

if [[ -z "$CLI_IS_RUNNING" ]]; then
   echo "ERROR: container [$CLI] is not running"
   exit 1
fi

readonly MD5=$(md5sum "$UPDATE_TX_PB" | cut -d' ' -f1)

readonly UPDATE_TX_PB_DOCKER_PATH=/etc/hyperledger/configtx/$(basename $UPDATE_TX_PB).$MD5.pb

echo "Copying to $UPDATE_TX_PB_DOCKER_PATH ..."

docker cp "$UPDATE_TX_PB" $CLI:$UPDATE_TX_PB_DOCKER_PATH

echo "Executing docker exec $CLI peer channel update ..."

docker exec $CLI \
   peer channel update \
      $PEER_CLI_TLS_PARAMETERS \
      -o $ORDERER_NAME:$ORDERER_PORT \
      -c $CHANNEL_NAME \
      -f "$UPDATE_TX_PB_DOCKER_PATH"

echo_success "channel [$CHANNEL_NAME] updated"
