#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

readonly BASE="$(dirname "$(readlink -f "$0")")"
[[ ! -v ENVIRONMENT ]] && source "$BASE/.env"

. "$BASE/../common/lib.sh"

echo_running

PATH="$(realpath "$BASE/../common"):$PATH"

function usage() {
   echo "Usage: $0 org"
   echo "The script starts peers of org"
   exit 1
}

function fetch() {
   docker exec "$CLI" peer channel fetch "$1" $TLS_PARAMETERS -o "$ORDERER" -c "$CHANNEL_NAME" "$2"
   docker exec "$CLI" ls -la "$2"
}

if [[ $# -ne 1 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   usage
fi

check_exe ch.config.tool.sh

NEWORG="${1^^}"

readonly DOCKER_FILE="$BASE/${NEWORG}.docker-compose.yml" && check_file "$DOCKER_FILE"

SERVICES=""
for peer in $PEERS; do
    SERVICES="$SERVICES ${peer}.${NEWORG,,}.$NETWORK_DOMAIN"
    LAST_CLI="${peer}_${NEWORG,,}_cli"
    SERVICES="$SERVICES $LAST_CLI"
done

docker-compose -f "$DOCKER_FILE" down

echo "SERVICES [$SERVICES]"
docker-compose -f "$DOCKER_FILE" up -d $SERVICES

# wait for Hyperledger Fabric to start
echo "Waiting for fabric to complete start up..."
while ! (docker exec "$LAST_CLI" peer node status  | grep "STARTED")
do
    echo "..."
    sleep 1
done

readonly TLS_PARAMETERS=$( get_tls_parameters )

readonly TMP_PATH="${BASE}/tmp/$$.${NEWORG}.start"
sudo rm -Rf "$TMP_PATH"
mkdir -p "$TMP_PATH"

readonly ZERO_BLOCK="$$.${CHANNEL_NAME}_zero.block"

readonly CONFIG_BLOCK_BASENAME="$$.${CHANNEL_NAME}_config.block"
readonly CONFIG_BLOCK="$TMP_PATH/$CONFIG_BLOCK_BASENAME"

readonly SET_ANCHOR_PEER_TX_BASENAME="${NEWORG}_set_anchor_peer.tx"
readonly SET_ANCHOR_PEER_TX="$TMP_PATH/$SET_ANCHOR_PEER_TX_BASENAME"

readonly CLI_WORKING_DIR="/opt/gopath/src/github.com/hyperledger/fabric/peer"

rm -f "$ZERO_BLOCK" "$CONFIG_BLOCK" "$SET_ANCHOR_PEER_TX"

for peer in $PEERS; do

    CLI="${peer}_${NEWORG,,}_cli"

    # TODO: verificar si el container esta levantado

    fetch 0 "$ZERO_BLOCK"

    echo_sep "$CLI peer channel join ..."
    docker exec "$CLI" peer channel join $TLS_PARAMETERS -b "$ZERO_BLOCK"

    if [[ $peer == peer0 ]]; then
       # los peer0 se configuran como anchor

       readonly ANCHOR_PEER_NAME="peer0.${NEWORG,,}.$NETWORK_DOMAIN"

       fetch config "$CONFIG_BLOCK_BASENAME"

       # Use command to avoid the DOCKERDEBUG echo alter the cat output
       command docker exec "$CLI" cat "$CONFIG_BLOCK_BASENAME" > "$CONFIG_BLOCK"

       check_file "$CONFIG_BLOCK"

       ch.config.tool.sh set_anchor \
                         -o "$CONFIG_BLOCK" \
                         -m "$NEWORG" \
                         -n "$ANCHOR_PEER_NAME" \
                         -u "$SET_ANCHOR_PEER_TX"

       docker cp "$SET_ANCHOR_PEER_TX" "$CLI:$CLI_WORKING_DIR/$SET_ANCHOR_PEER_TX_BASENAME"

       echo_sep "Ejecutando $CLI peer channel update add anchor ..."
       docker exec "$CLI" peer channel update $TLS_PARAMETERS -o "$ORDERER" -c "$CHANNEL_NAME" \
                     -f "$CLI_WORKING_DIR/$SET_ANCHOR_PEER_TX_BASENAME"

       echo_green "$ANCHOR_PEER_NAME configured as anchor peer"
    fi
done

echo_success "$PEERS of $NEWORG joined to $CHANNEL_NAME"
