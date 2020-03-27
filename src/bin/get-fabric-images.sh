#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

# Check args
if [[ $# != 1 ]]; then
   echo "ERROR: $# unexpected number of params"
   echo "Usage: $0 <fabric-version>"
fi

DOCKER_NS=hyperledger
ARCH=amd64
VERSION="$1"
FABRIC_IMAGES=(fabric-peer fabric-orderer fabric-ccenv fabric-tools)

for image in ${FABRIC_IMAGES[@]}; do
  echo "==> Pulling ${DOCKER_NS}/$image:${ARCH}-${VERSION}"
  docker pull ${DOCKER_NS}/$image:${ARCH}-${VERSION}
done
