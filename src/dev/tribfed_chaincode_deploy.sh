#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

BASE=$(dirname $(readlink -f $0))
[[ ! -v ENVIRONMENT ]] && source $BASE/.env

. "$BASE/../common/lib.sh"

echo_running

if [[ $# -eq 1 ]]; then
   readonly ARG1_VERSION="$1" # opcionalmente recibe una version
fi

echo "CHAINCODE_DIR [$(realpath "$CHAINCODE_DIR")]"

if [[ ! -d $CHAINCODE_DIR ]]; then
   echo_red "CHAINCODE_DIR [$(realpath "$CHAINCODE_DIR")] doesn't exist"
   exit 1
fi

if [[ ! -r $CHAINCODE_DIR/main.go ]]; then
   if [[ ! -v CHAINCODE_ARTIFACT ]]; then
      echo_red "main.go not found in CHAINCODE_DIR [$CHAINCODE_DIR] and CHAINCODE_ARTIFACT not especificated"
      exit 1
   fi
   if [[ ! -r $CHAINCODE_ARTIFACT ]]; then
      echo_red "CHAINCODE_ARTIFACT [$CHAINCODE_ARTIFACT] doesn't exist"
      exit 1
   fi
   tar -C "$CHAINCODE_DIR" -xaf "$CHAINCODE_ARTIFACT"
   if [[ ! -r $CHAINCODE_DIR/main.go ]]; then
       echo_red "CHAINCODE_ARTIFACT [$CHAINCODE_ARTIFACT] doesn't contain main.go"
       exit 1
   fi
   echo "main.go extracted from [$(realpath "$CHAINCODE_ARTIFACT")]"
else
   echo "main.go in [$(realpath "$CHAINCODE_DIR")]"
fi

TLS_PARAMETERS=""
if [[ $TLS_ENABLED == true ]]; then
    TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem"

    if [[ $TLS_CLIENT_AUTH_REQUIRED == true ]]; then
       TLS_PARAMETERS="$TLS_PARAMETERS --clientauth"
       TLS_PARAMETERS="$TLS_PARAMETERS --keyfile /etc/hyperledger/tls/client.key"
       TLS_PARAMETERS="$TLS_PARAMETERS --certfile /etc/hyperledger/tls/client.crt"
    fi
fi

echo_sep "determining chaincode version ..."
docker exec peer0_afip_cli peer chaincode list -C "$CHANNEL_NAME" --instantiated

readonly CC_VERSION="$(docker exec peer0_afip_cli peer chaincode list -C "$CHANNEL_NAME" --instantiated | sed -En '/Name: padfed/{s/.*Version: ([^,]+),.*/\1/;p}')"
echo "already instantiated version [${CC_VERSION:-anyone}]"

if [[ -z $CC_VERSION ]]
then
   readonly NEW_VERSION=${ARG1_VERSION:-1}
   readonly COMMAND="instantiate"
else
   if [[ -v ARG1_VERSION ]]; then
      readonly NEW_VERSION="$ARG1_VERSION"
   elif [[ $CC_VERSION == *[[:digit:]]* ]]; then
      readonly NEW_VERSION="$(("$CC_VERSION" + 1))"
   else
      readonly NEW_VERSION="${CC_VERSION}.x"
   fi
   readonly COMMAND="upgrade"
fi

echo_sep "deploying $CHAINCODE_NAME version $NEW_VERSION ..."

for ORG in ${ORGS_WITH_PEERS}; do
   docker exec "peer0_${ORG,,}_cli" peer chaincode install $TLS_PARAMETERS -n "$CHAINCODE_NAME" -v "$NEW_VERSION" -p "$CHAINCODE_PACKAGE"
done

echo_sep "activating $CHAINCODE_NAME version $NEW_VERSION command $COMMAND ..."
docker exec peer0_afip_cli peer chaincode "$COMMAND" $TLS_PARAMETERS -o "$ORDERER" -C "$CHANNEL_NAME" -n "$CHAINCODE_NAME" -v "$NEW_VERSION" -c '{"Args":[""]}' -P "$ENDORSEMENT_POLICY"

while !(docker exec peer0_afip_cli peer chaincode list --instantiated -C "$CHANNEL_NAME" | sed -E "/Name: $CHAINCODE_NAME,/s/.* Version: ([^,]+),.*/\1/" | grep -q "$NEW_VERSION"); do
   echo 'waiting for chaincode instantiation ...'
   sleep 1
done

echo_success "Chaincode $CHAINCODE_NAME $NEW_VERSION deployed"
