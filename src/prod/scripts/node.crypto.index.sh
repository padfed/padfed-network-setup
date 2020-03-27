#!/bin/bash
# peer.crypto.index.sh

set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname $0)"
. "$BASE/lib.sh"

echo_running

[[ ! -v SETUP_CONF ]] && readonly SETUP_CONF="setup.conf" && check_file "$SETUP_CONF" && source "$SETUP_CONF"

# Check env variables
check_env MSPID
check_env DOMAIN 
check_env CRYPTO_STAGE_PATH

readonly NODE_BASENAME="$1"

[[ ! -v OPERATIONS_ENABLE ]] && readonly OPERATIONS_ENABLE="false" 

function print_name_when_file {
    local file="$1"
    [[ -r $file ]] && { echo "$file"; return 0; } 
    echo "" # not file
}

function print_name_when_crt {
    local file="$1"
    is_x509_crt "$file" && { echo "$file"; return 0; } 
    echo "" # not cert
}

function look_for_ADMIN_FILES() {
   ADMIN_MSP_KEY=$( print_name_when_file ${1}-msp-client.key )
   [[ ! -r $ADMIN_MSP_KEY ]] && return 0

   ADMIN_MSP_CRT=$( print_name_when_crt  ${1}-msp-client.crt )
   ADMIN_TLS_KEY=$( print_name_when_file ${1}-tls-client.key )
   ADMIN_TLS_CRT=$( print_name_when_crt  ${1}-tls-client.crt )

   [[ ! -r $ADMIN_MSP_CRT ]] && { echo_red "ADMIN_MSP_CRT not found"; exit 1; }
   [[ ! -r $ADMIN_TLS_KEY ]] && { echo_red "ADMIN_TLS_KEY not found"; exit 1; }
   [[ ! -r $ADMIN_TLS_CRT ]] && { echo_red "ADMIN_TLS_CRT not found"; exit 1; }

   echo "ADMIN_MSP_KEY [$ADMIN_MSP_KEY] found"
   echo "ADMIN_MSP_CRT [$ADMIN_MSP_KEY] found"
   echo "ADMIN_TLS_KEY [$ADMIN_TLS_KEY] found"
   echo "ADMIN_TLS_CRT [$ADMIN_TLS_CRT] found"    
}

readonly CRYPTO_STAGE_MSPID_PATH="$CRYPTO_STAGE_PATH/$MSPID-$NODE_BASENAME"

if [[ ! -d $CRYPTO_STAGE_MSPID_PATH ]]; then
   echo_red "[$CRYPTO_STAGE_MSPID_PATH] dir not found"
   echo_red "you must first execute the option peer_make_requests, then gets crt"
   exit 1
fi

readonly   CACERTS_PATH="$CRYPTO_STAGE_MSPID_PATH"/cacerts
mkdir -p "$CACERTS_PATH"

CACERTS_FOUND="false"

if [[ $CA_MODE == "ROOTCAS" ]]; then
   readonly CACERTS_FILENAMES="$MSP_CA_CRT_FILENAME $TLS_CA_CRT_FILENAME $OPE_CA_CRT_FILENAME"
else
   readonly CACERTS_FILENAMES="$MSP_CA_CRT_FILENAME $TLS_CA_CRT_FILENAME $OPE_CA_CRT_FILENAME $ROOTCA_FILENAME $COMMON_ICA_CRT_FILENAME"
fi

echo "CACERTS_FILENAMES [$CACERTS_FILENAMES]"

readonly CRTS_PATH="$MSPID-$NODE_BASENAME-crypto-requests-crts"
if [[ -d $CRTS_PATH ]]; then
   echo "Searching *.crt in [$CRTS_PATH] ..."
   for f in $( find $CRTS_PATH -maxdepth 1 -name '*.crt' ); do
       cp -v "$f" "$CRYPTO_STAGE_MSPID_PATH/" 
   done
   if [[ -d $CRTS_PATH/cacerts ]]; then
      echo "Searching CACERTS in [$CRTS_PATH/cacerts] ..."
      for c in $CACERTS_FILENAMES; do
          if [[ -s  $CRTS_PATH/cacerts/$c ]]; then
             cp -v "$CRTS_PATH/cacerts/$c" "$CACERTS_PATH/" 
             CACERTS_FOUND="true"
          fi 
      done
   fi
fi
if [[ $CACERTS_FOUND == "false" && -d $PWD/resources ]]; then
   echo "Searching CACERTS in [$PWD/resources] ..."
   for c in $CACERTS_FILENAMES; do
       for f in $( find "$PWD/resources" -name $c ); do
           cp -v "$f" "$CACERTS_PATH/"
           CACERTS_FOUND="true"
       done
   done
fi

echo "Indexing CAS crypto-materials ..."
if [[ $CA_MODE == "ROOTCAS" ]]; then
   echo "Indexing ROOTCAS crts ..."
   readonly MSP_CA_CRT=$( print_name_when_crt "$CACERTS_PATH/$MSP_CA_CRT_FILENAME" )
   readonly TLS_CA_CRT=$( print_name_when_crt "$CACERTS_PATH/$TLS_CA_CRT_FILENAME" )
   readonly OPE_CA_CRT=$( print_name_when_crt "$CACERTS_PATH/$OPE_CA_CRT_FILENAME" )
else
   echo "Indexing ROOTCA and INTERMEDIATECAS crts ..."
   readonly ROOTCA_CRT=$( print_name_when_crt "$CACERTS_PATH/$ROOTCA_FILENAME" )
   [[ -r $ROOTCA_CRT ]] && echo "Unique ROOTCA_CRT found !"
   readonly MSP_CA_CRT="$ROOTCA_CRT"
   readonly TLS_CA_CRT="$ROOTCA_CRT"
   readonly OPE_CA_CRT="$ROOTCA_CRT"
   # Intermedite cas
   readonly COMMON_ICA_CRT=$( print_name_when_crt "$CACERTS_PATH/$COMMON_ICA_CRT_FILENAME" )
   readonly MSP_ICA_CRT=$( print_name_when_crt    "$CACERTS_PATH/$MSP_CA_CRT_FILENAME" )
   readonly TLS_ICA_CRT=$( print_name_when_crt    "$CACERTS_PATH/$TLS_CA_CRT_FILENAME" )
   readonly OPE_ICA_CRT=$( print_name_when_crt    "$CACERTS_PATH/$OPE_CA_CRT_FILENAME" )
fi

[[ -r $MSP_CA_CRT  ]] && echo "MSP_CA_CRT found !"
[[ -r $TLS_CA_CRT  ]] && echo "TLS_CA_CRT found !"
[[ -r $OPE_CA_CRT  ]] && echo "OPE_CA_CRT found !"
[[ -r $COMMON_ICA_CRT  ]] && echo "COMMON_ICA_CRT found !"
[[ -r $MSP_ICA_CRT ]] && echo "MSP_ICA_CRT found !"
[[ -r $TLS_ICA_CRT ]] && echo "TLS_ICA_CRT found !"
[[ -r $OPE_ICA_CRT ]] && echo "OPE_ICA_CRT found !"

# Material criptografico del Admin de la Org
echo "Searching ADMIN crypto-materials ..."
look_for_ADMIN_FILES "$CRYPTO_STAGE_MSPID_PATH/admin1@$DOMAIN"

if [[ -z $ADMIN_MSP_KEY ]]; then 
   echo "Searching ADMIN crypto-materials in [$MSPID-*-crypto-admin] ..."
   for d in $( find ./ -maxdepth 1 -name "$MSPID-*-crypto-admin" -type d ); do
       echo "ADMIN crypto-material recovered from $d ..."
       for f in $( find "$d" -type f ); do
           cp  "$f" "$CRYPTO_STAGE_MSPID_PATH"
       done
       look_for_ADMIN_FILES "$CRYPTO_STAGE_MSPID_PATH/admin1@$DOMAIN"
       break
   done
fi

[[ ! -r $ADMIN_MSP_KEY ]] && { echo_red "ADMIN_MSP_KEY not found"; exit 1; }

ADMIN_1_MSP_KEY=$ADMIN_MSP_KEY
ADMIN_1_MSP_CRT=$ADMIN_MSP_CRT
ADMIN_1_TLS_KEY=$ADMIN_TLS_KEY
ADMIN_1_TLS_CRT=$ADMIN_TLS_CRT

echo "ADMIN_1_MSP_CRT [$ADMIN_1_MSP_CRT]"

SEP="." && [[ -v NODE_NAMESEP && "$NODE_NAMESEP" == "-" ]] && SEP="-"
readonly NODE_FILES="$CRYPTO_STAGE_MSPID_PATH/${NODE_BASENAME}${SEP}${DOMAIN}"

# Material criptografico del Node
echo "Processing NODE crypto-materials ..."
readonly NODE_MSP_KEY=${NODE_FILES}-msp-server.key && check_file            "$NODE_MSP_KEY"
readonly NODE_MSP_CRT=${NODE_FILES}-msp-server.crt && check_x509_crt        "$NODE_MSP_CRT"
readonly NODE_TLS_KEY=${NODE_FILES}-tls-server.key && check_file            "$NODE_TLS_KEY"
readonly NODE_TLS_CRT=${NODE_FILES}-tls-server.crt && check_x509_crt        "$NODE_TLS_CRT"
readonly NODE_TLS_CLIENT_KEY=${NODE_FILES}-tls-client.key && check_file     "$NODE_TLS_CLIENT_KEY"
readonly NODE_TLS_CLIENT_CRT=${NODE_FILES}-tls-client.crt && check_x509_crt "$NODE_TLS_CLIENT_CRT"

if [[ $OPERATIONS_ENABLE == "true" ]]; then
   readonly NODE_OPE_CLIENT_KEY=${NODE_FILES}-ope-client.key && check_file     "$NODE_OPE_CLIENT_KEY"
   readonly NODE_OPE_CLIENT_CRT=${NODE_FILES}-ope-client.crt && check_x509_crt "$NODE_OPE_CLIENT_CRT"
fi

readonly INDEX_CONF=$CRYPTO_STAGE_PATH/$MSPID-$NODE_BASENAME/index.conf

cat <<< "#########################################################
# Archivo generado por ${THIS}

# Certificados raices de las CAs de la propia Org: 
MSP_CA_CRT=${MSP_CA_CRT:-}
TLS_CA_CRT=${TLS_CA_CRT:-}
OPE_CA_CRT=${OPE_CA_CRT:-}
COMMON_ICA_CRT=${COMMON_ICA_CRT:-}
MSP_ICA_CRT=${MSP_ICA_CRT:-}
TLS_ICA_CRT=${TLS_ICA_CRT:-}
OPE_ICA_CRT=${OPE_ICA_CRT:-}

# Material criptografico del Admin de la Org:
ADMIN_1_MSP_KEY=${ADMIN_1_MSP_KEY:-}
ADMIN_1_MSP_CRT=${ADMIN_1_MSP_CRT:-}
ADMIN_1_TLS_KEY=${ADMIN_1_TLS_KEY:-}
ADMIN_1_TLS_CRT=${ADMIN_1_TLS_CRT:-}

# Material criptografico del $NODE_BASENAME:
NODE_MSP_KEY=${NODE_MSP_KEY}
NODE_MSP_CRT=${NODE_MSP_CRT}
NODE_TLS_KEY=${NODE_TLS_KEY}
NODE_TLS_CRT=${NODE_TLS_CRT}
NODE_TLS_CLIENT_KEY=${NODE_TLS_CLIENT_KEY}
NODE_TLS_CLIENT_CRT=${NODE_TLS_CLIENT_CRT}
NODE_OPE_CLIENT_KEY=${NODE_OPE_CLIENT_KEY:-}
NODE_OPE_CLIENT_CRT=${NODE_OPE_CLIENT_CRT:-}
" > "$INDEX_CONF"

check_file "$INDEX_CONF"

echo_success
