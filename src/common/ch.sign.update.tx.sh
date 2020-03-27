#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

red_echo()   { echo -e "\033[1;31m$@\033[0m"; }

green_echo() { echo -e "\033[1;32m$@\033[0m"; } 

check_param_file() {
[[ -f "$2" ]] || { red_echo "ERROR: p$1: File [$2] not found !!!"; usage; }
}

check_file() {
[[ -f "$1" ]] || { red_echo "ERROR: File [$1] not found !!!"; exit 1; }
}

check_dir() {
[[ -d "$1" ]] || { red_echo "ERROR: Dir [$1] not found !!!"; exit 1; }
}

check_exe() {
which "$1"
[[ "$?" -eq 0 ]] || { red_echo "ERROR: Exe ["$1"] not found !!!"; exit 1; }
}

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

THIS="$0"

if [[ "$#" -ne 7 ]]; then
   red_echo "ERROR: Unexpected number of params"
   red_echo $@
   usage
fi

#-e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
#-e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
#-e CORE_PEER_ADDRESS=peer0.org2.example.com:9051

PEER_CLI="$1" 
check_dir "$2"          && PEER_CLI_SIGNING_PATH="$2" 
MSPID="${3^^}" 
check_dir "$4"          && ADMIN_DIR="$4" 
CORE_PEER_ADDRESS="$5" 
check_param_file 6 "$6" && FILE_TO_SIGN="$6"

OUTPUT_FILENAME="$7"
if [[ -f "$OUTPUT_FILENAME" ]]; then
   red_echo "ERROR: Output file [$OUTPUT_FILENAME] already exists"
   exit 1
fi

BASE=$(dirname $(readlink -f $0))

echo "########################################"
echo "Running: $THIS"
echo "- p1: peer_cli: $PEER_CLI"
echo "- p2: peer_cli_signing_path: $PEER_CLI_SIGNING_PATH" 
echo "- p3: signer_mspid: $MSPID"
echo "- p4: signer_admin_dir: $ADMIN_DIR"
echo "- p5: signer_peer_address: $CORE_PEER_ADDRESS"
echo "- p6: file_to_sing: $FILE_TO_SIGN" 
echo "- p7: output filename $OUTPUT_FILENAME"

docker exec $PEER_CLI rm -f /signing/*

#sudo rm -Rf "$PEER_CLI_SIGNING_PATH/*"

echo "Organizing signer [${MSPID}] crypto material ..."

sudo cp -Rf "$ADMIN_DIR" "$PEER_CLI_SIGNING_PATH"
#docker cp "$ADMIN_DIR"    $PEER_CLI:/signing

#sudo cp -v  "$FILE_TO_SIGN"  "$PEER_CLI_SIGNING_PATH"
docker cp "$FILE_TO_SIGN" $PEER_CLI:/signing

BASENAME_FROM_ADMIN_DIR=$( basename "$ADMIN_DIR" )
BASENAME_FROM_FILE_TO_SIGN=$( basename "$FILE_TO_SIGN" )

check_dir  "$PEER_CLI_SIGNING_PATH"/"$BASENAME_FROM_ADMIN_DIR/msp"
check_dir  "$PEER_CLI_SIGNING_PATH"/"$BASENAME_FROM_ADMIN_DIR/tls"
check_file "$PEER_CLI_SIGNING_PATH"/"$BASENAME_FROM_FILE_TO_SIGN"

echo "Signing file [$BASENAME_FROM_FILE_TO_SIGN] with ${MSPID} crypto material ..."

ls -la "$PEER_CLI_SIGNING_PATH"/"$BASENAME_FROM_FILE_TO_SIGN"

docker exec \
      -e CORE_PEER_LOCALMSPID="$MSPID" \
      -e CORE_PEER_TLS_ROOTCERT_FILE="/signing/$BASENAME_FROM_ADMIN_DIR/tls/ca.crt" \
      -e CORE_PEER_MSPCONFIGPATH="/signing/$BASENAME_FROM_ADMIN_DIR/msp" \
      -e CORE_PEER_ADDRESS="$CORE_PEER_ADDRESS" \
      ${PEER_CLI} \
      peer channel signconfigtx -f "/signing/$BASENAME_FROM_FILE_TO_SIGN" \
      --logging-level info 

ls -la "$PEER_CLI_SIGNING_PATH"/"$BASENAME_FROM_FILE_TO_SIGN"

#sudo cp "$PEER_CLI_SIGNING_PATH"/"$BASENAME_FROM_FILE_TO_SIGN" "$OUTPUT_FILENAME"

docker cp "$PEER_CLI:/signing/$BASENAME_FROM_FILE_TO_SIGN" "$OUTPUT_FILENAME"

check_file "$OUTPUT_FILENAME"

green_echo "[${THIS}] - File [$OUTPUT_FILENAME] successfully signed by $MSPID using $PEER_CLI" 
echo "########################################"
