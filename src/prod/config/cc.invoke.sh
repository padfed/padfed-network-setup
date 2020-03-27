#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env

case "$#" in
   0 | 1 ) 
	echo "ERROR: $# unexpected number of params."
	echo "Usage: $0 <invoke or query> functionName [arg1 arg2 ...]"
	exit 1
   ;;
esac
   
readonly OP="$1"
readonly FUNCTION="$2"
ARGS='{"Args":[]}'
ARGS=$(jq <<<$ARGS -c ".function=\"$FUNCTION\"")
shift

for ARG in ${@:2}
do
  ARG=$(jq -c <<<$ARG . || echo $ARG)
  ARGS=$(jq <<<$ARGS -c '.Args+=[$a]' --arg a $ARG)
done

WAIT_FOR_EVENT=""
ORDERER=""
TLS_WITH_ORDERER=""

case $OP in
  query)
    ;;
  invoke)
    WAIT_FOR_EVENT="--waitForEvent"
    ORDERER="-o $ORDERER_NAME:$ORDERER_PORT" 
    if [[ $TLS_ENABLED == "true" ]]; then
       TLS_WITH_ORDERER="--tls --cafile /etc/hyperledger/orderer/tls/$ORDERER_TLSCA_CRT_FILENAME"
       if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
          TLS_WITH_ORDERER="$TLS_WITH_ORDERER --clientauth" 
          TLS_WITH_ORDERER="$TLS_WITH_ORDERER --keyfile /etc/hyperledger/admin/tls/client.key" 
          TLS_WITH_ORDERER="$TLS_WITH_ORDERER --certfile /etc/hyperledger/admin/tls/client.crt"
       fi
    fi    
    ;;
  *)
    echo "Usage: $0 [invoke|query] {json-args}"
    exit 1
esac

readonly CONTAINER="${NODE_NAME}.cli"

docker exec "$CONTAINER" peer chaincode $OP \
         $TLS_WITH_ORDERER \
         $ORDERER \
         -C $CHANNEL_NAME \
         -n $CHAINCODE_NAME \
         $WAIT_FOR_EVENT \
         -c "$ARGS"
