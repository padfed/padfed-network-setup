#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env
IDEMPOTENT=${IDEMPOTENT:-}

if [[ -z "$1" ]]; then
    echo "Debe indicar la versión del CC a instalar"
	exit 1
fi

if ! [[ -x "$(command -v tar)" ]]; then
    echo 'Error: tar no instalado o no localizable en PATH, revise README con Prerequisitos de instalacion' >&2
    exit 1
fi

TARGET=$BASE/gopath

PKG=$TARGET/src/${CHAINCODE_PATH}
test -d $PKG && rm -rf $PKG
mkdir -p $PKG

DEP=$TARGET/deploy
test -d $DEP || mkdir -p $DEP

tar -C $PKG -xaf $TARGET/download/padfed-chaincode-$1.tar.xz

CONTAINER="${PEER_NAME}.${BLOCKCHAIN_NETWORK_NAME}.${ENVIRONMENT}.${ORG_NAME}.${ORGS_NETWORK_DOMAIN_NAME}.cli"

if [[ -z "$IDEMPOTENT" || ! -f /opt/gopath/deploy/${CHAINCODE_NAME}-$1.ccd ]]; then
  docker exec $CONTAINER \
    peer chaincode package \
      -n ${CHAINCODE_NAME} \
      -p ${CHAINCODE_PATH} \
      -v $1 \
      /opt/gopath/deploy/${CHAINCODE_NAME}-$1.ccd
fi

if test -z "$IDEMPOTENT" || ! (docker exec $CONTAINER peer chaincode list -C $CHANNEL_NAME --installed | sed -E "/Name: $CHAINCODE_NAME,/s/.* Version: ([^,]+),.*/\1/" | grep -q $1); then
  docker exec $CONTAINER \
    peer chaincode install \
      /opt/gopath/deploy/${CHAINCODE_NAME}-$1.ccd
fi
