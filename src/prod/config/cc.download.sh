#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
readonly BASE=$(dirname $(readlink -f $0))

if [[ -r $PWD/.env ]]; then
   echo "Setting from PWD/.env ... "
   source $PWD/.env
   readonly TARGET="$PWD/gopath"
elif [[ -r $BASE/.env ]]; then
   echo "Setting from BASE/.env ... "
   source $BASE/.env
   readonly TARGET="$BASE/gopath"
else
   echo "WARN: Running without .env ... "
fi

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

readonly VERSION="$1"
readonly OUTPUT_NAME="$TARGET/download/$CHAINCODE_NAME-$VERSION"

for ext in tar.xz tar.xz.md5; do
    if [[ ! -f $OUTPUT_NAME.$ext ]]; then
       echo "Downloading $OUTPUT_NAME.$ext..."
       curl -fk# --noproxy nexus.cloudint.afip.gob.ar --create-dirs \
            "$CHAINCODE_REPO_URL/padfed/padfed-chaincode/$VERSION/padfed-chaincode-$VERSION.$ext" \
            -o "$OUTPUT_NAME.$ext"
    else  
       echo "File [$OUTPUT_NAME.$ext] already exists"
    fi
done

echo "Checking $OUTPUT_NAME.tar.xz MD5 signature..."
cp "$OUTPUT_NAME.tar.xz.md5" ./MD5SUMS
echo " *$OUTPUT_NAME.tar.xz" >> ./MD5SUMS
md5sum -c ./MD5SUMS
rm ./MD5SUMS
