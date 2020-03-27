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

readonly cs=$(docker container ls -aq)
[[ ! -z "$cs" ]] && docker container stop $cs

pushd "$PEER_DIR"
docker-compose down --remove-orphans
docker-compose up -d
popd

echo_success
