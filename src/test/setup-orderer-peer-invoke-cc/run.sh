#!/bin/bash

set -Eeuo pipefail

function inicialize() {
readonly BASE="$(dirname "$(readlink -f "$0")")"

pushd "$BASE/../../prod"

. "$PWD/scripts/lib.sh"

readonly SETUP_CONF="setup.conf" && check_file "$SETUP_CONF" && source "$SETUP_CONF"

check_env MSPID
}

function mktemp2() {
   mkdir -p ./tmp
   echo "./tmp/$$.$1"
}

function run_orderer() {
./setup.sh clean
./setup.sh end2end orderer0
}

function run_peer() {
./setup.sh make_requests peer0
./setup.sh cas_process_requests "$MSPID-peer0-crypto-requests"
./setup.sh setup peer0

pushd "./fabric-instance/$MSPID-peer0"

sed -i 's/OPERATIONS_PORT=.*/OPERATIONS_PORT=10443/' .env

# --filter "ansestor=..." requires docker v19
#readonly REAL_ORDERER_NAME="$(docker ps --filter "ancestor=hyperledger/fabric-orderer" --format '{{.Names}}')"
readonly REAL_ORDERER_NAME="$(docker ps --format '{{.Names}}' | grep orderer0)"
sed -i "s/ORDERER_NAME=.*/ORDERER_NAME=$REAL_ORDERER_NAME/" .env

docker-compose up -d

./ch.create.sh

popd
}

function deploy_cc() {

readonly CC_VERSION="$1"

pushd "./fabric-instance/$MSPID-peer0"

sed -i "s/CHAINCODE_ENDORSMENT=.*/CHAINCODE_ENDORSMENT=\"AND('${MSPID}.member')\"/" .env

source .env

./cc.download.sh    "$CC_VERSION"
./cc.install.sh     "$CC_VERSION"
./cc.instantiate.sh "$CC_VERSION"

echo "Verificando que el chaincode $CHAINCODE_NAME:$CC_VERSION quede instanciado ..."

while ! (docker exec "$NODE_NAME" peer chaincode list --instantiated -C "$CHANNEL_NAME" | grep -q "Version: ${CC_VERSION},"); do
   echo 'Esperando que el chaincode quede instanciado ...'
   sleep 1
done
echo "Chaincode $CHAINCODE_NAME:$CC_VERSION instanciado !!!"

./cc.invoke.sh invoke GetVersion

popd
}

inicialize

echo_running

run_orderer

run_peer

deploy_cc 0.8.8

popd

echo_success
