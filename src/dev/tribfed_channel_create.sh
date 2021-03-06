#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

BASE="$(dirname "$(readlink -f "$0")")"
source "$BASE/.env"

. "$BASE/../common/lib.sh"

echo_running

readonly DIR="$( dirname "$PWD")/dev"          # BUG: dependiente del PWD / FIX: usar $BASE definido 2 líneas arriba

readonly TLS_PARAMETERS=$( get_tls_parameters )

# el peer0 de AFIP crea el channel
echo_sep "Ejecutando peer0_afip_cli peer channel create ..."
docker exec peer0_afip_cli peer channel create $TLS_PARAMETERS -o "$ORDERER" -c "$CHANNEL_NAME" -f /etc/hyperledger/configtx/chcreate.tx

for org in $ORGS_WITH_PEERS; do
    for peer in $PEERS; do

        cli="${peer}_${org,,}_cli"

        # TODO: verificar si el container esta levantado

        echo_sep "Ejecutando $cli peer channel fetch 0 ..."
        docker exec "$cli" peer channel fetch 0 $TLS_PARAMETERS -o "$ORDERER" -c "$CHANNEL_NAME" zero.block

        echo_sep "Ejecutando $cli peer channel join ..."
        docker exec "$cli" peer channel join $TLS_PARAMETERS -b zero.block

        if [[ $peer == peer0 ]]; then

            # los peer0 se configuran como anchor

            echo_sep "Ejecutando $cli peer channel update add anchor ..."
            docker exec "$cli" peer channel update $TLS_PARAMETERS -o "$ORDERER" -c "$CHANNEL_NAME" -f "/etc/hyperledger/configtx/${org}_anchor.tx"
        fi
    done
done
