#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

readonly BASE="$(dirname "$(readlink -f "$0")")"
source $BASE/.env
. "$BASE/../common/lib.sh"

echo_running

usage() {
  echo "Usage: $0 <p1> <p2>"
  echo "p1: crypto-config.yaml"
  echo "p2: configtx.yaml"
  exit 1
}

[[ "$#" -eq 2 ]] || { echo_red "ERROR: $# is an invalid number of args"; usage; }

check_param_file 1 "$1"
check_param_file 2 "$2"

readonly DIR="$(dirname "$PWD")/dev"          # BUG: dependiente del PWD / FIX: usar $BASE definido 2 líneas arriba

readonly FABRIC_CONFIG_PATH="$DIR"
readonly FABRIC_DEST_PATH="$DIR/fabric-instance"

readonly CRYPTOGEN=../bin/cryptogen
readonly CONFIGTXGEN=../bin/configtxgen

if [[ ! -x $CRYPTOGEN ]]; then
   ../bin/get-fabric-binaries.sh "$HLF_VERSION"
fi

echo "crypto-config.yaml (from p1) [$1]"
echo "FABRIC_DEST_PATH [$FABRIC_DEST_PATH]"
echo "configtx.yaml (from p2) [$2]"
echo "NETWORK_DOMAIN [$NETWORK_DOMAIN]"
echo "CHANNEL_NAME [$CHANNEL_NAME]"

sudo rm -Rf "$FABRIC_DEST_PATH"

mkdir "$FABRIC_DEST_PATH" -p

cp "$FABRIC_CONFIG_PATH/$2" "$FABRIC_DEST_PATH/configtx.yaml" --force

echo_sep "Ejecutando cryptogen generate ..."
$CRYPTOGEN generate --config="$FABRIC_CONFIG_PATH/$1" --output="$FABRIC_DEST_PATH/crypto-config"

#Generar el bloque genesis con la configuracion de la Blockchain
#debe ejecutarse en el directorio superior a la carpeta crypto-config

echo_sep "Ejecutando configtxgen -profile OrdererGenesis outputBlock ..."
$CONFIGTXGEN -configPath "$FABRIC_DEST_PATH" -profile OrdererGenesis -outputBlock "$FABRIC_DEST_PATH/genesis.block" -channelID "$SYSTEM_CHANNEL_NAME"

echo_sep "Ejecutando configtxgen -inspectBlock ..."
$CONFIGTXGEN -configPath "$FABRIC_DEST_PATH" -inspectBlock "$FABRIC_DEST_PATH/genesis.block" &> "$FABRIC_DEST_PATH/inspect.genesis.block.out"

echo_sep "Ejecutando configtxgen -outputCreateChannelTx ..."
$CONFIGTXGEN -configPath "$FABRIC_DEST_PATH" -profile "$CHANNEL_NAME" -outputCreateChannelTx "$FABRIC_DEST_PATH/chcreate.tx" -channelID "$CHANNEL_NAME"

echo_sep "Ejecutando configtxgen -inspectChannelCreateTx ..."
$CONFIGTXGEN -configPath "$FABRIC_DEST_PATH" -inspectChannelCreateTx "$FABRIC_DEST_PATH/chcreate.tx" &> "$FABRIC_DEST_PATH/inspect.chcreate.tx.out"

echo_sep "Ejecutando configtxgen -outputAnchorPeersUpdate ..."
for org in $ORGS_WITH_PEERS; do
    $CONFIGTXGEN -profile "$CHANNEL_NAME" -outputAnchorPeersUpdate "$FABRIC_DEST_PATH/${org}_anchor.tx" -channelID "$CHANNEL_NAME" -configPath "$FABRIC_DEST_PATH/" -asOrg "$org"
done

mv "$FABRIC_DEST_PATH/genesis.block"    "$FABRIC_DEST_PATH/crypto-config"
mv "$FABRIC_DEST_PATH/chcreate.tx"      "$FABRIC_DEST_PATH/crypto-config"
mv "$FABRIC_DEST_PATH"/*anchor.tx       "$FABRIC_DEST_PATH/crypto-config"

# Copia los tslca en peer_afip_cli/tls_root_cas para peer_afip_cli puede invocar chaincodes en los peers de otras orgs
sudo mkdir -p "$FABRIC_DEST_PATH/peer0_afip_cli/tls_root_cas/"
for f in $FABRIC_DEST_PATH/crypto-config/peerOrganizations/*/tlsca/*-cert.pem
do
  sudo cp "$f" "$FABRIC_DEST_PATH/peer0_afip_cli/tls_root_cas/"
done
