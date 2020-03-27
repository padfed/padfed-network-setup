#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env
IDEMPOTENT=${IDEMPOTENT:-}

WAIT=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --wait|-w)
      WAIT=1
      shift
      ;;
    -*)
      echo "Argumento inválido: $1"
      exit 1
      ;;
    *)
      VERSION=$1
      shift
      ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  echo "Debe indicar la versión del CC a instanciar."
  exit 1
fi

if ! (echo "$VERSION" | grep -qE '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9a-z-]+(\.[0-9a-z-]+)*)?(\+[0-9a-z-]+(\.[0-9a-z-]+)*)?$') ; then
  echo "La versión $VERSION no es una versión semántica."
  exit 1
fi

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.pem"
  if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
    PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
  fi
fi

CONTAINER="${PEER_NAME}.${BLOCKCHAIN_NETWORK_NAME}.${ENVIRONMENT}.${ORG_NAME}.${ORGS_NETWORK_DOMAIN_NAME}.cli"

instantiated() {
  docker exec $CONTAINER peer chaincode list $PEER_CLI_TLS_PARAMETERS --instantiated -C $CHANNEL_NAME \
    | sed -E "/Name: $CHAINCODE_NAME,/s/.* Version: ([^,]+),.*/\1/" \
    | grep -q $VERSION
}

if test -z "$IDEMPOTENT" || ! instantiated ; then
  docker exec $CONTAINER \
    peer chaincode upgrade $PEER_CLI_TLS_PARAMETERS \
      -C ${CHANNEL_NAME} \
      -n ${CHAINCODE_NAME} \
      -v ${VERSION} \
      -c '{"Args":[""]}' \
      -P "${CHAINCODE_ENDORSMENT}"
fi

if [[ -n $WAIT ]]; then
  while ! instantiated ; do
    echo "Esperando que el chaincode $CHAINCODE_NAME $VERSION esté instanciado..."
    sleep 1
  done
  echo "Chaincode $CHAINCODE_NAME $VERSION instanciado!"
fi
