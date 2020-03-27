#!/bin/bash
# Setup Peer

set -Eeuo pipefail

# Initialize
BASE="$(dirname $0)"
. "$BASE/lib.sh"

echo_running

# Check args
if [[ "$#" -ne 2 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   echo "Usage: $0 <node_basename> <crt_file>"
   echo "p1: crt"
   exit 1
fi

readonly NODE_BASENAME="$1"
case $NODE_BASENAME in
orderer* ) echo_red "ERROR: p1 [$NODE_BASENAME], command must be execute only on a peer"; exit 1 ;;
esac

readonly TLSCA_CRT="$2"
is_x509_crt "$TLSCA_CRT" || { echo_red "ERROR: p2 [$TLSCA_CRT] must be a crt"; exit 1; }

check_file "setup.conf" && source "setup.conf"

check_env FABRIC_INSTANCE_PATH
check_env MSPID

readonly PEER_DIR="$FABRIC_INSTANCE_PATH/$MSPID-$NODE_BASENAME"

readonly DOCKER_ENV="$PEER_DIR/.env"

if grep -q "ORDERER_TLSCA_CRT_FILENAME=" "$DOCKER_ENV"; then 
   echo_red "ERROR: [$DOCKER_ENV] already has ORDERER_TLSCA_CRT_FILENAME"
   exit 1
fi
if [[ ! -w $DOCKER_ENV ]]; then
   echo_red "ERROR: [$DOCKER_ENV] is not writeable"
   exit 1
fi

readonly PEER_TLS_DIR="$PEER_DIR/crypto-config/orderer/tls"

check_dir "$PEER_TLS_DIR"

readonly ORDERER_TLSCA_CRT_FILENAME=$(basename "$TLSCA_CRT")

cp "$TLSCA_CRT" "$PEER_TLS_DIR/$ORDERER_TLSCA_CRT_FILENAME"

check_x509_crt "$PEER_TLS_DIR/$ORDERER_TLSCA_CRT_FILENAME"

echo "ORDERER_TLSCA_CRT_FILENAME=$ORDERER_TLSCA_CRT_FILENAME" >> "$DOCKER_ENV"

echo_success 
