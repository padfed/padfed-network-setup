#!/bin/bash

set -Eeuo pipefail
#set -x

# Initialize
readonly BASE="$(dirname $0)"
. "$BASE/lib.sh"

function mk_get() {
   local REQUEST_FILE="$1"
   local CN=$(get_CN_from_CSR "$REQUEST_FILE")
   local REQUEST_FILE_BASENAME=$(basename "$REQUEST_FILE" .request)
   case "$REQUEST_FILE_BASENAME" in
   *-msp-client )
         local SERVICE="msp"
         local CLIENT_OR_SERVER="client"
         ;;
   *-msp-server )
         local SERVICE="msp"
         local CLIENT_OR_SERVER="server"
         ;;
   *-tls-client )
         local SERVICE="tls"
         local CLIENT_OR_SERVER="client"
         ;;
   *-tls-server )
         local SERVICE="tls"
         local CLIENT_OR_SERVER="server"
         ;;
   *-ope-client )
         local SERVICE="ope"
         local CLIENT_OR_SERVER="client"
         ;;
   *-ope-server )
         local SERVICE="ope"
         local CLIENT_OR_SERVER="server"
         ;;
   * ) echo_red "[$THIS] ERROR: p1 [$REQUEST_FILE] unknow request filename pattern"; exit 1 ;;
   esac

   local CRT_FILE="$CRTS_DIR/$REQUEST_FILE_BASENAME.crt"

   "$BASE/ca.process.request.sh" "$SERVICE" "$CLIENT_OR_SERVER" "$CN" "$REQUEST_FILE" "$CRT_FILE"

   check_x509_crt "$CRT_FILE"

   echo "$CN crt OK"
}

# Copy from Dummy CA to Crypto-stage and index file
function copy_cacert() {

    local SRC_CA="${1,,}"
    local DEST="$2"

    local source_file=$( "$BASE/ca.print.material.path.sh" "$SRC_CA" crt )

    check_x509_crt $source_file # If exists must be a x509 crt

    cp -f "$source_file" "$DEST"
}

function copy_cacerts() {

   DEST_CACERTS_PATH="$1"
   mkdir -p "$DEST_CACERTS_PATH"

   copy_cacert msp "$DEST_CACERTS_PATH/$MSP_CA_CRT_FILENAME"
   copy_cacert tls "$DEST_CACERTS_PATH/$TLS_CA_CRT_FILENAME"
   copy_cacert ope "$DEST_CACERTS_PATH/$OPE_CA_CRT_FILENAME"

   if [[ $CA_MODE == INTERMEDIATECAS ]]; then
      copy_cacert root "$DEST_CACERTS_PATH/$ROOTCA_FILENAME"
   fi
}

echo_running

[[ ! -v SETUP_CONF ]] && readonly SETUP_CONF="setup.conf" && check_file "$SETUP_CONF" && source "$SETUP_CONF"

if [[ "$#" -ne 1 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   echo "Usage: $0 <requests root dir>"
   exit 1
fi

readonly REQUESTS_DIR="$1"
check_dir "$REQUESTS_DIR"

readonly CRTS_DIR="$REQUESTS_DIR-crts"
mkdir -p "$CRTS_DIR"

for r in $(find "$REQUESTS_DIR" -name '*.request'); do
    mk_get "$r"
done

copy_cacerts "$CRTS_DIR/cacerts"

echo_success "MSP, TLS y OPE crts from $REQUESTS_DIR"
