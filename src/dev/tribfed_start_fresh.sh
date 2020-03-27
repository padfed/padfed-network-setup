#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

# cd al directorio donde está ubicado este script
cd "$(dirname "$(readlink -f "$0")")"
readonly BASE="$(dirname "$(readlink -f "$0")")"
source "$BASE/.env"
. "$BASE/../common/lib.sh"

echo_running

usage() {
  echo "Usage: $0 p1"
  echo "p1: single or add-org"
  exit 1
}

[[ "$#" -eq 1 ]] || { echo_red "ERROR: $# is an invalid number of args"; usage; }

case "$1" in
single )  readonly ADD_ORG="no" ;;
add-org ) readonly ADD_ORG="yes" ;;
* ) echo_red "ERROR: p1 [$1]" ; usage ;;
esac

# detener y eliminar los contenedores, volúmenes y redes de fabric
docker-compose down --volumes --remove-orphans

# eliminar imágenes de padfedcc
./tribfed_delete_cc_images.sh

sudo rm -rf "$FABRIC_INSTANCE_PATH"

echo_sep "Generando material criptografico, orderer block, primera tx del channel y txs para anchors ..."
./tribfed_setup.sh

echo_sep "Levantando los servicios ..."
./tribfed_start.sh

echo_sep "Creando el channel y joineando peers ..."
./tribfed_channel_create.sh

echo_sep "Deployando chaincode ..."
./tribfed_chaincode_deploy.sh

if [[ $ADD_ORG == no ]]; then
   echo_success "END 2 END: START FRESH"
   exit 0
fi

# Puede setearse en el .env
NEWORG=${NEWORG:=CBA}

echo_sep "Agregando $NEWORG al channel ..."
./neworg_setup.sh $NEWORG

echo_sep "Levantando y joineando al channel los peers de la nueva org $NEWORG ..."
./neworg_start.sh $NEWORG

echo_sep "Deployando chaincode por segunda vez incluyendo a la nueva org $NEWORG ..."
ORGS_WITH_PEERS_EXTENDED="$ORGS_WITH_PEERS $NEWORG"
env ORGS_WITH_PEERS="$ORGS_WITH_PEERS_EXTENDED" ./tribfed_chaincode_deploy.sh

echo_sep "Ejecutando chaincode ..."
env ORGS_WITH_PEERS="$ORGS_WITH_PEERS_EXTENDED" ./tribfed_chaincode_test_1.sh

echo_success "END 2 END: START FRESH + ADD ORG + CHAINCODE EXECUTE"
