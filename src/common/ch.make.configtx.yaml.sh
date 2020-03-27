#!/bin/bash
# create configtx.yaml 

set -Eeuo pipefail

BASE="$(dirname $0)"
. "$BASE/lib.sh"

echo_running

# Check args
if [[ "$#" -ne 5 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   echo "Usage: $0 p1 p2 p3 p4"
   echo "p1: mspid, ej ARBA"
   echo "p2: configtx_msp_dir de la org"
   echo "p3: anchor_peer_name"
   echo "p4: anchor_peer_port"
   echo "p5: output_filename (configtx.yaml)" 
   exit 1
fi

readonly MSPID="$1"
readonly CONFIGTX_MSP_DIR="$2" && check_dir "$CONFIGTX_MSP_DIR"
readonly ANCHOR_PEER_NAME="$3" && 
readonly ANCHOR_PEER_PORT="$4"
readonly FILENAME="$5"

readonly READERS_RULE="\"ANY Readers\""
readonly WRITERS_RULE="\"OR('${MSPID}.member')\""
readonly ADMINS_RULE="\"OR('${MSPID}.admin')\""

cat <<< "Organizations:
    - &${MSPID}
        Name: ${MSPID}
        ID: ${MSPID}
        MSPDir: ${CONFIGTX_MSP_DIR}
        Policies:
            Readers:
                Type: ImplicitMeta
                Rule: ${READERS_RULE}
            Writers:
                Type: Signature
                Rule: ${WRITERS_RULE}
            Admins:
                Type: Signature
                Rule: ${ADMINS_RULE}
        AnchorPeers:
            - Host: ${ANCHOR_PEER_NAME}
              Port: ${ANCHOR_PEER_PORT}
" > "$FILENAME"

[[ ! -r $FILENAME ]] && { echo "ERROR: configtx.yaml [$FILENAME] could not be generated !!!"; exit 1; }

echo_success "configtx.yaml [$FILENAME] generated"
