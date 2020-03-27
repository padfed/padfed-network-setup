#!/bin/bash

set -Eeuo pipefail

readonly BASE="$(dirname "$(readlink -f "$0")")"

# Check args
if [[ $# != 1 ]]; then
   echo "ERROR: $# unexpected number of params"
   echo "Usage: $(basename "$0") <fabric-version>"
   exit 1
fi

readonly VERSION="$1"

pushd "$BASE/.."

"$BASE/bootstrap.sh" "$VERSION" -d -s

# bootstrap.sh -d -s ademas de los binarios descomprime un directorio config conteniendo 3 yamls
# procedemos a elimnarlos

for y in configtx core orderer; do
    rm -f "$PWD/config/$y.yaml" 
done

if [[ -d $PWD/config ]]; then
   find "$PWD/config" -maxdepth 0 -empty -exec rm -r {} \;
fi

for b in peer orderer idemixgen; do
    rm -f "$BASE/$b"
done

popd 
