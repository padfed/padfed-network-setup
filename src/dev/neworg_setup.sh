#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

red_echo()   { echo -e "\033[1;31m$@\033[0m"; }

green_echo() { echo -e "\033[1;32m$@\033[0m"; }

check_param_file() {
[[ -f "$2" ]] || { red_echo "ERROR: p$1: File [$2] not found !!!"; usage; }
}

check_file() {
[[ -s "$1" ]] || { red_echo "ERROR: File [$1] not found !!!"; exit 1; }
}

check_dir() {
[[ -d "$1" ]] || { red_echo "ERROR: Dir [$1] not found !!!"; exit 1; }
}

function check_exe() {
local command="$(command -v "$1")"
[[ -x $command ]] && { echo "exe checked [$command]"; } || { red_echo "ERROR: Exe ["$1"] not found !!!"; exit 1; } 
}

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 neworg_name (ex: AGIP)"
  echo "The script will add a neworg into the channel"
  exit 1
fi

THIS="$0"

NEWORG="${1^^}" 
DOMAIN="${NEWORG,,}".tribfed.gob.ar

readonly BASE=$(dirname $(readlink -f $0))
[[ ! -v ENVIRONMENT ]] && source $BASE/.env
PATH=$(realpath $BASE/../bin):$PATH
PATH=$(realpath $BASE/../common):$PATH

check_exe cryptogen
check_exe jq
check_exe ch.config.tool.sh
check_exe ch.sign.update.tx.sh
check_exe ch.make.configtx.yaml.sh

# construye un crypto-config.yaml para que sea utilizado por cryptogen
make_crypto_config_yaml() {
  local OUTPUT_CRYPTO_CONFIG_YAML="$1"

cat <<< "Organizations:
PeerOrgs:
  - Name: ${NEWORG}
    Domain: cba.tribfed.gob.ar
    CA:
      Hostname: ca
      Country: AR
      Province: xx
      Locality: xx
      OrganizationalUnit: ${NEWORG}
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 4
" > "$OUTPUT_CRYPTO_CONFIG_YAML"
}

# construye un configtx.yaml para que sea utilizado por 
make_configtx_yaml() {

   local OUTPUT_CONFIGTX_YAML="$1"

   local MSP_DIR="." # indica que el configtx.yaml esta en el mismo directorio msp
   local ANCHOR_PEER_NAME="peer0.${NEWORG,,}.$DOMAIN" 
   local ANCHOR_PEER_PORT="${PEER_PORT:-7051}"

   ch.make.configtx.yaml.sh \
        "$NEWORG" \
        "$MSP_DIR" \
        "$ANCHOR_PEER_NAME" \
        "$ANCHOR_PEER_PORT" \
        "$OUTPUT_CONFIGTX_YAML"

   check_file "$OUTPUT_CONFIGTX_YAML"
}

echo "########################################"
echo "Running: $THIS"
echo "- neworg (from p1): $NEWORG"
echo "- channel (from .env): $CHANNEL_NAME"

readonly TMP_PATH="${BASE}/${NEWORG}_setup_tmp"
sudo rm -Rf "$TMP_PATH"
mkdir "$TMP_PATH"

echo "Generating ${NEWORG} crypto material ..."

make_crypto_config_yaml "$TMP_PATH/crypto-config.yaml"

cryptogen generate --config="$TMP_PATH/crypto-config.yaml" --output="$TMP_PATH/crypto-config"

readonly CRYPTOGEN_OUTPUT_ORG_DIR="$TMP_PATH/crypto-config/peerOrganizations/${DOMAIN}"

check_dir  "$CRYPTOGEN_OUTPUT_ORG_DIR" 
check_dir  "$CRYPTOGEN_OUTPUT_ORG_DIR/msp" 
check_dir  "$CRYPTOGEN_OUTPUT_ORG_DIR/tlsca" 

make_configtx_yaml "$CRYPTOGEN_OUTPUT_ORG_DIR/msp/configtx.yaml"

echo "Coping crypto material from tmp to target ..."

readonly NEWORG_TARGET_PATH="$FABRIC_INSTANCE_PATH/crypto-config/peerOrganizations/$DOMAIN"

sudo rm -Rf "$NEWORG_TARGET_PATH"

sudo cp -rf "$CRYPTOGEN_OUTPUT_ORG_DIR" "$NEWORG_TARGET_PATH"

# Coping tlsca from target to peer0_afip_cli
sudo mkdir -p "$FABRIC_INSTANCE_PATH/peer0_afip_cli/tls_root_cas/"
sudo cp "$CRYPTOGEN_OUTPUT_ORG_DIR/tlsca/"*-cert.pem "$FABRIC_INSTANCE_PATH/peer0_afip_cli/tls_root_cas/"

echo "Making update_tx ..."

readonly UPDATE_IN_ENVELOPE_PB="$TMP_PATH"/${NEWORG}_update_in_envelope.pb

ch.config.tool.sh add \
         -m $NEWORG \
         -k org \
         -v "$CRYPTOGEN_OUTPUT_ORG_DIR/msp" \
         -c $CHANNEL_NAME \
         -g Application \
         -u "$UPDATE_IN_ENVELOPE_PB"

check_file "$UPDATE_IN_ENVELOPE_PB"

# Sign and Submit the Config Update
#
# We now have a protobuf binary – UPDATE_IN_ENVELOPE_PB –.
# However, we need signatures from the requisite Admin users before the config can be written to the ledger.
# The modification policy (mod_policy) for our channel Application group is set to the default of “MAJORITY”,
# which means that we need a majority of existing org admins to sign it.
# Because we have only two orgs – Org1 and Org2 – and the majority of two is two, we need both of them to sign.
# Without both signatures, the ordering service will reject the transaction for failing to fulfill the policy.
#
# First, let’s sign this update proto as the Org1 Admin.
# Remember that the CLI container is bootstrapped with the Org1 MSP material,
# so we simply need to issue the peer channel signconfigtx command:

readonly CLI=peer0_afip_cli
readonly CLI_SIGNING_PATH="${FABRIC_INSTANCE_PATH}"/${CLI}/signing && check_dir "$CLI_SIGNING_PATH"

cp "${UPDATE_IN_ENVELOPE_PB}" "${UPDATE_IN_ENVELOPE_PB}.unsigned"
SIGNED_FILENAME=${UPDATE_IN_ENVELOPE_PB}

for ORG in ${ORGS_WITH_PEERS}; do

    if [[ "$ORG" == "AFIP" ]]; then
       echo "Skiping AFIP because AFIP signature will be attached executing peer channel update ..."
    else
       echo "Signing with ${CLI} and ${ORG} crypto material ..."

       ORG_DOMAIN="${ORG,,}.tribfed.gob.ar"
       
       ADMIN_DIR="${FABRIC_INSTANCE_PATH}/crypto-config/peerOrganizations/${ORG_DOMAIN}/users/Admin@${ORG_DOMAIN}"
       check_dir "$ADMIN_DIR/msp"
       check_dir "$ADMIN_DIR/tls"

       SIGNED_FILENAME=${SIGNED_FILENAME}.signed_by_${ORG}
       rm -f ${SIGNED_FILENAME}
       
       ch.sign.update.tx.sh ${CLI} \
                      "$CLI_SIGNING_PATH" \
                       ${ORG} \
                      "$ADMIN_DIR" \
                       peer0.${ORG_DOMAIN}:7051 \
                       ${UPDATE_IN_ENVELOPE_PB} \
                       ${SIGNED_FILENAME}

       check_file ${SIGNED_FILENAME}

       cp ${SIGNED_FILENAME} ${UPDATE_IN_ENVELOPE_PB}
    fi
done

# Lastly, we will issue the peer channel update command.
# The Org2 Admin signature will be attached to this call
# so there is no need to manually sign the protobuf a second time.

echo "########################################"
echo Updating channel, adding ${NEWORG} ...

if [[ ${TLS_ENABLED:="true"} == "true" ]]; then
    PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem"

    if [[ {$TLS_CLIENT_AUTH_REQUIRED:="false"} == "true" ]]; then
       PEER_CLI_TLS_PARAMETERS="${PEER_CLI_TLS_PARAMETERS} --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
    fi
fi

docker exec $CLI rm -f /signing/*

docker cp "$SIGNED_FILENAME" $CLI:/signing

echo "Setting TLS parameters for peer0_afip_cli ..."

docker exec $CLI peer channel update -f "/signing/$( basename $SIGNED_FILENAME)" $PEER_CLI_TLS_PARAMETERS -o $ORDERER -c $CHANNEL_NAME

echo "########################################"
green_echo "[${THIS}] - New org ${NEWORG} added to ${CHANNEL_NAME}: OK !!!"
echo "########################################"
