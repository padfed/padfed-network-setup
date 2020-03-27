#!/bin/bash
# Create CA key & self-signed certificate

set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname $0)"
. "$BASE/lib.sh"

echo_running

# Check args
if [[ "$#" -ne 3 ]]; then
   echo_red "ERROR: $# unexpected number of params"
   echo "Usage: $0 p1 p2 p3"
   echo "p1: base"
   echo "p2: subj"
   echo "p3: days"
   exit 1
fi

readonly CABASE="$1"
readonly SUBJ="$2"
readonly DAYS="$3"

# Defaults openssl ca filenames
readonly PRIVATE_KEY="$CABASE/private/cakey.pem"
readonly PRIVATE_KEY_TMP="$CABASE/cakey.tmp"
readonly CERTIFICATE="$CABASE/cacert.pem"
readonly REQUEST="$CABASE/requests/cacert.request"
mkdir -p "$CABASE/"{certs,newcerts,private,requests} 

echo "Generating Elliptic Curve Cryptography key (required by Fabric) ..."
openssl ecparam -name prime256v1 -genkey -noout -out "$PRIVATE_KEY_TMP"

echo "Transforming key to PKCS#8 ..."
openssl pkcs8 -topk8 -nocrypt -in "$PRIVATE_KEY_TMP" -out "$PRIVATE_KEY"
    
rm "$PRIVATE_KEY_TMP"

openssl req \
        -verbose \
        -new \
        -subj "$SUBJ" \
        -key  "$PRIVATE_KEY" \
        -out  "$REQUEST" \
        -sha256

check_file "$PRIVATE_KEY"
check_file "$REQUEST"

echo "Generating CA ..."
echo "subj [$SUBJ]"

# Create CA structure

touch "$CABASE/index.txt" 
touch "$CABASE/index.txt.attr" 
openssl rand -hex 16 > "$CABASE/serial"
cat <<< "[ ca ]
default_ca             = CA_default
[ CA_default ]       
dir                    = ${CABASE} # Where everything is kept
certs                  = \$dir/certs # Where the issued certs are kept
crl_dir                = \$dir/crl # Where the issued crl are kept
unique_subject         = no # Set to 'no' to allow creation of several certs with same subject.
database               = \$dir/index.txt # database index file.
new_certs_dir          = \$dir/newcerts # default place for new certs.
certificate	           = \$dir/cacert.pem # The CA certificate
serial		           = \$dir/serial # The current serial number
crlnumber	           = \$dir/crlnumber # the current crl number must be commented out to leave a V1 CRL
crl		               = \$dir/crl.pem # The current CRL
private_key	           = \$dir/private/cakey.pem # The private key
default_days           = 730
policy                 = policy_anything
email_in_dn            = no
[policy_anything]
countryName            = optional
stateOrProvinceName    = optional
localityName           = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional
[ v3_ca ]
basicConstraints = critical, CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always, issuer
keyUsage = critical, cRLSign, keyCertSign, digitalSignature, keyEncipherment
[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always, issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
" > "$CABASE/ca.conf"

openssl ca -selfsign \
           -md sha256 \
           -batch \
           -notext \
           -days $DAYS \
           -config  "$CABASE/ca.conf" \
           -extensions v3_ca \
           -keyfile "$PRIVATE_KEY" \
           -in      "$REQUEST" \
           -out     "$CERTIFICATE" 

check_file     "$PRIVATE_KEY" && echo "key [$PRIVATE_KEY]"
check_x509_crt "$CERTIFICATE" && echo "crt [$CERTIFICATE]"

echo_success
