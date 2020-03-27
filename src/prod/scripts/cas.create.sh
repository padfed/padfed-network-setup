#!/bin/bash
# Create CA key & self-signed certificate for MSP, TLS y OPE

set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname "$0")"

# Import lib
. "$BASE/lib.sh"

echo_running

check_file "setup.conf" && source "setup.conf"

# Check env variables
check_env MSPID 
check_env DOMAIN 
check_env CAS_INSTANCES_PATH 
check_env CA_CRT_DAYS 
check_env CA_MODE

case $CA_MODE in
ROOTCAS | INTERMEDIATECAS ) ;;
* ) "ERROR: env variable CA_MODE [$CA_MODE] must be ROOTCAS or INTERMEDIATECAS"; exit 1 ;;
esac

########################################################################
echo "CRT_DN_C [${CRT_DN_C:=AR}]"
echo "CRT_DN_O [${CRT_DN_O:=${DOMAIN}}]"
echo "CAS_CRT_DN_CN_SUFFIX [${CAS_CRT_DN_CN_SUFFIX:=""}]"

readonly TARGET="$CAS_INSTANCES_PATH/$MSPID"

warn_backup_rm "$TARGET"

if [[ $CA_MODE == "INTERMEDIATECAS" ]]; then 
   readonly SERVICES="root msp tls ope"
else
   readonly SERVICES="msp tls ope"
fi

for service in $SERVICES; do
    CA="${service}ca"
    [[ $service != "root" && $CA_MODE == "INTERMEDIATECAS" ]] && CA="${service}ica"

    CABASE="$TARGET/$service" && mkdir -p "$CABASE"

    if [[ $service == "root" ]]; then
       if [[ -v ROOTCA_CN && ! -z $ROOTCA_CN ]]; then
          readonly LOCAL_ROOTCA_CN="$ROOTCA_CN"
       else
          readonly LOCAL_ROOTCA_CN="$CA.$DOMAIN"
       fi
       SUBJ="/C=${CRT_DN_C:=AR}/O=${CRT_DN_O}/CN=${LOCAL_ROOTCA_CN}${CAS_CRT_DN_CN_SUFFIX}"
       readonly ROOTCABASE="$CABASE"
       "$BASE/rootcas.create.one.sh" "$CABASE" "$SUBJ" "$CA_CRT_DAYS"
    else
       SUBJ="/C=${CRT_DN_C:=AR}/O=${CRT_DN_O}/CN=$CA.${DOMAIN}${CAS_CRT_DN_CN_SUFFIX}"
       if [[ -v ROOTCABASE ]]; then
          "$BASE/${CA_MODE,,}.create.one.sh" "$CABASE" "$SUBJ" "$CA_CRT_DAYS" "$ROOTCABASE"
       else
          "$BASE/${CA_MODE,,}.create.one.sh" "$CABASE" "$SUBJ" "$CA_CRT_DAYS"
       fi
    fi
    check_file     "$( "$BASE/ca.print.material.path.sh" "$service" "key" )" 
    check_x509_crt "$( "$BASE/ca.print.material.path.sh" "$service" "crt" )" 
done

echo_success
