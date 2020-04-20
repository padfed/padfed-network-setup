#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail
readonly BASE=$(dirname "$(readlink -f "$0")")
source "$BASE/.env"

case "$#" in
   0 | 1 )
	echo "ERROR: $# unexpected number of params."
	echo "Usage: $0 <invoke or query> functionName [arg1 arg2 ...]"
	exit 1
esac

readonly OP="$1"
shift

case "$OP" in
query)  readonly WAIT_FOR_EVENT=""
        readonly LOGGING_LEVEL="INFO"
        ;;
invoke) readonly WAIT_FOR_EVENT="--waitForEvent"
        readonly LOGGING_LEVEL="DEBUG"
        ;;
*) echo_red "ERROR: Usage: $0 <invoke|query> <json-args>"
   exit 1
esac

ARGS="{\"function\":\"$1\",\"args\":[]}"
shift

for ARG in "$@"
do
  ARG=$(jq -c <<<$ARG . || echo "$ARG")
  ARGS=$(jq <<<$ARGS -c '.args+=[$a]' --arg a "$ARG")
done

ORDERER_PARAMS=""
TLS_WITH_ORDERER=""

if [[ $OP == invoke ]]; then
    ORDERER_PARAMS="-o $ORDERER_NAME:$ORDERER_PORT"
    if [[ $TLS_ENABLED == true ]]; then
       TLS_WITH_ORDERER="--tls --cafile /etc/hyperledger/orderer/tls/$ORDERER_TLSCA_CRT_FILENAME"
       if [[ $TLS_CLIENT_AUTH_REQUIRED == true ]]; then
          TLS_WITH_ORDERER="$TLS_WITH_ORDERER --clientauth"
          TLS_WITH_ORDERER="$TLS_WITH_ORDERER --keyfile /etc/hyperledger/admin/tls/client.key"
          TLS_WITH_ORDERER="$TLS_WITH_ORDERER --certfile /etc/hyperledger/admin/tls/client.crt"
       fi
    fi
fi

readonly CONTAINER="${NODE_NAME}.cli"

docker exec "$CONTAINER" peer chaincode "$OP" \
         $TLS_WITH_ORDERER \
         $ORDERER_PARAMS \
         --logging-level "$LOGGING_LEVEL" \
         -C "$CHANNEL_NAME" \
         -n "$CHAINCODE_NAME" \
         "$WAIT_FOR_EVENT" \
         -c "$ARGS"
