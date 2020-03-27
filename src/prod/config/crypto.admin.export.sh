#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env
IDEMPOTENT=${IDEMPOTENT:-}

readonly PEER_DIR="$FABRIC_INSTANCE_PATH/$MSPID-$NODE_BASENAME"

readonly ADMIN_DIR="$PEER_DIR/crypto-config/admin"

[[ ! -d "$ADMIN_DIR/msp/signcerts" ]] && { echo "ERROR: [$ADMIN_DIR/msp/signcerts] is not dir"; exit 1; }
[[ ! -d "$ADMIN_DIR/msp/keystore"  ]] && { echo "ERROR: [$ADMIN_DIR/msp/keystore] is not dir"; exit 1; }
[[ ! -d "$ADMIN_DIR/tls"           ]] && { echo "ERROR: [$ADMIN_DIR/msp/tls] is not dir"; exit 1; }

echo "Searching crypto material in $ADMIN_DIR/{msp/{keystore,singcerts},tls} ..."

for f in $(find "$ADMIN_DIR/msp/signcerts" -name '*.crt'); do
    readonly ADMIN_MSP_CRT="$f"
    break
done
for f in $(find "$ADMIN_DIR/msp/keystore" -name '*.key'); do
    readonly ADMIN_MSP_KEY="$f"
    break
done

[[ -v ADMIN_MSP_CRT ]] || { echo "ERROR: ADMIN_MSP_CRT not found"; exit 1; }
[[ -v ADMIN_MSP_KEY ]] || { echo "ERROR: ADMIN_MSP_KEY not found"; exit 1; }

readonly ADMIN_TLS_CRT="$ADMIN_DIR/tls/client.crt"
readonly ADMIN_TLS_KEY="$ADMIN_DIR/tls/client.key"

[[ -r "$ADMIN_TLS_CRT" ]] || { echo "ERROR: ADMIN_TLS_CRT not found"; exit 1; }
[[ -r "$ADMIN_TLS_KEY" ]] || { echo "ERROR: ADMIN_TLS_KEY not found"; exit 1; }

readonly CRYPTO_ADMIN="$PEER_DIR/$MSPID-$NODE_BASENAME-crypto-admin"
rm -rf   "$CRYPTO_ADMIN"
mkdir -p "$CRYPTO_ADMIN"

cp "$ADMIN_MSP_CRT" "$CRYPTO_ADMIN/admin1@${DOMAIN}-msp-client.crt"
cp "$ADMIN_MSP_KEY" "$CRYPTO_ADMIN/admin1@${DOMAIN}-msp-client.key"
cp "$ADMIN_TLS_CRT" "$CRYPTO_ADMIN/admin1@${DOMAIN}-tls-client.crt"
cp "$ADMIN_TLS_KEY" "$CRYPTO_ADMIN/admin1@${DOMAIN}-tls-client.key"
