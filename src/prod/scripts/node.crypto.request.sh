#!/bin/bash
# Create Key and CSR (Certificate Sign Request) 

set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname $0)"
. "$BASE/lib.sh"

echo_running

# Check args
if [[ "$#" -ne 2 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   echo "Usage: $0 p1 p2"
   echo "p1: SUBJ"
   echo "p2: request basefilename"
   exit 1
fi

readonly SUBJ="$1"
readonly FILEBASENAME="$2"

rm -f "${FILEBASENAME}.1"
rm -f "${FILEBASENAME}.key"
rm -f "${FILEBASENAME}.request"

echo "Generating Elliptic Curve Cryptography key (required by Fabric) ..."
openssl ecparam -name prime256v1 -genkey -noout -out "${FILEBASENAME}.1"

echo "Transforming key to PKCS#8 ..."
openssl pkcs8 -topk8 -nocrypt -in  "${FILEBASENAME}.1" -out "${FILEBASENAME}.key"

rm ${FILEBASENAME}.1

echo "Generating request ..."
echo "SUBJ [$SUBJ]"
openssl req -new \
            -subj "$SUBJ" \
            -key "${FILEBASENAME}.key" \
            -out "${FILEBASENAME}.request" 

check_file "${FILEBASENAME}.key"     && echo "key [${FILEBASENAME}.key]"
check_file "${FILEBASENAME}.request" && echo "csr [${FILEBASENAME}.request]"

echo_success
