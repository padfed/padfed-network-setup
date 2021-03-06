#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

readonly BASE=$(dirname "$(readlink -f "$0")")

. "$BASE/lib.sh"

echo_running

if [[ -r $PWD/.env ]]; then
   echo "Setting from $PWD/.env ... "
   source "$PWD/.env"
elif [[ -r $BASE/.env ]]; then
   echo "Setting from $BASE/.env ... "
   source "$BASE/.env"
else
   echo "WARN: Running without .env ... "
fi

usage() {
   echo "usage: $0 p1 [-c <channel_name>] [-u <output_file_name>]"
   echo "p1: config or number of block"
}

if [[ $# == 0 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   usage
   exit 1
fi

readonly BLOCK=${1,,};shift

while getopts "h?c:u:" opt; do
      case "$opt" in
      h|\?) usage
            exit 0
            ;;
      c) CHANNEL_NAME=${OPTARG,,} ;;
      u) OUTPUT=$OPTARG ;;
      esac
done

if ! [[ $BLOCK == *[[:digit:]]* ]] && ! [[ $BLOCK == config ]]; then
   echo "ERROR: p1 [$BLOCK] invalid"
   usage
   exit 1
fi

echo "ENVIRONMENT [${ENVIRONMENT:="dev"}]"
echo "CHANNEL_NAME [${CHANNEL_NAME:="padfedchannel"}]"
echo "SYSTEM_CHANNEL_NAME [${SYSTEM_CHANNEL_NAME:="ordererchannel"}]"
echo "TLS_ENABLED [${TLS_ENABLED:="true"}]"
echo "TLS_CLIENT_AUTH_REQUIRED [${TLS_CLIENT_AUTH_REQUIRED:=$TLS_ENABLED}]"
echo "ORDERER_TLSCA_CRT_FILENAME [${ORDERER_TLSCA_CRT_FILENAME:="tlsca.pem"}]"
echo "OUTPUT [${OUTPUT:=${CHANNEL_NAME}.${BLOCK}.protobuf}]"

readonly TLS_PARAMETERS=$( get_tls_parameters )

ORDERER_PARAMETER=""
[[ -v ORDERER_NAME && ! -z $ORDERER_NAME ]] && readonly ORDERER_PARAMETER="${ORDERER_NAME}:${ORDERER_PORT:-7050}"
echo "ORDERER_PARAMETER [$ORDERER_PARAMETER]"

readonly RUNNING_CLIS=$(docker ps --format \{\{.Names\}\} --filter status=running | grep -E '^peer0.+(\.|_)cli$')

CLI=""
for CLI in $RUNNING_CLIS; do
   [[ $CLI =~ ^.+afip.+$ ]] && break
done

if [[ -z $CLI ]]; then
   echo "ERROR: no cli container running"
   exit 1
fi

echo "CLI [$CLI]"

if test -f "$OUTPUT"; then
   echo "removing file [$OUTPUT] ..."
   rm -f "$OUTPUT"
fi

readonly OUTPUT_BASENAME="$(basename "$OUTPUT")"

docker exec "$CLI" peer channel fetch "$BLOCK" $TLS_PARAMETERS -o "$ORDERER_PARAMETER" -c "$CHANNEL_NAME" "$OUTPUT_BASENAME"

docker exec "$CLI" ls -la "$OUTPUT_BASENAME"

# Use command to avoid the DOCKERDEBUG echo alter the cat output
command docker exec "$CLI" cat "$OUTPUT_BASENAME" > "$OUTPUT"

ls -la "$OUTPUT"

if [[ ! -s $OUTPUT ]]; then
   echo_red "ERROR: block [$BLOCK] unfetched !!!"
   exit 1
fi

echo_success "block [$BLOCK] fetched - file [$OUTPUT] generated"
