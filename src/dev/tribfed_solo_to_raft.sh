#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

BASE=$(dirname $(readlink -f $0))
source $BASE/.env

CHANNEL_ID=$1

echo "antes de proceder debe insertar la metada modificada en el archivo ${CHANNEL_ID}_config_mantenance_mod.json, si no lo hizo cancele este script. Esperando 5 segundos..."
sleep 5

sed -i 's/solo/etcdraft/g' ${1}_config_mantenance_mod.json

# encode old config to protopuf
configtxlator proto_encode --input ${CHANNEL_ID}_config_mantenance.json --type common.Config --output ${CHANNEL_ID}_config_mantenance.pb

# encode new config to protopuf
configtxlator proto_encode --input ${CHANNEL_ID}_config_mantenance_mod.json --type common.Config --output ${CHANNEL_ID}_config_mantenance_mod.pb

# compute delta between configs
configtxlator compute_update --channel_id $CHANNEL_NAME --original ${CHANNEL_ID}_config_mantenance.pb --updated ${CHANNEL_ID}_config_mantenance_mod.pb --output ${CHANNEL_ID}_config_mantenance_update.pb

# decode delta config
configtxlator proto_decode --input ${CHANNEL_ID}_config_mantenance_update.pb --type common.ConfigUpdate | jq . > ${CHANNEL_ID}_config_mantenance_update.json

# wrap delta config with a header
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_ID'", "type":2}},"data":{"config_update":'$(cat ${CHANNEL_ID}_config_mantenance_update.json)'}}}' | jq . > ${CHANNEL_ID}_config_mantenance_update_envelope.json

case "$1" in
ordererchannel ) sed -i 's/padfedchannel/ordererchannel/g' ${CHANNEL_ID}_config_mantenance_update_envelope.json ;;
esac

# encode wrapped config to protopuf
configtxlator proto_encode --input ${CHANNEL_ID}_config_mantenance_update_envelope.json --type common.Envelope --output ${CHANNEL_ID}_config_mantenance_update_in_envelope.pb

docker  cp ${CHANNEL_ID}_config_mantenance_update_in_envelope.pb peer0_afip_cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/${CHANNEL_ID}_config_mantenance_update_in_envelope.pb

# sign channel update config
docker exec peer0_afip_cli peer channel signconfigtx -f ${CHANNEL_ID}_config_mantenance_update_in_envelope.pb

#Updating channel
echo updating channel
docker exec peer0_afip_cli peer channel update -f ${CHANNEL_ID}_config_mantenance_update_in_envelope.pb -c $CHANNEL_ID  -o orderer.afip.tribfed.gob.ar:7050 --tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem
