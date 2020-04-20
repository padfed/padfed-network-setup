#!/bin/bash

set -Eeuo pipefail
#set -x

# Initialize
readonly BASE="$(dirname "$0")"

# Import lib.sh
. "scripts/lib.sh"

echo_running

function end2end() {

    show_config

    check_env FABRIC_INSTANCE_PATH
    check_env FABRIC_LEDGER_STORE_PATH

    clean

    setup_crypto_end2end

    node_init

    node_test
}

function setup_crypto_end2end() {

    check_env FABRIC_INSTANCE_PATH

    setup_cas

    make_requests "$NODE_BASENAME"

    cas_process_requests

    node_crypto_index
}

function setup_cas() {

    # Crea CAs para MSP, TLS y OPE
    "scripts/cas.create.sh"
}

function make_requests() {

    local NODE_BASENAME_OR_CLIENTS="$1"

    # Check env variables
    check_env CRYPTO_STAGE_PATH

    warn_backup_rm "$CRYPTO_STAGE_PATH/$MSPID-$NODE_BASENAME_OR_CLIENTS"

    "scripts/node.crypto.make.requests.sh" "$NODE_BASENAME_OR_CLIENTS"
}

function cas_process_requests() {
    local REQUESTS_PATH=""
    [[ "$#" == 1 ]] && REQUESTS_PATH="$(dirname "$1")/$(basename "$1")"

    if [[ ! -v CAS_INSTANCES_PATH || ! -d $CAS_INSTANCES_PATH/$MSPID ]]; then
       echo_red "ERROR: Unconfigured CAs"
       exit 1
    fi
    if [[ ! -z $REQUESTS_PATH ]]; then
       if [[ ! -d $REQUESTS_PATH ]]; then
          echo_red "ERROR: p2 [$REQUESTS_PATH] must be a directory"
          exit 1
       fi
    elif [[ -v NODE_BASENAME && ! -z $NODE_BASENAME ]]; then
         REQUESTS_PATH="$MSPID-$NODE_BASENAME-crypto-requests"
         [[ ! -d $REQUESTS_PATH ]] && REQUESTS_PATH=""
    fi
    if [[ -z $REQUESTS_PATH ]]; then
       echo "Nothing to process ..."
       return 0
    fi
    "scripts/cas.process.requests.sh" "$REQUESTS_PATH"
}

node_crypto_index() {

    # Indexa material cryptografico
    "scripts/node.crypto.index.sh" "$NODE_BASENAME"
}

node_setup() {
    check_env CRYPTO_STAGE_PATH

    local INDEX_CONF="$CRYPTO_STAGE_PATH/$MSPID-$NODE_BASENAME/index.conf"

    [[ ! -s $INDEX_CONF ]] && node_crypto_index

    # Organiza setup
    "scripts/node.setup.sh" "$NODE_BASENAME"
}

node_init() {
    node_setup

    # Corre peer
    "scripts/node.up.sh" "$NODE_BASENAME"
}

function set_orderer_tlsca_crt() {
   readonly crt="$1"
   is_x509_crt "$crt" || { echo_red "ERROR: p3 [$crt] must be a crt"; exit 1; }
   "scripts/node.set.orderer_tlsca_crt.sh" "$NODE_BASENAME" "$crt"
}

node_test() {
   case $NODE_BASENAME in
   peer* ) "scripts/peer.test.sh" "$NODE_BASENAME" ;;
   esac
   node_health
}

node_health() {
   "scripts/health.check.sh" "$NODE_BASENAME"
}

function clean() {
   [[ -v CAS_INSTANCES_PATH ]] && warn_backup_rm "$CAS_INSTANCES_PATH/$MSPID"
   warn_backup_rm "$CRYPTO_STAGE_PATH"
   warn_backup_rm "$FABRIC_INSTANCE_PATH"
   warn_backup_rm "$FABRIC_LEDGER_STORE_PATH"

   for d in $( find ./ -maxdepth 1 -name "$MSPID"-*-crypto-admin -type d ); do
       warn_backup_rm "$d"
   done
   local cs="$(docker container ls -aq)"
   [[ ! -z $cs ]] && docker container stop $cs
   docker system prune
}

function usage() {
   echo "Usage: $0 option"
   echo
   echo "options:"
   echo " show_config : show config MSPID, DOMAIN, ..."
   echo " clean : backup and remove previous deploy"
   echo " cas : create cas"
   echo " cas_process_requests <dir>: process requests and make crt from [dir]"
   echo " make_requests <node> or clients: create requests (CSR)"
   echo " node_crypto_index <node>: indexa el material cryptográfico"
   echo " setup <node>: setup node (peerN or ordererN)"
   echo " init <node>: init node (peer or orderer)"
   echo " test <node>: test node + health"
   echo " health <node>: test operationes services (needs curl-7.54.0-3.fc27)"
   echo " set_orderer_tlsca_crt <node> <filename> : set ORDERER_TLSCA_CRT_FILENAME with filename"
   echo " extact_crt <chain pem filename> : extacts crt from chain"
   echo
   echo "test only:"
   echo " crypto_end2end <node>: cas + create_requests + process_requests (TEST ONLY)"
   echo " end2end <node>: cas + create_requests + process_requests + init + test"
   exit
}

function check_node() {
   readonly NODE_BASENAME=$1
   local opt=""
   [[ $# == 2 ]] && opt=" | $2"
   case $NODE_BASENAME in
   orderer* ) [[ $MSPID == "$ORDERER_ORG_MSPID" || ( $MSPID != "$ORDERER_ORG_MSPID" && $ORDERER_TYPE == etcdraft ) ]] || { echo_red "ERROR: p1 [$NODE_BASENAME] (only $ORDERER_ORG_MSPID or ORDERER_TYPE=etcdraft)"; usage; } ;;
   peer0 | peer1 ) ;;
   * ) echo_red "ERROR: p1 [$NODE_BASENAME] must be peer0 | peer1 | orderer* (only ${ORDERER_ORG_MSPID} or ORDERER_TYPE=etcdraft) $opt"
       usage
   esac
}

function show_config() {
   echo "FABRIC_VERSION [$FABRIC_VERSION]"
   echo "ENVIRONMENT [$ENVIRONMENT]"
   echo "MSPID [$MSPID]"
   echo "DOMAIN [$DOMAIN]"
   echo "CA_MODE [$CA_MODE]"

   echo ""
   echo "Configuración de generación de requests CSR:"
   echo "ADMINS_BASENAME [${ADMINS_BASENAME:-}]"
   echo "USERS_BASENAME [${USERS_BASENAME:-}]"
   echo "OPERS_BASENAME [${OPERS_BASENAME:-}]"
   echo "ALL_PEERS_BASENAMES [${ALL_PEERS_BASENAMES:-}]"
   echo "CRT_DN_C [${CRT_DN_C:="AR"}]"
   echo "CRT_DN_O [${CRT_DN_O:=$DOMAIN}]"
   echo "CRT_DN_OU_MSP [${CRT_DN_OU_MSP:="none"}]"
   echo "CRT_DN_OU_TLS [${CRT_DN_OU_TLS:="TLS"}]"
   echo "CRT_DN_OU_OPE [${CRT_DN_OU_OPE:="OPE"}]"
   echo "CRT_DN_CN_SUFFIX [${CRT_DN_CN_SUFFIX:-}]"

   echo ""
   echo "Configuración de nombres de CAs:"
   echo "ROOTCA_FILENAME [${ROOTCA_FILENAME:-}]"
   echo "COMMON_ICA_CRT_FILENAME [${COMMON_ICA_CRT_FILENAME:-}]"
   echo "MSP_CA_CRT_FILENAME [${MSP_CA_CRT_FILENAME:-}]"
   echo "TLS_CA_CRT_FILENAME [${TLS_CA_CRT_FILENAME:-}]"
   echo "OPE_CA_CRT_FILENAME [${OPE_CA_CRT_FILENAME:-}]"

   echo ""
   echo "Directorio temporal para trabajar con el material criptográfico:"
   echo "CRYPTO_STAGE_PATH [${CRYPTO_STAGE_PATH:-}]"

   echo ""
   echo "Operations"
   echo "OPERATIONS_ENABLE [${OPERATIONS_ENABLE:-}]"

   if [[ -v CAS_INSTANCES_PATH ]]; then
      echo ""
      echo "Directorio para creación de CAs:"
      echo "CAS_INSTANCES_PATH [$CAS_INSTANCES_PATH]"
   fi
}

function extract_crt() {
   "scripts/crt.extract.sh" "$1"
}

############################################################

# Check args
case "$#" in
1 ) readonly ARG2="" ;;
2 ) readonly ARG2="$2"; ARG3="" ;;
3 ) readonly ARG2="$2"; ARG3="$3" ;;
* ) echo_red "ERROR: $# unexpected number of params"
    usage
esac

readonly SETUP_CONF="setup.conf" && check_file "$SETUP_CONF" && source "$SETUP_CONF"

check_env MSPID
check_env DOMAIN
check_env CA_MODE

readonly RUNMODE="${1,,}"

case "$RUNMODE" in
clean ) clean
   ;;
conf | config | show_config )
   show_config
   ;;
cas ) [[ "$#" != 1 ]] && { echo_red "ERROR: $# unexpected number of params"; usage; }
   setup_cas
   ;;
make_requests )
   [[ $ARG2 == "clients" ]] || check_node "$ARG2" "clients"
   make_requests "$ARG2"
   ;;
process_requests | cas_process_requests )
   [[ ! -d $ARG2 ]] && { echo_red "ERROR: p2 [$ARG2] must be a directory"; usage; }
   cas_process_requests "$ARG2"
   ;;
index | crypto_index | node_crypto_index )
   check_node "$ARG2"
   node_crypto_index
   ;;
crypto_end2end )
   check_node "$ARG2"
   setup_crypto_end2end
   ;;
setup )
   check_node "$ARG2"
   node_setup
   ;;
init )
   check_node "$ARG2"
   node_init
   ;;
test )
   check_node "$ARG2"
   node_test
   ;;
health )
   check_node  "$ARG2"
   node_health
   ;;
orderer_tlsca_crt | set_orderer_tlsca_crt )
   check_node "$ARG2"
   set_orderer_tlsca_crt "$ARG3"
   ;;
end2end )
   check_node "$ARG2"
   end2end
   ;;
extract_crt | extract_crts )
   [[ ! -s $ARG2 && ! -d $ARG2 ]] && { echo_red "ERROR: p2 [$ARG2] must be a chain pem file or directory"; usage; }
   extract_crt "$ARG2"
   ;;
*) echo_red "ERROR: p1 [$1] invalid"
   usage
   ;;
esac

echo_success "$RUNMODE - $MSPID"
