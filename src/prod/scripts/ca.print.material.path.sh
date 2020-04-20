#!/bin/bash
# ca.material.path.sh

set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname "$0")"
. "$BASE/lib.sh"

readonly THIS="$0"

[[ ! -v SETUP_CONF ]] && readonly SETUP_CONF="setup.conf" && [[ -r $SETUP_CONF ]] && source "$SETUP_CONF"

# Check args
if [[ "$#" -ne 2 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   echo "Usage: $0 p1"
   echo "p1: root, msp, tls or ope"
   echo "p2: key, crt, csr or requests"
   exit 1
fi
readonly SERVICE="${1,,}"
readonly TYPE="${2,,}"

[[ -v CAS_INSTANCES_PATH && -v MSPID && -v DOMAIN ]] || { echo ""; exit; }

case "$SERVICE" in
msp | tls | ope | root ) ;;
* ) echo_red "[$THIS] ERROR: p1 must by root, msp, tls or ope"; exit 1 ;;
esac

readonly CABASE="$CAS_INSTANCES_PATH/$MSPID/$SERVICE"

case "$TYPE" in
key )      echo "$CABASE/private/cakey.pem"; exit ;;
crt )      echo "$CABASE/cacert.pem"; exit ;;
requests ) echo "$CABASE/requests"; exit ;;
esac

echo_red "[$THIS] ERROR: p2 [$TYPE] must by crt, key or requests"
exit 1
