#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
readonly BASE=$(dirname "$(readlink -f "$0")")
source "$BASE/.env"

function package() {
  local CHAINCODE_FILE_TAR_XZ="$TARGET/download/$CHAINCODE_NAME-$VERSION.tar.xz"

  if ! [[ -r $CHAINCODE_FILE_TAR_XZ ]]; then
     echo "Error: no esta disponible el archivo [$(basename "$CHAINCODE_FILE_TAR_XZ")] en [$TARGET/download/]" >&2
     exit 1
  fi
  if ! [[ -x "$(command -v tar)" ]]; then
     echo "Error: comando tar no instalado o no localizable en PATH" >&2
     exit 1
  fi

  readonly PKG="$TARGET/src/$CHAINCODE_PATH"
  test -d "$PKG" && rm -rf "$PKG"
  mkdir -p "$PKG"
  tar -C "$PKG" -xaf "$CHAINCODE_FILE_TAR_XZ"

  docker exec "$CONTAINER" \
    peer chaincode package \
      -n "$CHAINCODE_NAME" \
      -p "$CHAINCODE_PATH" \
      -v "$VERSION" \
      "/opt/gopath/deploy/${CHAINCODE_NAME}-${VERSION}.ccd"
}

############################################################

if [[ -z $1 ]]; then
  echo "Error: p1 debe ser la version del CC a instalar"
	exit 1
fi

readonly VERSION="$1"

if ! (echo "$VERSION" | grep -qE '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9a-z-]+(\.[0-9a-z-]+)*)?(\+[0-9a-z-]+(\.[0-9a-z-]+)*)?$') ; then
  echo "La versión $VERSION no es una versión semántica."
  exit 1
fi

readonly TARGET="${FABRIC_INSTANCE_PATH}/$MSPID-${NODE_BASENAME,,}/gopath"

mkdir -p "$TARGET/deploy"

readonly CONTAINER="${NODE_NAME}.cli"

if [[ ! -f "$TARGET/deploy/${CHAINCODE_NAME}-${VERSION}.ccd" ]]; then
   package
fi

if ! (docker exec "$CONTAINER" peer chaincode list -C "$CHANNEL_NAME" --installed | sed -E "/Name: $CHAINCODE_NAME,/s/.* Version: ([^,]+),.*/\1/" | grep -q ${VERSION}); then
  docker exec "$CONTAINER" \
    peer chaincode install \
      "/opt/gopath/deploy/${CHAINCODE_NAME}-${VERSION}.ccd"
fi
