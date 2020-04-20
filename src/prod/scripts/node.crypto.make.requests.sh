#!/bin/bash
# Create Admin, Users and Peers keys/requests for MSP and TLS

set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname "$0")"
. "$BASE/lib.sh"

echo_running

[[ ! -v SETUP_CONF ]] && readonly SETUP_CONF="setup.conf" && check_file "$SETUP_CONF" && source "$SETUP_CONF"

# Check env variables
check_env MSPID
check_env DOMAIN
check_env CRYPTO_STAGE_PATH
check_env CA_MODE

echo "CRT_DN_C [${CRT_DN_C:=AR}]"
echo "CRT_DN_O [${CRT_DN_O:=${DOMAIN}}]"
echo "CRT_DN_OU_TLS [${CRT_DN_OU_TLS:="TLS"}]"
echo "CRT_DN_OU_OPE [${CRT_DN_OU_OPE:="OPE"}]"
echo "CRT_DN_OU_MSP [${CRT_DN_OU_MSP:="none"}]"
echo "CRT_DN_OU_MSP_ADMIN [${CRT_DN_OU_MSP_ADMIN:="admin"}]"
echo "CRT_DN_OU_MSP_CLIENT [${CRT_DN_OU_MSP_CLIENT:="client"}]"
echo "CRT_DN_OU_MSP_PEER [${CRT_DN_OU_MSP_PEER:="peer"}]"
echo "CRT_DN_OU_MSP_ORDERER [${CRT_DN_OU_MSP_ORDERER:="orderer"}]"

echo "CRT_DN_CN_SUFFIX [${CRT_DN_CN_SUFFIX:=""}]"

echo "OPERATIONS_ENABLE [${OPERATIONS_ENABLE:=false}]"

echo "ADMINS_BASENAME [${ADMINS_BASENAME:-}]"
echo "USERS_BASENAME [${USERS_BASENAME:-}]"
echo "OPERS_BASENAME [${OPERS_BASENAME:-}]"

function mk_request() {
       local FILEBASENAME="$CRYPTO_TARGET/${FULLNAME}-$SERVICE"

       "$BASE/node.crypto.request.sh" "$SUBJ" "$FILEBASENAME"

       check_file "$FILEBASENAME.key"

       local CN_from_CSR=$(get_CN_from_CSR "$FILEBASENAME.request")
       [[ $CN == "$CN_from_CSR" ]] || { echo_red "ERROR: CN [$CN] != CN from CSR [$CN_from_CSR]"; exit 1; }

       mv "$FILEBASENAME.request" "$CRYPTO_REQUESTS_PATH"
}

########################################################################

function set_SERIALNUMBER() {
   if [[ -v ORG_CUIT && ! "$ORG_CUIT" == "0" ]]; then
      if ! [[ $ORG_CUIT == *[[:digit:]]* ]]; then
         echo_red "[$THIS] ERROR: env ORG_CUIT must be number"
         exit 1
      fi
      if [[ ! $ORG_CUIT -gt 30000000000 ]]; then
         echo_red "[$THIS] ERROR: env ORG_CUIT must a valid CUIT"
         exit 1
      fi
      readonly SERIALNUMBER="/serialNumber=CUIT $ORG_CUIT"
   else
      readonly SERIALNUMBER=""
   fi
}

function mk_user_requests() {
   local BASENAME=$1
   local FULLNAME=${BASENAME}@$DOMAIN
   local CN=${BASENAME}${CRT_DN_CN_SUFFIX}

   # MSP
   local MSP_OU_2="" && [[ $CRT_DN_OU_MSP != "none" ]] && MSP_OU_2="/OU=$CRT_DN_OU_MSP"
   local SUBJ="/C=${CRT_DN_C}/O=${CRT_DN_O}/OU=${CRT_DN_OU_MSP_CLIENT}${MSP_OU_2}/CN=${CN}$SERIALNUMBER"
   local SERVICE="msp-client"
   mk_request

   # TLS-CLIENT
   local SUBJ="/C=${CRT_DN_C}/O=${CRT_DN_O}/OU=$CRT_DN_OU_TLS/CN=${CN}$SERIALNUMBER"
   local SERVICE="tls-client"
   mk_request
}

function mk_admin_requests() {
   local BASENAME=$1

   case $BASENAME in
   admin1 | admin2 | admin3 | admin4 | admin5 ) ;;
   * ) echo_red "ERROR: ADMINS_BASENAME has an item [$BASENAME] - must have some of [admin1 | admin2 | admin3 | admin4 | admin5]"
       exit 1
   esac

   local FULLNAME=${BASENAME}@$DOMAIN
   local CN=${BASENAME}${CRT_DN_CN_SUFFIX}

   # MSP
   local MSP_OU_2="" && [[ $CRT_DN_OU_MSP != "none" ]] && MSP_OU_2="/OU=$CRT_DN_OU_MSP"
   local SUBJ="/C=${CRT_DN_C}/O=${CRT_DN_O}/OU=${CRT_DN_OU_MSP_ADMIN}${MSP_OU_2}/CN=${CN}$SERIALNUMBER"
   local SERVICE="msp-client"
   mk_request

   # TLS-CLIENT
   local SUBJ="/C=${CRT_DN_C}/O=${CRT_DN_O}/OU=$CRT_DN_OU_TLS/CN=${CN}$SERIALNUMBER"
   local SERVICE="tls-client"
   mk_request
}

function mk_oper_requests() {
   local BASENAME=$1
   local FULLNAME=${BASENAME}@$DOMAIN
   local CN=${BASENAME}${CRT_DN_CN_SUFFIX}

   # OPE-CLIENT
   local SUBJ="/C=${CRT_DN_C}/O=${CRT_DN_O}/OU=$CRT_DN_OU_OPE/CN=${CN}$SERIALNUMBER"
   local SERVICE="ope-client"
   mk_request
}

function mk_peer_requests() {
   local BASENAME=$1
   local SEP="." && [[ -v NODE_NAMESEP ]] && [[ $NODE_NAMESEP == "-" ]] && SEP="-"
   local FULLNAME=${BASENAME}${SEP}$DOMAIN

   # MSP
   local MSP_OU_2="" && [[ $CRT_DN_OU_MSP != "none" ]] && MSP_OU_2="/OU=$CRT_DN_OU_MSP"
   case "$BASENAME" in
   peer* )    local OU="/OU=${CRT_DN_OU_MSP_PEER}${MSP_OU_2}" ;;
   orderer* ) local OU="/OU=${CRT_DN_OU_MSP_ORDERER}${MSP_OU_2}" ;;
   * ) echo_red "ERROR: [$BASENAME] must be peer* | orderer*"
       exit 1
       ;;
   esac
   local CN=${BASENAME}${CRT_DN_CN_SUFFIX}
   local SUBJ="/C=${CRT_DN_C}/O=${CRT_DN_O}${OU}/CN=${CN}$SERIALNUMBER"
   local SERVICE="msp-server"
   mk_request

   # TLS-CLIENT
   local CN=${BASENAME}${CRT_DN_CN_SUFFIX}
   local SUBJ="/C=${CRT_DN_C}/O=${CRT_DN_O}/OU=$CRT_DN_OU_TLS/CN=${CN}$SERIALNUMBER"
   local SERVICE="tls-client"
   mk_request

   # TLS-SERVER
   local CN=$FULLNAME # Para TLS-SERVER en el CN va el FQDN que es el FULLNAME
   local SUBJ="/C=${CRT_DN_C}/O=${CRT_DN_O}/OU=$CRT_DN_OU_TLS/CN=${CN}$SERIALNUMBER"
   local SERVICE="tls-server"
   mk_request

   if [[ $OPERATIONS_ENABLE == true ]]; then
      local CN=${BASENAME}${CRT_DN_CN_SUFFIX}
      local SUBJ="/C=${CRT_DN_C}/O=${CRT_DN_O}/OU=$CRT_DN_OU_OPE/CN=${CN}$SERIALNUMBER"
      local SERVICE="ope-client"
      mk_request
   fi
}

###########################################################

if [[ $# != 1 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   exit 1
fi
case "$1" in
orderer* | peer* ) readonly NODE_BASENAME=$1
           ;;
clients )  ;;
* )        echo_red "Usage: p1 [$1] must bu peer0 | peer1 | orderer* (only ${ORDERER_ORG_MSPID} or ORDERER_TYPE=etcdraft) | clients"
           exit 1
esac

if [[ -v NODE_BASENAME && ! -z $NODE_BASENAME ]]; then
   readonly CRYPTO_TARGET="$CRYPTO_STAGE_PATH/$MSPID-$NODE_BASENAME"
   readonly CRYPTO_REQUESTS_PATH="$MSPID-$NODE_BASENAME-crypto-requests"
else
   readonly CRYPTO_TARGET="$CRYPTO_STAGE_PATH/$MSPID-clients"
   readonly CRYPTO_REQUESTS_PATH="$MSPID-clients-crypto-requests"
fi

# Si no existe, crea CRYPTO_STAGE
backup_dir "$CRYPTO_TARGET"
rm -rf     "$CRYPTO_TARGET"
mkdir -p   "$CRYPTO_TARGET"

backup_dir "$CRYPTO_REQUESTS_PATH"
rm -rf     "$CRYPTO_REQUESTS_PATH"
mkdir -p   "$CRYPTO_REQUESTS_PATH"

backup_dir "$CRYPTO_REQUESTS_PATH-crts"
rm -rf     "$CRYPTO_REQUESTS_PATH-crts"

set_SERIALNUMBER

if [[ -v NODE_BASENAME && ! -z $NODE_BASENAME ]]; then

   mk_peer_requests "$NODE_BASENAME"

   if [[ $NODE_BASENAME =~ orderer* || ( $MSPID != "$ORDERER_ORG_MSPID" && $NODE_BASENAME == peer0 ) ]]; then

      for admin in $ADMINS_BASENAME; do mk_admin_requests "${admin,,}"; done
   fi
else # clients
      for admin in ${ADMINS_BASENAME:-}; do mk_admin_requests "${admin,,}"; done
fi

if [[ $OPERATIONS_ENABLE == true && -v OPERS_BASENAME && ! -z $OPERS_BASENAME ]]; then
   for oper in $OPERS_BASENAME; do mk_oper_requests "$oper"; done
fi

if [[ -v USERS_BASENAME && ! -z $USERS_BASENAME ]]; then
   for user in $USERS_BASENAME; do mk_user_requests "$user"; done
fi
if [[ -v ALL_PEERS_BASENAMES && ! -z $ALL_PEERS_BASENAMES ]]; then
   for node in $ALL_PEERS_BASENAMES; do

       case "$node" in
       orderer* | peer* ) ;;
       * ) echo_red "ERROR: [$ALL_PEERS_BASENAMES] must be list of [peer0 | peer1 | orderer* (only ${ORDERER_ORG_MSPID} or ORDERER_TYPE=etcdraft)]"
           exit 1
           ;;
       esac

       # NODE_BASENAME puede estar incluido dentro de ALL_NODE_BASENAMES
       [[ $node != "${NODE_BASENAME:=x}" ]] && mk_peer_requests "$node"
   done
fi

echo_success "MSP, TLS, OPE key/csr for $MSPID"
