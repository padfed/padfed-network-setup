#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
ME=$(basename $0)
HERE=$(dirname $(readlink -f $0))

source $HERE/.env

CONTAINER="peer0.${BLOCKCHAIN_NETWORK_NAME}.${ENVIRONMENT}.afip.${ORGS_NETWORK_DOMAIN_NAME}.cli"

if [[ $TLS_ENABLED == "true" ]]; then
  PEER_CLI_TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.pem"
  if [[ $TLS_CLIENT_AUTH_REQUIRED == "true" ]]; then
    PEER_CLI_TLS_PARAMETERS="$PEER_CLI_TLS_PARAMETERS --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
  fi
fi

docker exec $CONTAINER \
  peer channel fetch config config_block.pb \
    $PEER_CLI_TLS_PARAMETERS \
    -o $ORDERER_HOSTNAME.$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME:$ORDERER_PORT \
    -c $CHANNEL_NAME \


docker exec $CONTAINER cat config_block.pb > config_block.pb

echo "extract block config"
configtxlator proto_decode --input config_block.pb --type common.Block > config_block.json

echo "extract config part"
jq ".data.data[0].payload.data.config" config_block.json > config.json

echo "show currents values"
#jq  ".channel_group.groups.Orderer.values.BatchSize.value.max_message_count" config.json
#jq  ".channel_group.groups.Orderer.values.BatchTimeout.value.timeout" config.json
jq  ".channel_group.groups.Orderer.values.BatchSize.value.preferred_max_bytes" config.json

echo "apply changes"
#jq ".channel_group.groups.Orderer.values.BatchSize.value.max_message_count=1000"  config.json |  
#jq ".channel_group.groups.Orderer.values.BatchTimeout.value.timeout=\"2s\"" |
jq ".channel_group.groups.Orderer.values.BatchSize.value.preferred_max_bytes=10485760" config.json > updated_config.json


configtxlator proto_encode --input config.json --type common.Config >original_config.pb
configtxlator proto_encode --input updated_config.json --type common.Config >modified_config.pb
configtxlator compute_update --channel_id $CHANNEL_NAME --original original_config.pb --updated modified_config.pb >config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate > common.configUpdate.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat common.configUpdate.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope > orderer_update_in_envelope.pb

cp orderer_update_in_envelope.pb ./crypto-config

#Requiere autorizacion de la mayoria de los participantes de OrdererMSP (para este caso donde se actualiza la configuracion de timeout y batchsize
#En esta organizacion para esta red hay un solo nodo por lo cual se firma solo para este nodo. Podria ejecutarse el update directamente que ya realiza dicha tarea

docker exec \
  -e CORE_PEER_ADDRESS=$ORDERER_HOSTNAME.$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME \
  -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/configtx/ordererOrganizations/$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME/users/Admin@$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME/msp \
  -e CORE_PEER_LOCALMSPID=$ORDERER_MSP \
  $CONTAINER peer channel signconfigtx -f /etc/hyperledger/configtx/orderer_update_in_envelope.pb \
  $PEER_CLI_TLS_PARAMETERS \
  -o $ORDERER_HOSTNAME.$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME:$ORDERER_PORT


#Para otro tipo de updates. ej: addOrg. se requiere la mayoria de los participantes N/2+1
#docker exec peer0_afip_cli   peer channel signconfigtx -f /etc/hyperledger/configtx/orderer_update_in_envelope.pb
#docker exec peer1_afip_cli   peer channel signconfigtx -f /etc/hyperledger/configtx/orderer_update_in_envelope.pb
#docker exec peer1_comarb_cli peer channel signconfigtx -f /etc/hyperledger/configtx/orderer_update_in_envelope.pb


#Updating channel desde un peer
docker exec \
  -e CORE_PEER_ADDRESS=$ORDERER_HOSTNAME.$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME \
  -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/configtx/ordererOrganizations/$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME/users/Admin@$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME/msp \
  -e CORE_PEER_LOCALMSPID=$ORDERER_MSP \
  $CONTAINER peer channel update -f /etc/hyperledger/configtx/orderer_update_in_envelope.pb \
  $PEER_CLI_TLS_PARAMETERS \
  -o $ORDERER_HOSTNAME.$ORDERER_DOMAIN_NAME.$ENVIRONMENT.$ORDERER_NETWORK_DOMAIN_NAME:$ORDERER_PORT \
  -c $CHANNEL_NAME