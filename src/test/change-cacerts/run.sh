#!/bin/bash

set -Eeuo pipefail

function inicialize() {
readonly BASE="$(dirname "$(readlink -f "$0")")"

pushd "$BASE/../../prod/"

. "$PWD/scripts/lib.sh"

grep CA_CRT_DAYS= setup.conf

echo "Para testear el reemplazo de cacerts vencidos"
echo "podes setear CA_CRT_DAYS=2 en el setup.conf"
echo "y volver a correr: "
echo "./setup-orderer-peer-invoke-cc/run.sh && ./change-cacerts/run.sh"
askProceed

popd
}

function load_new_cacerts() {
readonly CERTS_PATH="$BASE/new-crypto-stage/XXX-orderer0"

source "$CERTS_PATH/index.conf"

readonly root_certs="$CERTS_PATH/cacerts/$(basename "$MSP_CA_CRT")" 
readonly intermediate_certs="$CERTS_PATH/cacerts/$(basename "$MSP_ICA_CRT")" 
readonly tls_root_certs="$root_certs"
readonly tls_intermediate_certs="$CERTS_PATH/cacerts/$(basename "$TLS_ICA_CRT")" 
readonly ope_root_certs="$root_certs"
readonly ope_intermediate_certs="$CERTS_PATH/cacerts/$(basename "$OPE_ICA_CRT")" 

echo "root_certs [$root_certs]"
echo "intermediate_certs [$intermediate_certs]"
echo "tls_root_certs [$tls_root_certs]"
echo "tls_intermediate_certs [$tls_intermediate_certs]"
echo "ope_root_certs [$ope_root_certs]"
echo "ope_intermediate_certs [$ope_intermediate_certs]"
}

function invoke_cc() {
echo "Invoking GetVersion?debug ..."

pushd "$BASE/../../prod/fabric-instance/XXX-peer0"

sleep 5

./cc.invoke.sh invoke "GetVersion?debug"

popd
}

function mktemp2() {
   mkdir -p ./tmp
   echo "./tmp/$$.$1"
}

function set_ouis_variables() {
if [[ ! -v ouis_new_value ]]; then
   readonly ouis_intermediate_certs_b64="$(base64 -w 0 "$intermediate_certs")"    

   readonly ouis_new_entry="[{\"certificate\":\"$ouis_intermediate_certs_b64\",\"organizational_unit_identifier\":\"MSP-TRIBUTARIA\"}]"

   readonly ouis_current_value_json_file="$(mktemp2 ouis.json)"

   ./ch.config.tool.sh read -c ordererchannel -m XXX -g Orderer -k organizational_unit_identifiers -u "$ouis_current_value_json_file"

   readonly ouis_new_value="$(jq ". += $ouis_new_entry" "$ouis_current_value_json_file")"
fi
}

function add_new_cacerts() {
echo "Adding new cacerts into BC config ..."

pushd "$BASE/../../prod/fabric-instance/XXX-peer0"

# first the roots then the intermediates
local CACERTS_KEYS="root_certs tls_root_certs intermediate_certs organizational_unit_identifiers tls_intermediate_certs"

for c in ordererchannel padfedchannel; do
    for k in $CACERTS_KEYS; do
        if [[ $k == "organizational_unit_identifiers" ]]; then

           set_ouis_variables

           v="$ouis_new_value"
           task="set_value"
        else
           v_tmp="${!k}"
           v="$(base64 -w 0 "$v_tmp")"
           task="add"
        fi
        set -x
        ./ch.config.tool.sh "$task" -c "$c" -m XXX -k "$k" -v "$v" -x
        set +x
    done
done

popd
}

function set_new_cacerts() {
echo "Removing old cacerts from BC config ..."

pushd "$BASE/../../prod/fabric-instance/XXX-peer0"

# first the intermediates then the roots
local CACERTS_KEYS="organizational_unit_identifiers intermediate_certs tls_intermediate_certs root_certs tls_root_certs"

for k in $CACERTS_KEYS; do
    for c in ordererchannel padfedchannel; do
        if [[ $k == "organizational_unit_identifiers" ]]; then

           set_ouis_variables

           v="$ouis_new_entry"
        else
           v_tmp="${!k}"
           v="[\"$(base64 -w 0 "$v_tmp")\"]"
        fi

        set -x
        ./ch.config.tool.sh set_value -c "$c" -m XXX -k "$k" -v "$v" -x
        set +x
    done
done

popd
}

function start_network() {
for n in peer0 orderer0; do
    pushd "$BASE/../../prod/fabric-instance/XXX-$n"
    docker-compose up -d
    popd
done
}

function stop_network() {
for n in peer0 orderer0; do
    pushd "$BASE/../../prod/fabric-instance/XXX-$n"
    docker-compose stop
    popd
done
}

function restart_network() {
stop_network
start_network   
}

function replace_crypto_material() {
echo "Replacing crypto_material ..."

ADMIN_MSP_CRT="$CERTS_PATH/$(basename "$ADMIN_1_MSP_CRT")"
ADMIN_MSP_KEY="$CERTS_PATH/$(basename "$ADMIN_1_MSP_KEY")"
ADMIN_TLS_CRT="$CERTS_PATH/$(basename "$ADMIN_1_TLS_CRT")"
ADMIN_TLS_KEY="$CERTS_PATH/$(basename "$ADMIN_1_TLS_KEY")"

for n in peer0 orderer0; do
    pushd "$BASE/../../prod/fabric-instance/XXX-$n"
    if [[ $n == orderer0 ]]; then
       NODE_TYPE=orderer 
       NODE_MSP_CRT="$CERTS_PATH/$(basename "$ORDERER_MSP_CRT")"
       NODE_MSP_KEY="$CERTS_PATH/$(basename "$ORDERER_MSP_KEY")"
       NODE_TLS_KEY="$CERTS_PATH/$(basename "$ORDERER_TLS_KEY")"
       NODE_TLS_CRT="$CERTS_PATH/$(basename "$ORDERER_TLS_CRT")"
       NODE_TLS_CLIENT_KEY="$CERTS_PATH/$(basename "$ORDERER_TLS_CLIENT_KEY")"
       NODE_TLS_CLIENT_CRT="$CERTS_PATH/$(basename "$ORDERER_TLS_CLIENT_CRT")"
       NODE_OPE_CLIENT_KEY="$CERTS_PATH/$(basename "$ORDERER_OPE_CLIENT_KEY")"
       NODE_OPE_CLIENT_CRT="$CERTS_PATH/$(basename "$ORDERER_OPE_CLIENT_CRT")"
    else
       NODE_TYPE=peer
       NODE_MSP_CRT="$CERTS_PATH/$(basename "$PEER_MSP_CRT")"
       NODE_MSP_KEY="$CERTS_PATH/$(basename "$PEER_MSP_KEY")"
       NODE_TLS_KEY="$CERTS_PATH/$(basename "$PEER_TLS_KEY")"
       NODE_TLS_CRT="$CERTS_PATH/$(basename "$PEER_TLS_CRT")"
       NODE_TLS_CLIENT_KEY="$CERTS_PATH/$(basename "$PEER_TLS_CLIENT_KEY")"
       NODE_TLS_CLIENT_CRT="$CERTS_PATH/$(basename "$PEER_TLS_CLIENT_CRT")"
       NODE_OPE_CLIENT_KEY="$CERTS_PATH/$(basename "$PEER_OPE_CLIENT_KEY")"
       NODE_OPE_CLIENT_CRT="$CERTS_PATH/$(basename "$PEER_OPE_CLIENT_CRT")"
    fi
   
    # Estructura TLS 
    for d in tlscacerts tlsintermediatecerts signcerts keystore crls cacerts intermediatecerts admincerts; do
        rm -f ./crypto-config/msp/"$d"/*
        rm -f ./crypto-config/admin/msp/"$d"/*
    done
    rm -f ./crypto-config/tls/*
    rm -f ./crypto-config/operations/*
    rm -f ./crypto-config/{orderer,admin}/tls/*

    cp "$NODE_MSP_CRT"            ./crypto-config/msp/signcerts
    cp "$NODE_MSP_KEY"            ./crypto-config/msp/keystore
    cp "$root_certs"              ./crypto-config/msp/cacerts
    cp "$tls_root_certs"          ./crypto-config/msp/tlscacerts
    cp "$intermediate_certs"      ./crypto-config/msp/intermediatecerts
    cp "$tls_intermediate_certs"  ./crypto-config/msp/tlsintermediatecerts
    cp "$tls_intermediate_certs"  ./crypto-config/orderer/tls/ca.crt 

    # TLS    
    cp "$NODE_TLS_CRT"           "./crypto-config/tls/${NODE_TYPE}-tls-server.crt"
    cp "$NODE_TLS_KEY"           "./crypto-config/tls/${NODE_TYPE}-tls-server.key"
    cp "$NODE_TLS_CLIENT_CRT"    "./crypto-config/tls/${NODE_TYPE}-tls-client.crt"
    cp "$NODE_TLS_CLIENT_KEY"    "./crypto-config/tls/${NODE_TYPE}-tls-client.key"
    cp "$tls_intermediate_certs"  ./crypto-config/tls/ca.crt 

    # OPERATIONS
    # Para operation server reusa los certificados de TLS del server
    #
    cp "$NODE_OPE_CLIENT_KEY"    "./crypto-config/operations/${NODE_TYPE}-ope-client.key"
    cp "$NODE_OPE_CLIENT_CRT"    "./crypto-config/operations/${NODE_TYPE}-ope-client.crt"
    cp "$ope_intermediate_certs"  ./crypto-config/operations/ca.crt

    # Estructura criptografica del admin del peer
    cp "$ADMIN_MSP_CRT"          ./crypto-config/admin/msp/signcerts
    cp "$ADMIN_MSP_KEY"          ./crypto-config/admin/msp/keystore
    cp "$ADMIN_MSP_CRT"          ./crypto-config/admin/msp/admincerts
    cp "$root_certs"             ./crypto-config/admin/msp/cacerts
    cp "$tls_root_certs"         ./crypto-config/admin/msp/tlscacerts
    cp "$intermediate_certs"     ./crypto-config/admin/msp/intermediatecerts
    cp "$tls_intermediate_certs" ./crypto-config/admin/msp/tlsintermediatecerts

    # TLS del admin para el cli 
    cp "$ADMIN_TLS_CRT"          ./crypto-config/admin/tls/client.crt
    cp "$ADMIN_TLS_KEY"          ./crypto-config/admin/tls/client.key
    cp "$tls_intermediate_certs" ./crypto-config/admin/tls/ca.crt 

    popd 
done
}

function replace_genesis_block() {
echo "Replacing genesis_block ..."

pushd "$BASE/../../prod/fabric-instance/XXX-peer0"

local GENESIS_BLOCK="$(mktemp2 genesis.block)"

./ch.fetch.block.sh config -c ordererchannel -u "$GENESIS_BLOCK"

cp --backup=numbered "$GENESIS_BLOCK" "$BASE/../../prod/fabric-instance/XXX-orderer0/crypto-config/genesis.block"

popd
}

inicialize

echo_running

load_new_cacerts

restart_network && invoke_cc

add_new_cacerts

invoke_cc

restart_network && invoke_cc

stop_network

replace_crypto_material

restart_network && invoke_cc

set_new_cacerts

invoke_cc

restart_network && invoke_cc

replace_genesis_block

restart_network && invoke_cc

invoke_cc

stop_network

sudo date --set "next month"
date

start_network

invoke_cc

sudo date --set "1 month ago"
date

echo_success
