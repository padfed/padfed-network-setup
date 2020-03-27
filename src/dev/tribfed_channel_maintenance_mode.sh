#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

BASE=$(dirname $(readlink -f $0))
source $BASE/.env

echo "USAGE [CHANNEL_NAME] [TO_NORMAL|TO_MAINTENANCE]"

CHANNEL_ID=$1
STATE=$2


echo "extract block config"
docker exec peer0_afip_cli peer channel fetch config ${CHANNEL_ID}_config_block.pb -c ${CHANNEL_ID} -o orderer.afip.tribfed.gob.ar:7050 --tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem

docker exec peer0_afip_cli cat ${CHANNEL_ID}_config_block.pb > ${CHANNEL_ID}_config_block.pb


configtxlator proto_decode --input ${CHANNEL_ID}_config_block.pb --type common.Block > ${CHANNEL_ID}_config_block.json

echo "extract config part"
jq ".data.data[0].payload.data.config" ${CHANNEL_ID}_config_block.json > ${CHANNEL_ID}_config.json

# save old config, to calculate delta in the future
cp ${CHANNEL_ID}_config.json ${CHANNEL_ID}_config_mod.json

case "$2" in
TO_NORMAL )      sed -i 's/MAINTENANCE/NORMAL/g' ${CHANNEL_ID}_config_mod.json ;;
TO_MAINTENANCE ) sed -i 's/NORMAL/MAINTENANCE/g' ${CHANNEL_ID}_config_mod.json ;;
* ) echo "p2 [$2] erroneo, debe ser TO_NORMAL or TO_MAINTENANCE"
    exit 1
esac

# set maintenance mode in configs
#sed -i 's/NORMAL/MAINTENANCE/g' ${CHANNEL_ID}_config_mod.json

# encode old config to protopuf
configtxlator proto_encode --input ${CHANNEL_ID}_config.json --type common.Config --output ${CHANNEL_ID}_config.pb

# encode new config to protopuf
configtxlator proto_encode --input ${CHANNEL_ID}_config_mod.json --type common.Config --output ${CHANNEL_ID}_modified_config.pb

# compute delta between configs
configtxlator compute_update --channel_id ${CHANNEL_ID} --original ${CHANNEL_ID}_config.pb --updated ${CHANNEL_ID}_modified_config.pb --output ${CHANNEL_ID}_config_update.pb

# decode delta config
configtxlator proto_decode --input ${CHANNEL_ID}_config_update.pb --type common.ConfigUpdate | jq . > ${CHANNEL_ID}_config_update.json

# wrap delta config with a header
echo '{"payload":{"header":{"channel_header":{"channel_id":"'${CHANNEL_ID}'", "type":2}},"data":{"config_update":'$(cat ${CHANNEL_ID}_config_update.json)'}}}' | jq . > ${CHANNEL_ID}_config_update_envelope.json

# encode wrapped config to protopuf
configtxlator proto_encode --input ${CHANNEL_ID}_config_update_envelope.json --type common.Envelope --output ${CHANNEL_ID}_config_update_in_envelope.pb

docker  cp ${CHANNEL_ID}_config_update_in_envelope.pb peer0_afip_cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/${CHANNEL_ID}_config_update_in_envelope.pb
# sign channel update config
docker exec peer0_afip_cli peer channel signconfigtx -f ${CHANNEL_ID}_config_update_in_envelope.pb

#Updating channel
docker exec peer0_afip_cli peer channel update -f ${CHANNEL_ID}_config_update_in_envelope.pb -c ${CHANNEL_ID}  -o orderer.afip.tribfed.gob.ar:7050 --tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem

echo "extract block config luego de pasar el channel a modo mantenimiento, editar config_matenance.json incorporando propiedades de RAFT"
docker exec peer0_afip_cli peer channel fetch config ${CHANNEL_ID}_config_block_mantenance.pb -c ${CHANNEL_ID} -o orderer.afip.tribfed.gob.ar:7050 --tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem

docker exec peer0_afip_cli cat ${CHANNEL_ID}_config_block_mantenance.pb > ${CHANNEL_ID}_config_block_mantenance.pb

configtxlator proto_decode --input ${CHANNEL_ID}_config_block_mantenance.pb --type common.Block > ${CHANNEL_ID}_config_block_mantenance.json

echo "extract config part"
jq ".data.data[0].payload.data.config" ${CHANNEL_ID}_config_block_mantenance.json > ${CHANNEL_ID}_config_mantenance.json

# save old config, to calculate delta in the future
cp ${CHANNEL_ID}_config_mantenance.json ${CHANNEL_ID}_config_mantenance_mod.json
