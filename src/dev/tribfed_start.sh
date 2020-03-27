#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

readonly BASE="$(dirname "$(readlink -f "$0")")"
source "$BASE/.env"

readonly DOCKER_FILE="$BASE/docker-compose.yml"

SERVICES="$ORDERER_NAME"
LAST_CLI=""
for org in $ORGS_WITH_PEERS; do
    for peer in $PEERS; do
        SERVICES="$SERVICES ${peer}.${org,,}.$NETWORK_DOMAIN"
        LAST_CLI="${peer}_${org,,}_cli"
        SERVICES="$SERVICES $LAST_CLI"
    done
done

docker-compose -f "$DOCKER_FILE" down

echo "SERVICES [$SERVICES]"
docker-compose -f "$DOCKER_FILE" up -d $SERVICES

# wait for Hyperledger Fabric to start
echo "Waiting for fabric to complete start up ..."
echo "Getting $LAST_CLI status ..."
while ! (docker exec "$LAST_CLI" peer node status  | grep "STARTED")
do
    echo "..."
    sleep 1
done
