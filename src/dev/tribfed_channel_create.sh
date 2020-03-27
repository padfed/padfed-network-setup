#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

BASE=$(dirname $(readlink -f $0))
source $BASE/.env

DIR="$( dirname "${PWD}")"/dev          # BUG: dependiente del PWD / FIX: usar $BASE definido 2 líneas arriba


if [[ "$TLS_ENABLED" == "true" ]]; then
    PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem"

    if [[ "$TLS_CLIENT_AUTH_REQUIRED" == "true" ]]; then
       PEER_CLI_TLS_PARAMETERS="${PEER_CLI_TLS_PARAMETERS} --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
    fi
fi

# el peer0 de AFIP crea el channel
echo "####################################################"
echo "Ejecutando peer0_afip_cli peer channel create ..."
docker exec peer0_afip_cli peer channel create $PEER_CLI_TLS_PARAMETERS -o $ORDERER -c $CHANNEL_NAME -f /etc/hyperledger/configtx/$CHANNEL_NAME.tx

for org in ${ORGS_WITH_PEERS}; do
    for peer in ${PEERS}; do

        cli=${peer}_${org,,}_cli

        # TODO: verificar si el container esta levantado

        echo "####################################################"
        echo "Ejecutando ${cli} peer channel fetch 0 ..."
        docker exec ${cli} peer channel fetch 0 $PEER_CLI_TLS_PARAMETERS -o $ORDERER -c $CHANNEL_NAME zero.block

        echo "####################################################"
        echo "Ejecutando ${cli} peer channel join ..."
        docker exec ${cli} peer channel join $PEER_CLI_TLS_PARAMETERS -b zero.block

        if [[ "$peer" == "peer0" ]]; then

            # los peer0 se configuran como anchor

            echo "####################################################"
            echo "Ejecutando ${cli} peer channel update add anchor ..."
            docker exec ${cli} peer channel update $PEER_CLI_TLS_PARAMETERS -o $ORDERER -c $CHANNEL_NAME -f /etc/hyperledger/configtx/${org}_anchor.tx
        fi
    done
done
