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

check_dir  "$PEER_DIR"
check_file "$PEER_DIR/.env" && source "$PEER_DIR/.env"

if [[ ${OPERATIONS_ENABLE:="false"} != "true" ]]; then
   echo "OPERATIONS_ENABLE: $OPERATIONS_ENABLE"
   echo "test unavailable"
   echo_success
   exit
fi   

case $NODE_BASENAME in
peer* )    readonly NODE_TYPE="peer" ;;
orderer* ) readonly NODE_TYPE="orderer" ;;
esac

readonly ADMIN_TLS_KEY="$PEER_DIR/crypto-config/operations/${NODE_TYPE}-ope-client.key"
readonly ADMIN_TLS_CRT="$PEER_DIR/crypto-config/operations/${NODE_TYPE}-ope-client.crt"
check_file     "$ADMIN_TLS_KEY"
check_x509_crt "$ADMIN_TLS_CRT"

readonly CA_CHAIN_CERT="$PEER_DIR/crypto-config/tls/ca-chain.crt"
is_x509_crt "$CA_CHAIN_CERT" && readonly CACERT="$CA_CHAIN_CERT"

if [[ ! -v CACERT ]]; then
   readonly CACERT="$PEER_DIR/crypto-config/tls/ca.crt"
   check_x509_crt "$CACERT"
fi

readonly HEALTH_ENDPOINT=https://${NODE_NAME}:${OPERATIONS_PORT}/healthz

echo "CACERT [$CACERT]"
echo "ADMIN_TLS_KEY [$ADMIN_TLS_KEY]"
echo "ADMIN_TLS_CRT [$ADMIN_TLS_CRT]"
echo "HEALTH_ENDPOINT [$HEALTH_ENDPOINT]"

readonly CURL_COMMAND="curl --cacert $CACERT --key $ADMIN_TLS_KEY --cert $ADMIN_TLS_CRT --noproxy $NODE_NAME $HEALTH_ENDPOINT" 

# wait for Hyperledger Fabric to start
sleep 1
set -x
while ! ($CURL_COMMAND | grep '"status":"OK"')
do
    echo "..."
    sleep 1
done
set +x

echo_success
