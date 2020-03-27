#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

SUBCOMMAND="$1"
ARGS="$2"

BASE=$(dirname $(readlink -f $0))
[[ ! -v ENVIRONMENT ]] && source $BASE/.env

DIR="$( dirname "${PWD}")"/dev          # BUG: dependiente del PWD / FIX: usar $BASE definido 3 líneas arriba

docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

PEER_CLI_TLS_WITH_ORG=""

if [[ "$TLS_ENABLED" == "true" ]]; then

  PEER_CLI_TLS_WITH_ORDERER="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem"

  ORGS=AFIP
  [[ $SUBCOMMAND == invoke ]] && ORGS=$ORGS_WITH_PEERS
  for ORG in $ORGS; do
      echo "Adding peerAddress of peer0 $ORG ..."
      PEER_CLI_TLS_WITH_ORG="$PEER_CLI_TLS_WITH_ORG --peerAddresses peer0.${ORG,,}.tribfed.gob.ar:7051 --tlsRootCertFiles /etc/hyperledger/tls_root_cas/tlsca.${ORG,,}.tribfed.gob.ar-cert.pem"
  done

  if [[ "$TLS_CLIENT_AUTH_REQUIRED" == "true" ]]; then
       PEER_CLI_TLS_WITH_ORDERER="$PEER_CLI_TLS_WITH_ORDERER --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
  fi

fi

case $SUBCOMMAND in
  query)
    WAIT_FOR_EVENT=""
    ;;
  invoke)
    WAIT_FOR_EVENT="--waitForEvent"
    ;;
  *)
    echo "Usage: $0 [invoke|query] {json-args}"
    exit 1
esac

docker exec peer0_afip_cli peer chaincode $SUBCOMMAND \
         -o $ORDERER \
         $PEER_CLI_TLS_WITH_ORDERER \
         $PEER_CLI_TLS_WITH_ORG \
         -C $CHANNEL_NAME \
         -n $CHAINCODE_NAME \
         $WAIT_FOR_EVENT \
         --logging-level info \
         -c "$ARGS"
