#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env
IDEMPOTENT=${IDEMPOTENT:-}

if [[ -z "$1" ]]; then
  echo "Debe indicar la version de CC a instalar"
  exit 1
fi

if ! [[ -x "$(command -v curl)" ]]; then
  echo 'Error: curl tool no instalado o no localizable en PATH, revise README con Prerequisitos de instalacion' >&2
  exit 1
fi

if ! [[ -x "$(command -v md5sum)" ]]; then
  echo 'Error: md5sum no instalado o no localizable en PATH, revise README con Prerequisitos de instalacion' >&2
  exit 1
fi

TARGET="$BASE/gopath"

if [[ -z "$IDEMPOTENT" || ! -f "$TARGET/download/padfed-chaincode-$1.tar.xz" ]]; then
  echo "Downloading padfed-chaincode-$1.tar.xz..."
  curl -fk# --noproxy nexus.cloudint.afip.gob.ar --create-dirs \
    $CHAINCODE_REPO_URL/padfed/padfed-chaincode/$1/padfed-chaincode-$1.tar.xz \
    -o $TARGET/download/padfed-chaincode-$1.tar.xz
fi

if [[ -z "$IDEMPOTENT" || ! -f "$TARGET/download/padfed-chaincode-$1.tar.xz.md5" ]]; then
  echo "Downloading padfed-chaincode-$1.tar.xz.md5..."
  curl -fk# --noproxy nexus.cloudint.afip.gob.ar  --create-dirs \
    $CHAINCODE_REPO_URL/padfed/padfed-chaincode/$1/padfed-chaincode-$1.tar.xz.md5 \
    -o $TARGET/download/padfed-chaincode-$1.tar.xz.md5
fi

echo "Checking padfed-chaincode-$1.tar.xz MD5 signature..."
cp $TARGET/download/padfed-chaincode-$1.tar.xz.md5 ./MD5SUMS
echo " *$TARGET/download/padfed-chaincode-$1.tar.xz" >> ./MD5SUMS
md5sum -c ./MD5SUMS
rm ./MD5SUMS
