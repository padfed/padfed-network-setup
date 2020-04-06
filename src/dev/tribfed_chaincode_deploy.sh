#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

BASE=$(dirname "$(readlink -f "$0")")
[[ ! -v ENVIRONMENT ]] && source "$BASE/.env"

. "$BASE/../common/lib.sh"

echo_running

if [[ $# -eq 1 ]]; then
   readonly ARG1_VERSION="$1" # opcionalmente recibe una version
fi

echo "CHAINCODE_ARTIFACT [${CHAINCODE_ARTIFACT:-}]"
echo "CHAINCODE_DIR [$CHAINCODE_DIR]"
echo "CHAINCODE_PACKAGE [$CHAINCODE_PACKAGE]"

if [[ ! -d $CHAINCODE_DIR ]]; then
   echo_red "CHAINCODE_DIR [$(realpath "$CHAINCODE_DIR")] doesn't exist"
   exit 1
fi

if [[ ! -r $CHAINCODE_DIR/main.go && ! -v CHAINCODE_ARTIFACT ]]; then
   echo_red "main.go not found in CHAINCODE_DIR [$CHAINCODE_DIR] and CHAINCODE_ARTIFACT not especificated"
   exit 1
fi

if [[ -v CHAINCODE_ARTIFACT ]]; then
   if [[ ! -r $CHAINCODE_ARTIFACT ]]; then
      echo_red "CHAINCODE_ARTIFACT [$CHAINCODE_ARTIFACT] doesn't exist"
      exit 1
   fi
   if [[ -f $CHAINCODE_DIR/main.go ]]; then
      echo "Removing chaincode sources from [$CHAINCODE_DIR] ..."
      # Use "${var:?}" to ensure this never expands to /*
      rm -r "${CHAINCODE_DIR:?}"/*
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

readonly TLS_PARAMETERS=$( get_tls_parameters )

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

readonly ZERO_PEER_CLIS=$(docker ps --format \{\{.Names\}\} | grep "^peer0_" | grep "_cli$")

if [[ -z $ZERO_PEER_CLIS ]]; then
  echo "no peer0_*_cli was found"
  exit 1
fi

echo "ZERO PEER CLIS [$ZERO_PEER_CLIS]"

# "AND('ORG1.peer','ORG2.peer','ORG3.peer')"
ENDORSEMENT_POLICY="AND("
for cli in $ZERO_PEER_CLIS; do
   docker exec "$cli" peer chaincode install -n "$CHAINCODE_NAME" -v "$NEW_VERSION" -p "$CHAINCODE_PACKAGE"
   org=${cli#peer0_}
   org=${org%_cli}
   ENDORSEMENT_POLICY="${ENDORSEMENT_POLICY}'${org^^}.peer',"
done
ENDORSEMENT_POLICY="${ENDORSEMENT_POLICY%,})"
echo "ENDORSEMENT_POLICY [$ENDORSEMENT_POLICY]"

echo_sep "activating $CHAINCODE_NAME version $NEW_VERSION command $COMMAND ..."
docker exec peer0_afip_cli peer chaincode "$COMMAND" $TLS_PARAMETERS -o "$ORDERER" -C "$CHANNEL_NAME" -n "$CHAINCODE_NAME" -v "$NEW_VERSION" -c '{"Args":[""]}' -P "$ENDORSEMENT_POLICY"

while ! (docker exec peer0_afip_cli peer chaincode list --instantiated -C "$CHANNEL_NAME" | sed -E "/Name: $CHAINCODE_NAME,/s/.* Version: ([^,]+),.*/\1/" | grep -q "$NEW_VERSION"); do
   echo 'waiting for chaincode instantiation ...'
   sleep 1
done

echo_success "Chaincode $CHAINCODE_NAME $NEW_VERSION deployed"
