#!/bin/bash
[[ -n $DEBUG ]] && set -x
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

docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

usage() {
   echo "usage: $0 p1 [-c <channel_name>] [-u <output_file_name>]"
   echo "p1: config or number of block"
}

if [[ "$#" == 0 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   usage
   exit 1
fi

readonly BLOCK=${1,,};shift

while getopts "h?c:u:" opt; do
      case "$opt" in
      h|\?) usage
            exit 0
            ;;
      c) CHANNEL_NAME=${OPTARG,,} ;;
      u) OUTPUT=$OPTARG ;;
      esac
done

if ! [[ $BLOCK == *[[:digit:]]* ]] && ! [[ $BLOCK == "config" ]]; then
   echo "ERROR: p1 [$BLOCK] invalid"
   usage
   exit 1
fi

echo "ENVIRONMENT [${ENVIRONMENT:="dev"}]"
echo "CHANNEL_NAME [${CHANNEL_NAME:="padfedchannel"}]"
echo "SYSTEM_CHANNEL_NAME [${SYSTEM_CHANNEL_NAME:="ordererchannel"}]"
echo "TLS_ENABLED [${TLS_ENABLED:="true"}]"
echo "TLS_CLIENT_AUTH_REQUIRED [${TLS_CLIENT_AUTH_REQUIRED:=$TLS_ENABLED}]"
echo "ORDERER_TLSCA_CRT_FILENAME [${ORDERER_TLSCA_CRT_FILENAME:="tlsca.pem"}]"
echo "OUTPUT [${OUTPUT:=${CHANNEL_NAME}.${BLOCK}.block}]"

PEER_CLI_TLS_PARAMETERS=""
if [[ $TLS_ENABLED == "true" ]]; then
   PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/$ORDERER_TLSCA_CRT_FILENAME"
   if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
      PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth"
      PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --keyfile /etc/hyperledger/admin/tls/client.key"
      PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --certfile /etc/hyperledger/admin/tls/client.crt"
  fi
fi
echo "PEER_CLI_TLS_PARAMETERS [$PEER_CLI_TLS_PARAMETERS]"

ORDERER_PARAMETER=""
[[ $CHANNEL_NAME == $SYSTEM_CHANNEL_NAME && -v ORDERER_NAME && ! -z $ORDERER_NAME ]] && ORDERER_PARAMETER="-o ${ORDERER_NAME}:${ORDERER_PORT:-7050}"
echo "ORDERER_PARAMETER [$ORDERER_PARAMETER]"

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

if test -f "$OUTPUT"; then
   echo "removing file [$OUTPUT] ..."
   rm -f "$OUTPUT"
fi

docker exec $CLI peer channel fetch $BLOCK $PEER_CLI_TLS_PARAMETERS $ORDERER_PARAMETER -c $CHANNEL_NAME $(basename $OUTPUT)

docker exec $CLI cat $(basename $OUTPUT) > $OUTPUT

if [[ ! -s $OUTPUT ]]; then
   echo_red "ERROR: block [$BLOCK] unfetched !!!"
   exit 1
fi

echo_success "block [$BLOCK] fetched - file [$OUTPUT] generated"
