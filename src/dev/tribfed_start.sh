#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

BASE=$(dirname $(readlink -f $0))
source $BASE/.env

DIR="$( dirname "${PWD}")"/dev          # BUG: dependiente del PWD / FIX: usar $BASE definido 2 líneas arriba
DOCKER_FILE="${DIR}"/docker-compose.yml

if [[ "$TLS_ENABLED" == "true" ]]; then
    PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem"

    if [[ "$TLS_CLIENT_AUTH_REQUIRED" == "true" ]]; then
       PEER_CLI_TLS_PARAMETERS="${PEER_CLI_TLS_PARAMETERS} --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
    fi
fi

docker-compose -f "${DOCKER_FILE}" down
docker-compose -f "${DOCKER_FILE}" up -d

# wait for Hyperledger Fabric to start
echo "Waiting for fabric to complete start up..."
while ! (docker exec peer0_afip_cli peer node status  | grep "STARTED")
do
    echo "..."
    sleep 1
done

./tribfed_channel_create.sh