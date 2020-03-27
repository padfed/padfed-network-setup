#!/bin/bash
# configtx-msp-dir.packer.sh
# Genera un zip tgz con la estrcutura

set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname $0)"
. "$BASE/lib.sh"

echo_running

readonly nbn="$1"

make_configtx_yaml() {

   local output_configtx_yaml="$1"
   local CONFIGTX_MSP_DIR="." # indica que el configtx.yaml esta en el mismo directorio msp
   local SEP="." && [[ -v NODE_NAMESEP && $NODE_NAMESEP == "-" ]] && SEP="-"
   local ANCHOR_PEER_NAME=${ANCHOR_PEER_NAME:-${NODE_BASENAME}${SEP}${DOMAIN}}   
   local ANCHOR_PEER_PORT=${PEER_PORT:-7051}

   readonly READERS_RULE="\"OR('${MSPID}.admin', '${MSPID}.client', '${MSPID}.peer')\""
   readonly WRITERS_RULE="$READERS_RULE"
   readonly ADMINS_RULE="\"OR('${MSPID}.admin')\""

    cat <<< "# Generado por $THIS
Organizations:
- &${MSPID}
    Name: ${MSPID}
    ID: ${MSPID}
    MSPDir: ${CONFIGTX_MSP_DIR}
    Policies:
        Readers:
            Type: Signature
            Rule: ${READERS_RULE}
        Writers:
            Type: Signature
            Rule: ${WRITERS_RULE}
        Admins:
            Type: Signature
            Rule: ${ADMINS_RULE}
    AnchorPeers:
        - Host: ${ANCHOR_PEER_NAME}
          Port: ${ANCHOR_PEER_PORT}
" > "$output_configtx_yaml"
}

function check_crypto_config_msp_dir_crts() {
   
   echo "Checking crts in $PEER_MSP_DIR/{cacerts,intermediatecerts,tlscacerts,tlsintermediatecerts} ..."

   for subdir in cacerts intermediatecerts tlscacerts tlsintermediatecerts; do
       local dir="$PEER_MSP_DIR/$subdir"
       local found="false"
       if [[ -d $dir ]]; then
          for file in "$dir"/*; do
              if ! ( is_x509_crt $file ); then
                 echo_red "ERROR: file [$file] must by a X509 cert"
                 exit 1
              fi 
              found="true"
          done
       fi
       if [[ $found == "false" ]]; then
          case $subdir in
          cacerts | tlscacerts ) 
          echo_red "ERROR: x509 crts not found on [$dir]";
          exit 1;
          esac
       fi
   done
   echo "crts found" 
}

function make_zip() {
    
    local target_dir="${MSPID}-configtx-msp-dir" && mkdir -p "$target_dir"

    local tmp_dir="${target_dir}-tmp" && rm -rf "$tmp_dir"

    mkdir -p "$tmp_dir/msp/"

    make_configtx_yaml "$tmp_dir/msp/configtx.yaml"
    check_file         "$tmp_dir/msp/configtx.yaml"

    cp "$PEER_MSP_DIR/config.yaml" "$tmp_dir/msp/config.yaml"
    check_file "$tmp_dir/msp/config.yaml"

    cp -Rp "$PEER_MSP_DIR/"{admincerts,cacerts,intermediatecerts,tlscacerts,tlsintermediatecerts} "$tmp_dir/msp"
  
    local tgz_file="${target_dir}/${target_dir}".$(date +%Y%m%d%H%M%S).tar.xz
    tar --create --gzip --file="$tgz_file" "$tmp_dir" 
    rm -rf "$tmp_dir"

    check_file "$tgz_file"

    echo "tgz [$tgz_file] created"
}

##########################################

# Este script genera un tar.xz conteniendo la siguiente estructura
#
# ${MSPID}-configtx-msp-dir
# |_ msp
#    |_ admincerts
#    |_ cacerts
#    |  |_ xxxxxx.crt
#    |_ intermediatecerts
#    |  |_ xxxxxx.crt
#    |_ tlscacerts
#    |  |_ xxxxxx.crt
#    |_ tlsintermediatecerts
#    |  |_ xxxxxx.crt
#    |_ config.yaml
#    |_ configtx.yaml
#

readonly SETUP_CONF="setup.conf" && check_file "$SETUP_CONF" && source "$SETUP_CONF"

check_env FABRIC_INSTANCE_PATH 
check_env MSPID 

readonly PEER_DIR="$FABRIC_INSTANCE_PATH/$MSPID-$nbn"

[[ -r "$PEER_DIR/.env" ]] && source "$PEER_DIR/.env"

# Intenta obtener los certs desde una fabric-instance
readonly PEER_MSP_DIR="$FABRIC_INSTANCE_PATH/$MSPID-$NODE_BASENAME/crypto-config/msp"

check_crypto_config_msp_dir_crts

check_file "$PEER_MSP_DIR/config.yaml"

make_zip

echo_success
