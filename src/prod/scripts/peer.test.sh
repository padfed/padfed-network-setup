#!/bin/bash
# peer.run.sh

set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname $0)"
. "$BASE/lib.sh"

echo_running

readonly nbn="$1"

check_file "setup.conf" && source "setup.conf"

readonly PEER_DIR="$FABRIC_INSTANCE_PATH/$MSPID-$nbn"

check_file "$PEER_DIR/docker-compose.yaml"

check_file "$PEER_DIR/.env" && source "$PEER_DIR/.env"

# wait for Hyperledger Fabric to start
# check connection from cli to peer
sleep 1
while ! (docker exec $NODE_NAME.cli peer node status | grep "STARTED")
do
    echo "..."
    sleep 1
done

docker exec $NODE_NAME.cli peer channel list

echo_success
