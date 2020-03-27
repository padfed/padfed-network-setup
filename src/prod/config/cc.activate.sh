#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env

if [[ $# != 3 ]]; then
   echo "Cantidad de argumentos [$#] inesperada."
   echo "$0 <instantiate|upgrade> <version semantica> <wait|nowait>"
   exit 1
fi

readonly SUBCOMMAND="$1"

case "$SUBCOMMAND" in
instantiate | upgrade ) ;;
* ) echo "Argumento 1 [$SUBCOMMAND] debe ser <instantiate|upgrade>."
    exit 1;
    ;;
esac

VERSION="$2"
if ! (echo "$VERSION" | grep -qE '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9a-z-]+(\.[0-9a-z-]+)*)?(\+[0-9a-z-]+(\.[0-9a-z-]+)*)?$') ; then
  echo "La versión $VERSION no es una versión semántica."
  exit 1
fi

WAIT="$3"
case "$WAIT" in
wait | nowait ) ;;
* ) echo "Argumento 3 [$WAIT] debe ser <wait|nowait>."
    exit 1;
    ;;
esac

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/$ORDERER_TLSCA_CRT_FILENAME"
  if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --keyfile /etc/hyperledger/admin/tls/client.key"
     PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --certfile /etc/hyperledger/admin/tls/client.crt"
  fi
fi

readonly CONTAINER="${NODE_NAME}.cli"

instantiated() {
  docker exec $CONTAINER peer chaincode list $PEER_CLI_TLS_PARAMETERS --instantiated -C $CHANNEL_NAME \
    | sed -E "/Name: $CHAINCODE_NAME,/s/.* Version: ([^,]+),.*/\1/" \
    | grep -q $VERSION
}

if ! instantiated ; then
  docker exec $CONTAINER \
    peer chaincode $SUBCOMMAND $PEER_CLI_TLS_PARAMETERS \
      -C $CHANNEL_NAME \
      -n $CHAINCODE_NAME \
      -v $VERSION \
      -c '{"Args":[]}' \
      -P "$CHAINCODE_ENDORSMENT"
else
   echo "El chaincode $CHAINCODE_NAME $VERSION ya esta instanciado."
fi

if [[ $WAIT == "wait" ]]; then
  while ! instantiated ; do
    echo "Esperando que el chaincode $CHAINCODE_NAME $VERSION quede activado..."
    sleep 1
  done
  echo "Chaincode $CHAINCODE_NAME $VERSION activado!"
fi
