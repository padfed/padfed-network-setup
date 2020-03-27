#!/bin/bash
# Setup Peer

set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname "$0")"
. "$BASE/lib.sh"

echo_running

function set_env() {
   [[ ! -v SETUP_CONF ]] && readonly SETUP_CONF="setup.conf" && check_file "$SETUP_CONF" && source "$SETUP_CONF"
   
   # Defaults
   echo "ENVIRONMENT [${ENVIRONMENT:=prod}]"
   echo "TLS_ENABLED ${TLS_ENABLED:=true}]"
   echo "TLS_CLIENT_AUTH_REQUIRED [${TLS_CLIENT_AUTH_REQUIRED:=true}]"
   echo "LOG_LEVEL [${LOG_LEVEL:=info}]"
   echo "CHANNEL_NAME [${CHANNEL_NAME:="padfedchannel"}]"
   echo "NETWORK_NAME [${NETWORK_NAME:="padfednetwork"}]"
   echo "DOCKER_NETWORK_NAME [${DOCKER_NETWORK_NAME:=padfed}]"
   echo "CHAINCODE_NAME [${CHAINCODE_NAME:="padfedcc"}]"
   echo "CHAINCODE_PATH [${CHAINCODE_PATH:="gitlab.cloudint.afip.gob.ar\/blockchain-team\/padfed-chaincode.git"}]"
   echo "CHAINCODE_ENDORSMENT [${CHAINCODE_ENDORSMENT:="OR('AFIP.peer','COMARB.peer','ARBA.peer','CBA.peer')"}]"
   echo "CHAINCODE_REPO_URL [${CHAINCODE_REPO_URL:="https:\/\/nexus.cloudint.afip.gob.ar\/nexus\/repository\/padfed-bc-raw"}]"
   echo "ORDERER_TYPE [${ORDERER_TYPE:=solo}]"

   # Check env variables
   
   check_env DOMAIN 
   check_env FABRIC_INSTANCE_PATH
   check_env FABRIC_LEDGER_STORE_PATH
   check_env CRYPTO_STAGE_PATH
   check_env FABRIC_VERSION
   
   [[ ! -v PEER_PORT ]]         && readonly PEER_PORT=7051 # Defaul port
   [[ ! -v ORDERER_PORT ]]      && readonly ORDERER_PORT=7050 
   [[ ! -v OPERATIONS_ENABLE ]] && readonly OPERATIONS_ENABLE="false"
   [[ ! -v OPERATIONS_PORT ]]   && readonly OPERATIONS_PORT=9443
   
   local SEP="." && [[ -v NODE_NAMESEP && "$NODE_NAMESEP" == "-" ]] && SEP="-"
   readonly NODE_NAME=${NODE_BASENAME}${SEP}$DOMAIN

   case "$NODE_BASENAME" in
   peer* )    readonly NODE_TYPE="peer" ;;
   orderer* ) readonly NODE_TYPE="orderer" ;;
   esac
   
   # From index.conf
   
   readonly INDEX_CONF="$CRYPTO_STAGE_PATH/$MSPID-$NODE_BASENAME/index.conf"
   check_file "$INDEX_CONF" && source "$INDEX_CONF"
   
   [[ -z ${MSP_CA_CRT:=""} || ! -r $MSP_CA_CRT ]] && { echo_red "MSP_CA_CRT [${MSP_CA_CRT:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
   [[ -z ${TLS_CA_CRT:=""} || ! -r $TLS_CA_CRT ]] && { echo_red "TLS_CA_CRT [${TLS_CA_CRT:-}] not indexed in [$INDEX_CONF]"; exit 1; } 

   # Optional itermediatecas
   [[ -z ${MSP_ICA_CRT:=""} ]] || check_x509_crt "$MSP_ICA_CRT" 
   [[ -z ${TLS_ICA_CRT:=""} ]] || check_x509_crt "$TLS_ICA_CRT"

   if [[ $OPERATIONS_ENABLE == "true" ]]; then
      [[ -z ${OPE_ICA_CRT:=""}  ]] || check_x509_crt "$OPE_ICA_CRT"
      [[ -z ${NODE_OPE_CRT:=""} ]] || check_x509_crt "$NODE_OPE_CRT"  
   fi

   [[ -z ${ADMIN_1_MSP_KEY:=""} || ! -r $ADMIN_1_MSP_KEY ]] && { echo_red "ADMIN_1_MSP_KEY [${ADMIN_1_MSP_KEY:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
   [[ -z ${ADMIN_1_MSP_CRT:=""} || ! -r $ADMIN_1_MSP_CRT ]] && { echo_red "ADMIN_1_MSP_CRT [${ADMIN_1_MSP_CRT:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
   [[ -z ${ADMIN_1_TLS_KEY:=""} || ! -r $ADMIN_1_TLS_KEY ]] && { echo_red "ADMIN_1_TLS_KEY [${ADMIN_1_TLS_KEY:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
   [[ -z ${ADMIN_1_TLS_CRT:=""} || ! -r $ADMIN_1_TLS_CRT ]] && { echo_red "ADMIN_1_TLS_CRT [${ADMIN_1_TLS_CRT:-}] not indexed in [$INDEX_CONF]"; exit 1; } 

   [[ -z ${NODE_MSP_KEY:=""} || ! -r $NODE_MSP_KEY ]] && { echo_red "NODE_MSP_KEY [${NODE_MSP_KEY:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
   [[ -z ${NODE_MSP_CRT:=""} || ! -r $NODE_MSP_CRT ]] && { echo_red "NODE_MSP_CRT [${NODE_MSP_CRT:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
   [[ -z ${NODE_TLS_KEY:=""} || ! -r $NODE_TLS_KEY ]] && { echo_red "NODE_TLS_KEY [${NODE_TLS_KEY:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
   [[ -z ${NODE_TLS_CRT:=""} || ! -r $NODE_TLS_CRT ]] && { echo_red "NODE_TLS_CRT [${NODE_TLS_CRT:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
  
   [[ -z ${NODE_TLS_CLIENT_KEY:=""} || ! -r $NODE_TLS_CLIENT_KEY ]] && { echo_red "NODE_TLS_CLIENT_KEY [${NODE_TLS_CLIENT_KEY:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
   [[ -z ${NODE_TLS_CLIENT_CRT:=""} || ! -r $NODE_TLS_CLIENT_CRT ]] && { echo_red "NODE_TLS_CLIENT_CRT [${NODE_TLS_CLIENT_CRT:-}] not indexed in [$INDEX_CONF]"; exit 1; } 
  
   # From config
   readonly     DOCKER_COMPOSE_TEMPLATE_YAML="config/$NODE_TYPE.docker-compose.template.yaml"
   check_file "$DOCKER_COMPOSE_TEMPLATE_YAML"
   
   readonly     CONFIGTX_TEMPLATE_YAML="config/configtx.template.yaml"
   check_file "$CONFIGTX_TEMPLATE_YAML"
   
   local SEP="." && [[ -v NODE_NAMESEP && "$NODE_NAMESEP" == "-" ]] && SEP="-"
   readonly ANCHOR_PEER_NAME="peer0${SEP}$DOMAIN"
}

function set_ORDERER_TLSCA_CRT_FILENAME() {
   echo "About set ORDERER_TLSCA_CRT_FILENAME ..."

   if [[ -v ORDERER_TLSCA_CRT_FILENAME ]]; then
      local f="config/$ORDERER_TLSCA_CRT_FILENAME"
      echo "About check crt [$f] ..."
      if ( is_x509_crt "$f" ); then 
         cp -v "$f" "$PEER_CRYPTO_CONFIG/orderer/tls/$ORDERER_TLSCA_CRT_FILENAME"
         return 0
      fi
      echo "checking crt [$f] fail"
   fi
   # assumes that ${ORDERER_ORG_MSPID} is running the orderer,
   # then the cert of its tlsca is also that of the orderer

   [[ $MSPID == "${ORDERER_ORG_MSPID}" ]] || return 0 # on ${ORDERER_ORG_MSPID} peers only

   if [[ -z "$TLS_ICA_CRT" ]]; then
      cp -v "$TLS_CA_CRT"  "$PEER_CRYPTO_CONFIG/orderer/tls/ca.crt" 
   elif [[ ! -z "$COMMON_ICA_CRT" ]]; then
        cp  "$TLS_ICA_CRT" "$PEER_CRYPTO_CONFIG/orderer/tls/ca.crt"
        cat "$TLS_ICA_CRT" "$COMMON_ICA_CRT" "$TLS_CA_CRT" > "$PEER_CRYPTO_CONFIG/orderer/tls/ca-chain.crt" 
   else
      cp  -v "$TLS_ICA_CRT" "$PEER_CRYPTO_CONFIG/orderer/tls/ca.crt"
      cat -v "$TLS_ICA_CRT" "$TLS_CA_CRT" > "$PEER_CRYPTO_CONFIG/orderer/tls/ca-chain.crt" 
   fi
   ORDERER_TLSCA_CRT_FILENAME="ca.crt"
}

function make_crypto_config() {
################################################
#
# ./fabric-instance
#       [MSPID]-[peer[n]|orderer[n]]
#            crypto-config
#                msp (para el peer|orderer)
#                    tlscacerts
#                    tlsintermediatecerts
#                    singcerts
#                    keystore
#                    cacerts
#                    intermediatecerts
#                    admincerts
#                    config.yaml (file)
#                tls (para el peer|orderer)
#                    [peer|orderer]-tls-server.crt
#                    [peer|orderer]-tls-server.key
#                    [peer|orderer]-tls-client.crt
#                    [peer|orderer]-tls-client.key
#                    ca.key
#                admin (para el cli)
#                    msp
#                        tlscacerts
#                        tlsintermediatecerts
#                        singcerts
#                        keystore
#                        cacerts
#                        intermediatecerts
#                        admincerts
#                    tls
#                        client.crt
#                        client.key
#                        ca.key
#                operations
#                    [peer|orderer]-ope-client.crt
#                    [peer|orderer]-ope-client.key
#                    ca.key
#                orderer (para el cli y raft)
#                     tls 
#                        xxxxx (nombre en .env ORDERER_TLSCA_CRT_FILENAME)
#
################################################
   
   echo "About make crypto-config struct ..."

   mkdir -p "$PEER_CRYPTO_CONFIG"/{msp,tls,admin,operations,orderer/tls}
   mkdir -p "$PEER_CRYPTO_CONFIG/msp/"{tlscacerts,tlsintermediatecerts,signcerts,keystore,crls,cacerts,intermediatecerts,admincerts}

   cp "$NODE_MSP_CRT"    "$PEER_CRYPTO_CONFIG/msp/signcerts"
   cp "$NODE_MSP_KEY"    "$PEER_CRYPTO_CONFIG/msp/keystore"
   cp "$MSP_CA_CRT"      "$PEER_CRYPTO_CONFIG/msp/cacerts"
   cp "$TLS_CA_CRT"      "$PEER_CRYPTO_CONFIG/msp/tlscacerts"
  
   if [[ ! -z "$COMMON_ICA_CRT" ]]; then
      cp "$COMMON_ICA_CRT" "$PEER_CRYPTO_CONFIG/msp/intermediatecerts"
      cp "$COMMON_ICA_CRT" "$PEER_CRYPTO_CONFIG/msp/tlsintermediatecerts"
   fi

   [[ ! -z "$MSP_ICA_CRT" ]] && cp "$MSP_ICA_CRT" "$PEER_CRYPTO_CONFIG/msp/intermediatecerts"
   [[ ! -z "$TLS_ICA_CRT" ]] && cp "$TLS_ICA_CRT" "$PEER_CRYPTO_CONFIG/msp/tlsintermediatecerts"

   # config.yaml para NodeOUS en el raiz de la estructura MSP del peer
   
   readonly PEER_MSP_CONFIG_YAML="$PEER_CRYPTO_CONFIG/msp/config.yaml"
   if [[ -z "$MSP_ICA_CRT" ]]; then
      local crtpath="cacerts/$(basename "$MSP_CA_CRT")"
   else
      local crtpath="intermediatecerts/$(basename "$MSP_ICA_CRT")"
   fi   
   make_msp_config_yaml "$crtpath" \
                        "${CRT_DN_OU_MSP:=none}" \
                        "$PEER_MSP_CONFIG_YAML"
   
   check_file "$PEER_MSP_CONFIG_YAML"
  
   # TLS del peer   
   cp "$NODE_TLS_CRT"        "$PEER_CRYPTO_CONFIG/tls/${NODE_TYPE}-tls-server.crt"
   cp "$NODE_TLS_KEY"        "$PEER_CRYPTO_CONFIG/tls/${NODE_TYPE}-tls-server.key"
   cp "$NODE_TLS_CLIENT_CRT" "$PEER_CRYPTO_CONFIG/tls/${NODE_TYPE}-tls-client.crt"
   cp "$NODE_TLS_CLIENT_KEY" "$PEER_CRYPTO_CONFIG/tls/${NODE_TYPE}-tls-client.key"
   if [[ -z "$TLS_ICA_CRT" ]]; then 
      cp "$TLS_CA_CRT"  "$PEER_CRYPTO_CONFIG/tls/ca.crt" 
   elif [[ ! -z "$COMMON_ICA_CRT" ]]; then
        cp  "$TLS_ICA_CRT" "$PEER_CRYPTO_CONFIG/tls/ca.crt"
        cat "$TLS_ICA_CRT" "$COMMON_ICA_CRT" "$TLS_CA_CRT" > "$PEER_CRYPTO_CONFIG/tls/ca-chain.crt" 
   else
      cp  "$TLS_ICA_CRT" "$PEER_CRYPTO_CONFIG/tls/ca.crt"
      cat "$TLS_ICA_CRT" "$TLS_CA_CRT" > "$PEER_CRYPTO_CONFIG/tls/ca-chain.crt" 
   fi

   if [[ $OPERATIONS_ENABLE == "true" && ! -z $NODE_OPE_CLIENT_CRT ]]; then 
      # Para operation server reusa los certificados de TLS del server
      #
      cp "$NODE_OPE_CLIENT_KEY" "$PEER_CRYPTO_CONFIG/operations/${NODE_TYPE}-ope-client.key"
      cp "$NODE_OPE_CLIENT_CRT" "$PEER_CRYPTO_CONFIG/operations/${NODE_TYPE}-ope-client.crt"
      if [[ -z "$OPE_ICA_CRT" ]]; then
         cp  "$OPE_CA_CRT"  "$PEER_CRYPTO_CONFIG/operations/ca.crt"
      elif [[ ! -z "$COMMON_ICA_CRT" ]]; then
         cp  "$OPE_ICA_CRT" "$PEER_CRYPTO_CONFIG/operations/ca.crt"
         cat "$OPE_ICA_CRT" "$COMMON_ICA_CRT" "$OPE_CA_CRT" > "$PEER_CRYPTO_CONFIG/operations/ca-chain.crt" 
      else
         cp  "$OPE_ICA_CRT" "$PEER_CRYPTO_CONFIG/operations/ca.crt"
         cat "$OPE_ICA_CRT" "$OPE_CA_CRT" > "$PEER_CRYPTO_CONFIG/operations/ca-chain.crt" 
      fi
   fi
   # Estructura criptografica del admin del peer
   mkdir -p "$PEER_CRYPTO_CONFIG/admin/"{msp,tls}
   mkdir -p "$PEER_CRYPTO_CONFIG/admin/msp/"{tlscacerts,tlsintermediatecerts,signcerts,keystore,cacerts,intermediatecerts,admincerts}

   cp "$ADMIN_1_MSP_CRT" "$PEER_CRYPTO_CONFIG/admin/msp/signcerts"
   cp "$ADMIN_1_MSP_KEY" "$PEER_CRYPTO_CONFIG/admin/msp/keystore"
   cp "$ADMIN_1_MSP_CRT" "$PEER_CRYPTO_CONFIG/admin/msp/admincerts"
   cp "$MSP_CA_CRT"      "$PEER_CRYPTO_CONFIG/admin/msp/cacerts"
   cp "$TLS_CA_CRT"      "$PEER_CRYPTO_CONFIG/admin/msp/tlscacerts"

   [[ ! -z "$MSP_ICA_CRT" ]] && cp "$MSP_ICA_CRT" "$PEER_CRYPTO_CONFIG/admin/msp/intermediatecerts" 
   [[ ! -z "$TLS_ICA_CRT" ]] && cp "$TLS_ICA_CRT" "$PEER_CRYPTO_CONFIG/admin/msp/tlsintermediatecerts" 

   if [[ ! -z "$COMMON_ICA_CRT" ]]; then
      cp "$COMMON_ICA_CRT" "$PEER_CRYPTO_CONFIG/admin/msp/intermediatecerts"
      cp "$COMMON_ICA_CRT" "$PEER_CRYPTO_CONFIG/admin/msp/tlsintermediatecerts"
   fi

   # TLS del admin para el cli 
   cp "$ADMIN_1_TLS_CRT"  "$PEER_CRYPTO_CONFIG/admin/tls/client.crt"
   cp "$ADMIN_1_TLS_KEY"  "$PEER_CRYPTO_CONFIG/admin/tls/client.key"
   if [[ -z "$TLS_ICA_CRT" ]]; then 
      cp "$TLS_CA_CRT"  "$PEER_CRYPTO_CONFIG/admin/tls/ca.crt" 
   else
      cp  "$TLS_ICA_CRT" "$PEER_CRYPTO_CONFIG/admin/tls/ca.crt"
      cat "$TLS_ICA_CRT" "$TLS_CA_CRT" > "$PEER_CRYPTO_CONFIG/admin/tls/ca-chain.crt" 
   fi
}

function make_docker_compose() {
   echo "About make docker_composer.yaml ..."
   readonly DOKER_COMPOSE_YAML="$PEER_DIR/docker-compose.yaml"
   cp "$DOCKER_COMPOSE_TEMPLATE_YAML" "$DOKER_COMPOSE_YAML"
   replaceKeys "$DOKER_COMPOSE_YAML" NODE_NAME
   replaceKeys "$DOKER_COMPOSE_YAML" DOCKER_NETWORK_NAME
}

function set_CONFIGTXGEN() {
   echo "About set CONFIGTXGEN binary tool ..."
   [[ -v CONFIGTXGEN ]] && return 0
   [[ $(command -v configtxgen) ]] && { CONFIGTXGEN=$(command -v configtxgen); return 0; }
   CONFIGTXGEN="$FABRIC_BIN_PATH/configtxgen"
   [[ -x $(command -v "$CONFIGTXGEN") ]] || { "$FABRIC_BIN_PATH/get-fabric-binaries.sh" "$FABRIC_VERSION"; }
   check_exe "$CONFIGTXGEN"

   for f in cryptogen idemixgen orderer peer discover; do
       rm -f "$PWD/bin/$f"
   done
}

function set_CONFIGTX_YAML() {
   echo "About set configtx.yaml ..."
   [[ -v CONFIGTX_YAML ]] && return 0
   readonly CONFIGTX_YAML="$PEER_DIR/configtx.yaml"

   local CONFIGTX_YAML_CONTENT=$(< $CONFIGTX_TEMPLATE_YAML)
   CONFIGTX_YAML_CONTENT=${CONFIGTX_YAML_CONTENT//\{\{ORDERER_ORG_MSPID\}\}/$ORDERER_ORG_MSPID} # reemplaza N ocurrencias por linea
   CONFIGTX_YAML_CONTENT=${CONFIGTX_YAML_CONTENT//\{\{NODE_NAME\}\}/$NODE_NAME} 
   CONFIGTX_YAML_CONTENT=${CONFIGTX_YAML_CONTENT//\{\{ANCHOR_PEER_NAME\}\}/$ANCHOR_PEER_NAME} 
   CONFIGTX_YAML_CONTENT=${CONFIGTX_YAML_CONTENT//\{\{CHANNEL_NAME\}\}/$CHANNEL_NAME} 
   CONFIGTX_YAML_CONTENT=${CONFIGTX_YAML_CONTENT//\{\{CHANNEL_CONSORTIUM_NAME\}\}/$CHANNEL_CONSORTIUM_NAME} 
   CONFIGTX_YAML_CONTENT=${CONFIGTX_YAML_CONTENT//\{\{ORDERER_TYPE\}\}/$ORDERER_TYPE} 

   echo "$CONFIGTX_YAML_CONTENT" > "$CONFIGTX_YAML"
}

function make_genesis_block() {
   echo "About make genesis.block ..."
   set_CONFIGTXGEN
   set_CONFIGTX_YAML
   local of="$PEER_CRYPTO_CONFIG/genesis.block"
   "$CONFIGTXGEN" -configPath "$PEER_DIR" -profile OrdererGenesis -channelID ordererchannel -outputBlock "$of" -inspectBlock "$of" &> "$of.json"
   check_file "$of"
   echo "genesis.block [$of]"
}

function make_channel_create_tx() {
   echo "About make createchannel.tx ..."
   set_CONFIGTXGEN
   set_CONFIGTX_YAML
   local of="$PEER_CRYPTO_CONFIG/createchannel.tx"
   "$CONFIGTXGEN" -configPath "$PEER_DIR" -profile "$CHANNEL_NAME" -channelID "$CHANNEL_NAME" -outputCreateChannelTx "$of" -inspectChannelCreateTx "$of" &> "$of.json"
   check_file "$of"
   echo "createchannel.tx [$of]"
}

function make_anchor_peer_update_tx() {
   echo "About make anchorpeerupdate.tx ..."
   set_CONFIGTXGEN
   set_CONFIGTX_YAML
   local of="$PEER_CRYPTO_CONFIG/${MSPID}_anchorpeerupdate.tx"
   "$CONFIGTXGEN" -configPath "$PEER_DIR" -profile $CHANNEL_NAME -outputAnchorPeersUpdate "$of" -channelID "$CHANNEL_NAME" -asOrg "$MSPID"
   check_file "$of"
   echo "anchorpeerupdate.tx [$of]"
}

function make_docker_env() {
   echo "About make docker .env ..."
   local DOCKER_ENV="$1"

   local FABRIC_INSTANCE_REALPATH="$(realpath "$FABRIC_INSTANCE_PATH")"
   local FABRIC_LEDGER_STORE_REALPATH="$(realpath "$FABRIC_LEDGER_STORE_PATH")"
   
   cat <<< "#!/bin/bash
# 
# Generado por ${THIS}
#
" > "$DOCKER_ENV"

   check_file "$DOCKER_ENV"

   echo "ENVIRONMENT=$ENVIRONMENT" >> "$DOCKER_ENV"
   echo "TLS_ENABLED=$TLS_ENABLED" >> "$DOCKER_ENV"
   echo "TLS_CLIENT_AUTH_REQUIRED=$TLS_CLIENT_AUTH_REQUIRED" >> "$DOCKER_ENV" 
   echo "LOG_LEVEL=$LOG_LEVEL" >> "$DOCKER_ENV"

   echo "FABRIC_VERSION=$FABRIC_VERSION" >> "$DOCKER_ENV"
   echo "FABRIC_INSTANCE_PATH=$FABRIC_INSTANCE_REALPATH" >> "$DOCKER_ENV"
   echo "FABRIC_LEDGER_STORE_PATH=$FABRIC_LEDGER_STORE_REALPATH" >> "$DOCKER_ENV"
   echo "SYSTEM_CHANNEL_NAME=ordererchannel" >> "$DOCKER_ENV" 
   echo "CHANNEL_NAME=$CHANNEL_NAME" >> "$DOCKER_ENV" 
   echo "NETWORK_NAME=$NETWORK_NAME" >> "$DOCKER_ENV" 
   echo "MSPID=$MSPID" >> "$DOCKER_ENV"
   echo "DOMAIN=$DOMAIN" >> "$DOCKER_ENV"
   echo "NODE_NAME=$NODE_NAME" >> "$DOCKER_ENV"
   echo "NODE_BASENAME=$NODE_BASENAME" >> "$DOCKER_ENV"
   echo "ANCHOR_PEER_NAME=$ANCHOR_PEER_NAME" >> "$DOCKER_ENV"
   echo "ORDERER_PORT=$ORDERER_PORT" >> "$DOCKER_ENV"
   echo "OPERATIONS_ENABLE=$OPERATIONS_ENABLE" >> "$DOCKER_ENV"
   echo "OPERATIONS_PORT=${OPERATIONS_PORT:-}" >> "$DOCKER_ENV"
   
   if [[ $NODE_TYPE == "peer" ]]; then
      echo "PEER_PORT=$PEER_PORT" >> "$DOCKER_ENV"
      [[ -v ORDERER_NAME && ! -z $ORDERER_NAME ]] && echo "ORDERER_NAME=$ORDERER_NAME" >> "$DOCKER_ENV"
      [[ -v ORDERER_TLSCA_CRT_FILENAME && ! -z $ORDERER_TLSCA_CRT_FILENAME ]] && echo "ORDERER_TLSCA_CRT_FILENAME=$ORDERER_TLSCA_CRT_FILENAME" >> "$DOCKER_ENV"

      echo "CHAINCODE_NAME=$CHAINCODE_NAME"             >> "$DOCKER_ENV" 
      echo "CHAINCODE_PATH=$CHAINCODE_PATH"             >> "$DOCKER_ENV" 
      echo "CHAINCODE_ENDORSMENT=\"$CHAINCODE_ENDORSMENT\"" >> "$DOCKER_ENV" 
      echo "CHAINCODE_REPO_URL=$CHAINCODE_REPO_URL"     >> "$DOCKER_ENV" 
   fi
   echo "" >> "$DOCKER_ENV"
   echo "$DOCKER_ENV"
}

function copy_admin_scripts() {
   echo "About copy admin scripts and binaries ..."

   cp config/crypto.admin.export.sh "$PEER_DIR/"

   [[ $NODE_TYPE == "orderer" ]] && return 0

   if [[ $MSPID == "$ORDERER_ORG_MSPID" ]]; then
      cp config/cc.download.sh    "$PEER_DIR/"
      cp config/cc.instantiate.sh "$PEER_DIR/"
      cp config/cc.upgrade.sh     "$PEER_DIR/"
      cp config/cc.activate.sh    "$PEER_DIR/"
      cp config/cc.invoke.sh      "$PEER_DIR/"
      cp config/ch.create.sh      "$PEER_DIR/"
   fi

   cp config/ch.set.anchor.peer.sh "$PEER_DIR/"
   cp config/cc.query.sh          "$PEER_DIR/"
   cp config/cc.install.sh        "$PEER_DIR/"
   cp config/ch.join.sh           "$PEER_DIR/"
   cp config/ch.signconfig.sh     "$PEER_DIR/"

   cp ../common/lib.sh            "$PEER_DIR/"
   cp ../common/ch.config.tool.sh "$PEER_DIR/"
   cp ../common/ch.fetch.block.sh "$PEER_DIR/"
   cp ../common/ch.update.sh      "$PEER_DIR/"

   mkdir -p "$PEER_DIR/bin/"
   if [[ -v CONFIGTXGEN && -x $CONFIGTXGEN ]]; then
      cp "$CONFIGTXGEN"                            "$PEER_DIR/bin/"
      cp "$(dirname "$CONFIGTXGEN")/configtxlator" "$PEER_DIR/bin/"
   else
      for exe in configtxgen configtxlator; do
          [[ -x $FABRIC_BIN_PATH/$exe ]] && cp -f "$FABRIC_BIN_PATH/$exe" "$PEER_DIR/bin/"
      done
   fi
   return 0
}

function crypto_admin_export() {
   echo "About export admin crypto material ..."

   CRYPTO_ADMIN_DIR="$MSPID-$NODE_BASENAME-crypto-admin"

   backup_dir "$CRYPTO_ADMIN_DIR"
   rm -rf     "$CRYPTO_ADMIN_DIR"
   mkdir -p   "$CRYPTO_ADMIN_DIR"

   "$PEER_DIR/crypto.admin.export.sh" 
   
   cp -vrf "$PEER_DIR/$CRYPTO_ADMIN_DIR"/* "./$CRYPTO_ADMIN_DIR/"
}

###############################################################

readonly NODE_BASENAME="$1"

set_env

readonly FABRIC_BIN_PATH="$( realpath "../bin" )"
check_dir "$FABRIC_BIN_PATH"

readonly PEER_DIR="$FABRIC_INSTANCE_PATH/$MSPID-$NODE_BASENAME"
warn_backup_rm "$PEER_DIR" 

readonly STORAGE_DIR="$FABRIC_LEDGER_STORE_PATH/$MSPID-$NODE_BASENAME"
warn_backup_rm "$STORAGE_DIR" 

# Estructura compatible con la del proyecto qa

mkdir -p "$PEER_DIR/gopath/"{download,deploy,src}

# Estructura MSP para el peer

readonly PEER_CRYPTO_CONFIG="$PEER_DIR/crypto-config"

make_crypto_config 

[[ $NODE_TYPE == "peer" ]] && set_ORDERER_TLSCA_CRT_FILENAME

# docker-compose.yaml

make_docker_compose 

# configtxgen orderer

if [[ $MSPID == "$ORDERER_ORG_MSPID" ]]; then

   case "$NODE_BASENAME" in
   orderer* ) make_genesis_block 
              ;;
   peer0 )    make_channel_create_tx 
              make_anchor_peer_update_tx 
              ;;
   esac
fi
# .env

make_docker_env "$PEER_DIR/.env"

# move admin scripts

copy_admin_scripts 

# Estructura MSP de la org para generar la Tx para agregar la org al channel

if [[ $NODE_BASENAME == "peer0" && $MSPID != "$ORDERER_ORG_MSPID" ]]; then
   "$BASE/configtx-msp-dir.packer.sh" "$NODE_BASENAME"
fi

# make admin-crypto-material-dir for export to others nodes

if [[ $NODE_BASENAME =~ orderer* || ( $NODE_BASENAME == "peer0" && $MSPID != "$ORDERER_ORG_MSPID" ) ]]; then
   crypto_admin_export
fi

echo_success
