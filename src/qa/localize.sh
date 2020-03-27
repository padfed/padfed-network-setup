#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
ME=$(basename $0)
HERE=$(dirname $(readlink -f $0))
BASE="$HERE/deploy/nodes"

if [[ "$*" =~ "--debug" ]]; then
  set -x
  export DEBUG=1
fi

source $HERE/.env

bold=$(tput bold)
green=$(tput setaf 2)
normal=$(tput sgr0)

log() {
  echo -e "$*" | while read L; do printf "$bold$green[$ME]$normal $L\n"; done
}

localAddress() {
  nc -u 1.1.1.1 1000 &
  local P=$!
  ss -Hnup state established dst 1.1.1.1 dport = 1000 | awk "/pid=$P/{split(\$3,a,/:/);print a[1]}"
  kill $P
}

checkOrdererAddress() {
  if !(ip -o address | grep -q "$ORDERER_ADDRESS"); then
    local A=$(localAddress)
    log "La dirección configurar para el orderer ($ORDERER_ADDRESS) no coincide con ninguna de las direcciones de sus interfaces de red.
Reintente luego de corregir esta situación.
Si desea utilizar la dirección $A puede ejecutar el comando que sigue para realizar la corrección:
    sed -i 's/ORDERER_ADDRESS=.*/ORDERER_ADDRESS=$A/' $HERE/.env"
    exit 1
  fi
}

manglePorts() {
  log "Modifying network services ports..."
  sed -i 's/ORDERER_PORT=.*/ORDERER_PORT=7050/' $BASE/**/.env
  local P=8000
  for f in $BASE/**/.env
  do
    local L=$(($P + 1))
    sed -i "s/PEER_NODE_PRINCIPAL_PORT=.*/PEER_NODE_PRINCIPAL_PORT=$P/
            s/PEER_NODE_LISTENING_PORT=.*/PEER_NODE_LISTENING_PORT=$L/" $f
    P=$(($P + 10))
  done
}

nodeStart() {
  local node
  for node in "$@"; do
    log "Starting $node node..."
    (cd $BASE/$node && docker-compose -f $BASE/$node/docker-compose.yaml up -d)
  done
}

channelCreate() {
  local node
  for node in "$@"; do
    log "Creating channel on $node node..."
    IDEMPOTENT=1 $BASE/$node/ch.create.sh
  done
}

channelJoin() {
  local node
  for node in "$@"; do
    log "Joining to channel on $node node..."
    IDEMPOTENT=1 $BASE/$node/ch.join.sh
  done
}

chaincodeDownload() {
  local version=$1
  shift
  for node in "$@"; do
    log "Downloading chaincode $version on $node node..."
    IDEMPOTENT=1 $BASE/$node/cc.download.sh $version
  done
}

chaincodeInstall() {
  local version=$1
  shift
  for node in "$@"; do
    log "Installing chaincode $version on $node node..."
    IDEMPOTENT=1 $BASE/$node/cc.install.sh $version
  done
}

chaincodeDownloadInstall() {
  chaincodeDownload "$@"
  chaincodeInstall "$@"
}

chaincodeInstantiate() {
  local version=$1
  shift
  for node in "$@"; do
    log "Instantiating chaincode $version on $node node..."
    IDEMPOTENT=1 $BASE/$node/cc.instantiate.sh --wait $version
  done
}

chaincodeUpgrade() {
  local version=$1
  shift
  for node in "$@"; do
    log "Upgrading chaincode $version on $node node..."
    IDEMPOTENT=1 $BASE/$node/cc.upgrade.sh --wait $version
  done
}

chaincodeCall() {
  local node=$1
  shift
  log "Calling chaincode $2 $3 on $node node..."
  $BASE/$node/cc.call.sh "$@"
}

reset() {
  log "Removing all padfed containers..."
  docker ps -a --format '{{.ID}}' --filter "label=app=padfed" | xargs -r docker rm -f
  log "Cleaning padfed network configuration..."
  $HERE/clean.network.sh
  if [[ "$*" =~ "--reset-only" ]]; then
    exit 0
  fi
  log "Creating new padfed network configuration..."
  $HERE/create.network.sh
}

main() {

  export ORDERER_ADDRESS=$(localAddress)

  if [[ "$*" =~ "--reset" ]]; then
    reset "$@"
  fi

  checkOrdererAddress

  manglePorts

  nodeStart orderer {afip,arba,comarb}.peer{0,1}

  channelCreate afip.peer0

  channelJoin afip.peer1 {arba,comarb}.peer{0,1}

  # Instalar CC

  chaincodeDownloadInstall 0.99.5 {afip,arba,comarb}.peer0

  chaincodeInstantiate 0.99.5 afip.peer0

  # Actualizar CC

  chaincodeDownloadInstall 0.99.6 {afip,arba,comarb}.peer0

  chaincodeUpgrade 0.99.6 afip.peer0

  log "Success!"

}

main "$@"
