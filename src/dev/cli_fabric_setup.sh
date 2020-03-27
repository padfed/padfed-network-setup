#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

usage() {
  echo "Usage: $0 <p1> <p2>"
  echo "p1: crypto-config.yaml a utilizar, ej: tribfed_crypto-config.yaml"
  echo "p2: configtx.yaml a utilizar, ej: tribfed_configtx.yaml"
  exit 1
}

if [[ "$#" -ne 2 ]]; then
   usage
fi

BASE=$(dirname $(readlink -f $0))
source $BASE/.env
DIR="$( dirname "${PWD}")"/dev          # BUG: dependiente del PWD / FIX: usar $BASE definido 2 líneas arriba

readonly FABRIC_CONFIG_PATH="$DIR"
readonly FABRIC_DEST_PATH="$DIR/fabric-instance"

CHANNEL_TX=${CHANNEL_NAME}.tx

readonly CRYPTOGEN=../bin/cryptogen
readonly CONFIGTXGEN=../bin/configtxgen

if [[ ! -x $CRYPTOGEN ]]; then
   ../bin/get-fabric-binaries.sh "$HLF_VERSION"
fi

echo "########################################"
echo "FABRIC_DEST_PATH [$FABRIC_DEST_PATH]"
echo "crypto-config.yaml (from p1) [$1]"
echo "configtx.yaml (from p2) [$2]"
echo "network (form .env) [$NETWORK_DOMAIN]"
echo "system channel (from .env) [$SYSTEM_CHANNEL_NAME]"
echo "channel name (from .env) [$CHANNEL_NAME]"
echo "channel TX filename [$CHANNEL_TX]"
echo "########################################"

sudo rm -Rf $FABRIC_DEST_PATH

mkdir $FABRIC_DEST_PATH -p

cp $FABRIC_CONFIG_PATH/$2 $FABRIC_DEST_PATH/configtx.yaml --force

#Genera los materiales criptograficos requeridos para iniciar una red.

echo "########################################"
echo "Ejecutando cryptogen generate ..."
$CRYPTOGEN generate --config=$FABRIC_CONFIG_PATH/$1 --output=$FABRIC_DEST_PATH/crypto-config

#Generar el bloque genesis con la configuracion de la Blockchain
#debe ejecutarse en el directorio superior a la carpeta crypto-config

echo "########################################"
echo "Ejecutando configtxgen -profile OrdererGenesis outputBlock ..."
$CONFIGTXGEN -configPath $FABRIC_DEST_PATH -profile OrdererGenesis -outputBlock $FABRIC_DEST_PATH/genesis.block -channelID $SYSTEM_CHANNEL_NAME

echo "########################################"
echo "Ejecutando configtxgen -inspectBlock ..."
$CONFIGTXGEN -configPath $FABRIC_DEST_PATH -inspectBlock $FABRIC_DEST_PATH/genesis.block &> $FABRIC_DEST_PATH/inspect.genesis.block.out

#Generacion de la TX de configuracion para el channel

echo "########################################"
echo "Ejecutando configtxgen -outputCreateChannelTx ..."
$CONFIGTXGEN -configPath $FABRIC_DEST_PATH -profile $CHANNEL_NAME -outputCreateChannelTx $FABRIC_DEST_PATH/$CHANNEL_TX -channelID $CHANNEL_NAME

echo "########################################"
echo "Ejecutando configtxgen -inspectChannelCreateTx ..."
$CONFIGTXGEN -configPath $FABRIC_DEST_PATH -inspectChannelCreateTx $FABRIC_DEST_PATH/$CHANNEL_TX &> $FABRIC_DEST_PATH/inspect.$CHANNEL_NAME.create.tx.out

echo "########################################"
echo "Ejecutando configtxgen -outputAnchorPeersUpdate ..."
for org in ${ORGS_WITH_PEERS}; do
    $CONFIGTXGEN -profile $CHANNEL_NAME -outputAnchorPeersUpdate $FABRIC_DEST_PATH/${org}_anchor.tx -channelID $CHANNEL_NAME -configPath $FABRIC_DEST_PATH/ -asOrg ${org}
done

mv $FABRIC_DEST_PATH/genesis.block    $FABRIC_DEST_PATH/crypto-config
mv $FABRIC_DEST_PATH/$CHANNEL_TX      $FABRIC_DEST_PATH/crypto-config
mv $FABRIC_DEST_PATH/*anchor.tx       $FABRIC_DEST_PATH/crypto-config

# Copia los tslca en peer_afip_cli/tls_root_cas para peer_afip_cli puede invocar chaincodes en los peers de otras orgs 
sudo mkdir -p $FABRIC_DEST_PATH/peer0_afip_cli/tls_root_cas/
for f in $FABRIC_DEST_PATH/crypto-config/peerOrganizations/*/tlsca/*-cert.pem
do
  sudo cp $f $FABRIC_DEST_PATH/peer0_afip_cli/tls_root_cas/
done
