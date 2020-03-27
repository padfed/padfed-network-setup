#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

readonly BASE=$(dirname $(readlink -f $0))
[[ ! -v ENVIRONMENT ]] && source $BASE/.env

readonly THIS="$0"

PATH=$(realpath $BASE/../common):$PATH

function check_exe() {
   local command="$(command -v $1)"
   [[ -x $command ]] && { echo "exe checked [$command]"; } || { echo_red "ERROR: Exe ["$1"] not found !!!"; exit 1; } 
}

function docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

function echo_red()   { echo -e "\033[1;31m$@\033[0m"; }

function echo_green() { echo -e "\033[1;32m$@\033[0m"; }

function check_file() {
   [[ -f "$1" ]] || { echo_red "ERROR: File [$1] not found !!!"; exit 1; }
}

function usage() {
   echo "Usage: $0 neworg_name (ex: AGIP)"
   echo "The script will start peers of neworg"
   exit 1
}

function fetch() {
   echo "$CLI peer channel fetch $1 into $2 ..."
   docker exec $CLI peer channel fetch $1 $PEER_CLI_TLS_PARAMETERS -o $ORDERER -c $CHANNEL_NAME "$2"
}

if [[ $# -ne 1 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   usage
fi

check_exe ch.config.tool.sh

readonly NEWORG=${1^^}

readonly DOCKER_FILE="${BASE}"/${NEWORG}.docker-compose.yml && check_file "${DOCKER_FILE}"

if [[ "$TLS_ENABLED" == "true" ]]; then
    PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem"

    if [[ "$TLS_CLIENT_AUTH_REQUIRED" == "true" ]]; then
       PEER_CLI_TLS_PARAMETERS="${PEER_CLI_TLS_PARAMETERS} --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
    fi
fi

docker-compose -f "${DOCKER_FILE}" down
docker-compose -f "${DOCKER_FILE}" up -d

# wait for Hyperledger Fabric to start
echo "Waiting for fabric to complete start up..."
while ! (docker exec peer0_${NEWORG,,}_cli peer node status  | grep "STARTED")
do
    echo "..."
    sleep 1
done

readonly CONFIG_BLOCK_0=${CHANNEL_NAME}_config_block_zero.block
readonly CONFIG_BLOCK=${CHANNEL_NAME}_config_block.block
readonly SET_ANCHOR_PEER_TX=${NEWORG}_set_anchor_peer.tx
readonly CLI_WORKING_DIR="/opt/gopath/src/github.com/hyperledger/fabric/peer"

rm -f $CONFIG_BLOCK_0 $CONFIG_BLOCK $SET_ANCHOR_PEER_TX

for peer in $PEERS; do

    CLI=${peer}_${NEWORG,,}_cli

    # TODO: verificar si el container esta levantado

    echo "####################################################"
    fetch 0 $CONFIG_BLOCK_0

    echo "####################################################"
    echo "$CLI peer channel join ..."
    docker exec $CLI peer channel join $PEER_CLI_TLS_PARAMETERS -b $CONFIG_BLOCK_0

    if [[ $peer == "peer0" ]]; then
       # los peer0 se configuran como anchor

       readonly ANCHOR_PEER_NAME="peer0.${NEWORG,,}.tribfed.gob.ar"

       echo "####################################################"
       fetch config "$CONFIG_BLOCK"

       docker exec $CLI cat $(basename $CONFIG_BLOCK) > $CONFIG_BLOCK

       check_file "$CONFIG_BLOCK"

       ch.config.tool.sh set_anchor \
                         -o "$CONFIG_BLOCK" \
                         -m $NEWORG \
                         -n $ANCHOR_PEER_NAME \
                         -u "$SET_ANCHOR_PEER_TX"

       docker cp "$SET_ANCHOR_PEER_TX" $CLI:"$CLI_WORKING_DIR/$SET_ANCHOR_PEER_TX"

       echo "####################################################"
       echo "Ejecutando $CLI peer channel update add anchor ..."
       docker exec $CLI peer channel update $PEER_CLI_TLS_PARAMETERS -o $ORDERER -c $CHANNEL_NAME \
                     -f "$CLI_WORKING_DIR/$SET_ANCHOR_PEER_TX"
       
       echo_green "[$THIS] - Peer [$ANCHOR_PEER_NAME] configured as anchor peer of [$NEWORG] !!!"
    fi
done

echo "########################################"
echo_green "[$THIS] - Peers of new org $NEWORG joined to $CHANNEL_NAME: OK !!!"
echo "########################################"
