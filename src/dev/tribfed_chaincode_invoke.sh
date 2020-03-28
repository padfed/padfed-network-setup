#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

readonly SUBCOMMAND="$1"
readonly ARGS="$2"

readonly BASE=$(dirname "$(readlink -f "$0")")
[[ ! -v ENVIRONMENT ]] && source "$BASE/.env"

docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

case "$SUBCOMMAND" in
query)  readonly WAIT_FOR_EVENT="" ;;
invoke) readonly WAIT_FOR_EVENT="--waitForEvent" ;;
*) echo "Usage: $0 [invoke|query] {json-args}"
   exit 1
esac

readonly ZERO_PEERS=$(docker ps --format \{\{.Names\}\} --filter expose="$PEER_PORT" | grep peer0)

if [[ -z $ZERO_PEERS ]]; then
  echo "no peer0 was found"
  exit 1
fi

echo "ZERO PEERS [$ZERO_PEERS]"

TLS_WITH_PEERS=""
ORDERER_PARAMS=""

if [[ $SUBCOMMAND == invoke ]]; then

  for peer in $ZERO_PEERS; do
    org_domain="${peer/#peer0.}" # remove "peer0." from $peer if "peer0." is found at the begining
    echo "Adding peerAddress for $peer of $org_domain ..."
    TLS_WITH_PEERS="$TLS_WITH_PEERS --peerAddresses $peer:$PEER_PORT"
    TLS_WITH_PEERS="$TLS_WITH_PEERS --tlsRootCertFiles /etc/hyperledger/tls_root_cas/tlsca.$org_domain-cert.pem"
  done

  ORDERER_PARAMS="-o $ORDERER"
  if [[ $TLS_ENABLED == true ]]; then
    ORDERER_PARAMS="$ORDERER_PARAMS --tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.$NETWORK_DOMAIN-cert.pem"
    if [[ $TLS_CLIENT_AUTH_REQUIRED == true ]]; then
      ORDERER_PARAMS="$ORDERER_PARAMS --clientauth"
      ORDERER_PARAMS="$ORDERER_PARAMS --keyfile /etc/hyperledger/tls/client.key"
      ORDERER_PARAMS="$ORDERER_PARAMS --certfile /etc/hyperledger/tls/client.crt"
    fi
  fi
fi

docker exec peer0_afip_cli peer chaincode "$SUBCOMMAND" \
         $ORDERER_PARAMS \
         $TLS_WITH_PEERS \
         -C "$CHANNEL_NAME" \
         -n "$CHAINCODE_NAME" \
         "$WAIT_FOR_EVENT" \
         --logging-level info \
         -c "$ARGS"
