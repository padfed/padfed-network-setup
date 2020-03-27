#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

BASE=$(dirname $(readlink -f $0))
[[ ! -v ENVIRONMENT ]] && source $BASE/.env

docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

red_echo()   { echo -e "\033[1;31m$@\033[0m"; }

green_echo() { echo -e "\033[1;32m$@\033[0m"; }

if [[ "$#" -eq 1 ]]; then
   ARG1_VERSION="$1" # opcionalmente recibe una version
fi

if [[ ! -f "$CHAINCODE_DIR/main.go" ]]
then
    red_echo "Los fuentes del chaincode deben estar en $CHAINCODE_DIR (o modificar \$CHAINCODE_DIR)"
    exit 1
fi

if [[ "$TLS_ENABLED" == "true" ]]; then
    PEER_CLI_TLS_WITH_ORDERER="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem"

    if [[ "$TLS_CLIENT_AUTH_REQUIRED" == "true" ]]; then
       PEER_CLI_TLS_WITH_ORDERER="$PEER_CLI_TLS_WITH_ORDERER --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
    fi
fi

echo '####################################################'
echo docker exec peer0_afip_cli peer chaincode list
docker exec peer0_afip_cli peer chaincode list -C $CHANNEL_NAME --instantiated

CC_VERSION="$(docker exec peer0_afip_cli peer chaincode list -C $CHANNEL_NAME --instantiated | sed -En '/Name: padfed/{s/.*Version: ([^,]+),.*/\1/;p}')"
echo '####################################################'
echo "version detectada --> $CC_VERSION"

if [ -z "$CC_VERSION" ]
then
   CC_NEW_VERSION=${ARG1_VERSION:=1}
   CC_COMMAND="instantiate"
else
   echo "deploy detectado con version $CC_VERSION"
   CC_NEW_VERSION=${ARG1_VERSION:=$(expr $CC_VERSION + 1)}
   CC_COMMAND="upgrade"
fi

echo "$CC_COMMAND deploy con version $CC_NEW_VERSION"
echo "fuentes a empaquetar en $CHAINCODE_DIR"

for ORG in ${ORGS_WITH_PEERS}; do
   docker exec peer0_${ORG,,}_cli peer chaincode install $PEER_CLI_TLS_WITH_ORDERER -n $CHAINCODE_NAME -v $CC_NEW_VERSION -p $CHAINCODE_PACKAGE
done

echo "#################################################### (CHAINCODE ${CC_COMMAND})"
docker exec peer0_afip_cli peer chaincode ${CC_COMMAND} $PEER_CLI_TLS_WITH_ORDERER -o $ORDERER -C $CHANNEL_NAME -n $CHAINCODE_NAME -v $CC_NEW_VERSION -c '{"Args":[""]}' -P $ENDORSEMENT_POLICY

while !(docker exec peer0_afip_cli peer chaincode list --instantiated -C $CHANNEL_NAME | sed -E "/Name: $CHAINCODE_NAME,/s/.* Version: ([^,]+),.*/\1/" | grep -q $CC_NEW_VERSION); do
   echo 'Esperando que el chaincode esté instanciado...'
   sleep 1
done

echo "########################################"
green_echo "Chaincode $CHAINCODE_NAME $CC_NEW_VERSION instanciado!"
