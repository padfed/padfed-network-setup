#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

red_echo()   { echo -e "\033[1;31m$@\033[0m"; }

green_echo() { echo -e "\033[1;32m$@\033[0m"; }

# cd al directorio donde está ubicado este script
cd "$(dirname $(readlink -f "$0"))"
BASE=$(dirname $(readlink -f $0))
source $BASE/.env

usage() {
  echo "Usage: $0 p1"
  echo "p1: single or add-new-org"
  exit 1
}

[[ "$#" -eq 1 ]] || { red_echo "ERROR: invalid number of args"; usage; }

case "$1" in
single ) ;;
add-new-org ) ADD_NEW_ORG="yes" ;;
* ) red_echo "ERROR: p1 [$1]" ; usage ;;
esac

# detener y eliminar los contenedores, volúmenes y redes de fabric
docker-compose down --volumes --remove-orphans

# eliminar imágenes de padfedcc
./tribfed_delete_cc_images.sh

sudo rm -rf $FABRIC_INSTANCE_PATH

echo '##########################################################################'
echo Generando material criptografico, orderer block, primera tx del channel y txs para anchors ...
./tribfed_setup.sh

echo '##########################################################################'
echo Creando el channel y joineando peers ...
./tribfed_start.sh

echo '##########################################################################'
echo Deployando chaincode ...
./tribfed_chaincode_deploy.sh

if [[ ${ADD_NEW_ORG:="no"} == "no" ]]; then
   echo '##########################################################################'
   green_echo "END 2 END: START FRESH ... OK !!!"
   echo '##########################################################################'
   exit
fi 

# Puede setearse en el .env
NEWORG=${NEWORG:="CBA"}

echo '##########################################################################'
echo "Agregando $NEWORG al channel ..."
./neworg_setup.sh $NEWORG

echo '##########################################################################'
echo "Levantando y joineando al channel los peers de la nueva org $NEWORG ..."
./neworg_start.sh $NEWORG

echo '##########################################################################'
echo "Deployando chaincode por segunda vez incluyendo a nueva org $NEWORG ..."
ORGS_WITH_PEERS_EXTENDED="$ORGS_WITH_PEERS $NEWORG"
env ORGS_WITH_PEERS="$ORGS_WITH_PEERS_EXTENDED" ./tribfed_chaincode_deploy.sh

echo '##########################################################################'
echo Ejecutando chaincode ...
env ORGS_WITH_PEERS="$ORGS_WITH_PEERS_EXTENDED" ./tribfed_chaincode_test_1.sh

echo '##########################################################################'
green_echo "END 2 END: START FRESH + ADDING ORG + EXECUTING CHAINCODE ... OK !!!"
echo '##########################################################################'
