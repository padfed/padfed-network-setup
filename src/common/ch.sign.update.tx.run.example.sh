#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

# Este script ayuda a invocar al script cc.sing.update.tx.sh
#
# ch.sing.update.tx.sh recibe como parametros: 
# 1 - nombre del docker cli (puede ser cualquier cli)
# 2 - volumen mapeado del docker cli
# 3 - signer MSPID 
# 4 - path a la configuracion MSP del Admin del signer MSP
# 5 - direccion de algun peer del signer incluyendo el port (7051) 
# 6 - archivo que se debe firmar
# 7 - nombre del archivo de salida

sign() {
ch.sign.update.tx.sh \
        "${P1_SIGNER_CLI}" \
        "${P2_SIGNER_SIGNING_PATH}" \
        "${P3_SIGNER_MSPID}" \
        "${P4_SIGNER_ADMIN_MSP_PATH}" \
        "${P5_SIGNER_PEER_ADDRESS}" \
        "${P6_FILE_TO_SIGN}" \
        "${P7_OUTPUT_FILENAME}" 
}

BASE=$(dirname $(readlink -f $0))
PATH=$(realpath $BASE):$PATH

# Dev
#P1_SIGNER_CLI=peer0_afip_cli
#P2_SIGNER_SIGNING_PATH=...
#DOMAIN=${ORG,,}.tribfed.gob.ar

# Testnet
P1_SIGNER_CLI=peer0_afip_cli
P2_SIGNER_SIGNING_PATH=../src/dev/fabric-instance/peer0_afip_cli/signing/
FILE_TO_SIGN="/xx/xx/update_tx.pb"

##########
# ARBA #
##########
P3_SIGNER_MSPID=ARBA
ARTIFACTS_PATH=../src/qa/${P3_SIGNER_MSPID}_artifacts
DOMAIN=blockchain-tributaria.test.${P3_SIGNER_MSPID,,}.gob.ar
P4_SIGNER_ADMIN_MSP_PATH="${ARTIFACTS_PATH}/Admin@${DOMAIN}/msp"
P5_SIGNER_PEER_ADDRESS=peer0-${DOMAIN}:7051
P6_FILE_TO_SIGN="$FILE_TO_SIGN"
P7_OUTPUT_FILENAME="${P6_FILE_TO_SIGN}.signed_by_${P3_SIGNER_MSPID}.pb"

sign 

##########
# COMARB #
##########
P3_SIGNER_MSPID=COMARB
ARTIFACTS_PATH=../src/qa/${P3_SIGNER_MSPID}_artifacts
DOMAIN=blockchain-tributaria.testnet.${P3_SIGNER_MSPID,,}.gob.ar
P4_SIGNER_ADMIN_MSP_PATH="${ARTIFACTS_PATH}/Admin@${DOMAIN}/msp"
P5_SIGNER_PEER_ADDRESS=peer0.${DOMAIN}:7051
P6_FILE_TO_SIGN="${P7_OUTPUT_FILENAME}"
P7_OUTPUT_FILENAME="${P6_FILE_TO_SIGN}.signed_by_${P3_SIGNER_MSPID}.pb"

sign 
