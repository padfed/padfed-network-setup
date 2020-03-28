#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

readonly BASE=$(dirname "$(readlink -f "$0")")

. "$BASE/lib.sh"

echo_running

usage() {
  echo "Usage: $0 p1 p2 p3 p4 p5 p6 p7 p8"
  echo "p1: peer_cli (ex: peer0_afip_cli)"
  echo "p2: peer_cli_signing_path (ex: /home/appserv/develop/padfed-network-setup/src/dev/fabric-instance/peer0_afip_cli/signing)"
  echo "p3: signer_mspid (ex: ARBA)"
  echo "p4: signer_admin_msp_path (path) ==> -e CORE_PEER_MSPCONFIGPATH"
  echo "p5: signer_peer_address (url:port) ==> -e CORE_PEER_ADDRESS"
  echo "p6: file_to_sing (filename)"
  echo "p7: output_filename"
  exit 1
}

if [[ $# -ne 7 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   usage
fi

readonly PEER_CLI="$1"
check_dir "$2"          && readonly PEER_CLI_SIGNING_PATH="$2"
readonly MSPID="${3^^}"
check_dir "$4"          && readonly ADMIN_DIR="$4"
readonly CORE_PEER_ADDRESS="$5"
check_param_file 6 "$6" && readonly FILE_TO_SIGN="$6"

readonly OUTPUT_FILENAME="$7"
if [[ -f "$OUTPUT_FILENAME" ]]; then
   echo_red "ERROR: Output file [$OUTPUT_FILENAME] already exists"
   exit 1
fi

echo "- p1: peer_cli: $PEER_CLI"
echo "- p2: peer_cli_signing_path: $PEER_CLI_SIGNING_PATH"
echo "- p3: signer_mspid: $MSPID"
echo "- p4: signer_admin_dir: $ADMIN_DIR"
echo "- p5: signer_peer_address: $CORE_PEER_ADDRESS"
echo "- p6: file_to_sing: $FILE_TO_SIGN"
echo "- p7: output filename $OUTPUT_FILENAME"

docker exec "$PEER_CLI" rm -f /signing/*

echo "Organizing signer [$MSPID] crypto material ..."

sudo cp -Rf "$ADMIN_DIR" "$PEER_CLI_SIGNING_PATH"
#docker cp  "$ADMIN_DIR"  $PEER_CLI:/signing

docker cp "$FILE_TO_SIGN" "$PEER_CLI:/signing"

readonly BASENAME_FROM_ADMIN_DIR=$( basename "$ADMIN_DIR" )
readonly BASENAME_FROM_FILE_TO_SIGN=$( basename "$FILE_TO_SIGN" )

check_dir  "$PEER_CLI_SIGNING_PATH/$BASENAME_FROM_ADMIN_DIR/msp"
check_dir  "$PEER_CLI_SIGNING_PATH/$BASENAME_FROM_ADMIN_DIR/tls"
check_file "$PEER_CLI_SIGNING_PATH/$BASENAME_FROM_FILE_TO_SIGN"

echo "Signing file [$BASENAME_FROM_FILE_TO_SIGN] with $MSPID crypto material ..."

ls -la "$PEER_CLI_SIGNING_PATH/$BASENAME_FROM_FILE_TO_SIGN"

docker exec \
      -e CORE_PEER_LOCALMSPID="$MSPID" \
      -e CORE_PEER_TLS_ROOTCERT_FILE="/signing/$BASENAME_FROM_ADMIN_DIR/tls/ca.crt" \
      -e CORE_PEER_MSPCONFIGPATH="/signing/$BASENAME_FROM_ADMIN_DIR/msp" \
      -e CORE_PEER_ADDRESS="$CORE_PEER_ADDRESS" \
      "$PEER_CLI" \
      peer channel signconfigtx -f "/signing/$BASENAME_FROM_FILE_TO_SIGN" \
      --logging-level info

ls -la "$PEER_CLI_SIGNING_PATH/$BASENAME_FROM_FILE_TO_SIGN"

docker cp "$PEER_CLI:/signing/$BASENAME_FROM_FILE_TO_SIGN" "$OUTPUT_FILENAME"

check_file "$OUTPUT_FILENAME"

echo_success "[$OUTPUT_FILENAME] successfully signed by $MSPID using $PEER_CLI"
