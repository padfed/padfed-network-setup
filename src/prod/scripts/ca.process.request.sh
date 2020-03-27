#!/bin/bash
# process request with an openssl ca
# generete a certificate

set -Eeuo pipefail
#set -x

# Initialize
readonly BASE="$(dirname $0)"
. "$BASE/lib.sh"

echo_running

[[ ! -v SETUP_CONF ]] && readonly SETUP_CONF="setup.conf" && check_file "$SETUP_CONF" && source "$SETUP_CONF"

# Check env variables
check_env CAS_INSTANCES_PATH 

# Check args
if [[ "$#" -ne 5 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   echo "Usage: $0 p1 p2 p3 p4 p5"
   echo "p1: msp | tls | ope"
   echo "p2: client or server"
   echo "p3: CN"
   echo "p4: request filename"
   echo "p5: crt filename"
   exit 1
fi

readonly CA="${1,,}"
readonly CLIENT_OR_SERVER="${2,,}"
readonly CN="$3"
readonly REQUEST="$4" && check_param_file 4 "$REQUEST" # input
readonly CERTIFICATE="$5" # output

case "$CA" in
msp | tls | ope ) ;;
* ) echo_red "[$THIS] ERROR: p1 [$CA] ca unknow, must be msp, tls or ope"; exit 1 ;;
esac 

case "$CLIENT_OR_SERVER" in
client ) readonly DAYS=${CLIENT_CRT_DAYS:-730}  ;; # 2 years
server ) readonly DAYS=${SERVER_CRT_DAYS:-1460} ;; # 4 years
* ) echo_red "[$THIS] ERROR: p2 [$CLIENT_OR_SERVER] must be client or server"; exit 1 ;;
esac

readonly CA_REQUESTS_REPO=$( "$BASE/ca.print.material.path.sh" "$CA" "requests" )

readonly CABASE="$CAS_INSTANCES_PATH/${MSPID^^}/$CA"

echo "Generating crt from [$CN] as [$CLIENT_OR_SERVER] with [$CA] ca ..."

if [[ $CA != "msp" ]]; then
   if [[ $CLIENT_OR_SERVER == "client" ]]; then
      readonly EXTENDED_KEY_USAGE="extendedKeyUsage = clientAuth"
   else
      readonly EXTENDED_KEY_USAGE="extendedKeyUsage = serverAuth"
      readonly SUBJECT_ALT_NAME="subjectAltName = DNS:$CN"
   fi
fi

cat <<< "[ cert_ext ]
basicConstraints = critical, CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier= keyid, issuer
keyUsage = critical, digitalSignature, keyEncipherment
${EXTENDED_KEY_USAGE:-}
${SUBJECT_ALT_NAME:-}
" > "$REQUEST.ext.conf"
openssl ca -md sha256 \
           -batch \
           -notext \
           -days     $DAYS \
           -config  "$CABASE/ca.conf" \
           -extfile "$REQUEST.ext.conf" -extensions cert_ext \
           -in      "$REQUEST" \
           -out     "$CERTIFICATE" 

# Save on CA REQUESTS Repo
cp "$REQUEST"     "$CA_REQUESTS_REPO"
cp "$CERTIFICATE" "$CA_REQUESTS_REPO"

check_x509_crt "$CERTIFICATE" 
echo "crt [$CERTIFICATE]"

echo_success "crt for [$CN] as [$CLIENT_OR_SERVER] with [$CA] ca"
