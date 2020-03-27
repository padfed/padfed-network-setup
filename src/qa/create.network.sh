#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
ME=$(basename $0)
HERE=$(dirname $(readlink -f $0))

source $HERE/.env

replaceKeys() {
    local FILE=$1
    shift
    while [[ $# -gt 0 ]]; do
        local NAME=$1
        sed -i "s/{{$NAME}}/${!NAME}/" $FILE
        shift
    done
}

prepareCryptoConfig() {

    if ! [ -x "$(command -v cryptogen)" ]; then
      echo 'Error: cryptogen tool no instalado o no localizable en PATH, revise README con Prerequisitos de instalacion' >&2
      exit 1
    fi

    if ! [ -x "$(command -v configtxgen)" ]; then
      echo 'Error: configtxgen tool no instalado o no localizable en PATH, revise README con Prerequisitos de instalacion' >&2
      exit 1
    fi

    cp -f $FABRIC_CONFIG_PATH/configtx.template.yaml $FABRIC_DEST_PATH/configtx.yaml
    cp -f $FABRIC_CONFIG_PATH/crypto-config.template.yaml $FABRIC_DEST_PATH/crypto-config.yaml

    echo "###############################################################################################################"

    replaceKeys $FABRIC_DEST_PATH/crypto-config.yaml \
        ORDERER_NAME \
        ORDERER_NETWORK_DOMAIN_NAME \
        ORDERER_HOSTNAME \
        ORGS_NETWORK_DOMAIN_NAME \
        ORGS_DEFAULT_PEER_COUNT \
        ENVIRONMENT \
        BLOCKCHAIN_NETWORK_NAME \
        ORDERER_DOMAIN_NAME

    replaceKeys $FABRIC_DEST_PATH/configtx.yaml \
        ORDERER_HOSTNAME \
        ORDERER_PORT \
        ENVIRONMENT \
        BLOCKCHAIN_NETWORK_NAME \
        ORDERER_DOMAIN_NAME \
        ORDERER_NETWORK_DOMAIN_NAME \
        ORGS_NETWORK_DOMAIN_NAME \
        PEER_NODE_PRINCIPAL_PORT

    cryptogen generate --config=$FABRIC_DEST_PATH/crypto-config.yaml --output=$FABRIC_DEST_PATH/crypto-config

    configtxgen -configPath $FABRIC_DEST_PATH -profile SetupGenesis -outputBlock $FABRIC_DEST_PATH/genesis.block
    configtxgen -configPath $FABRIC_DEST_PATH -profile SetupChannel -outputCreateChannelTx $FABRIC_DEST_PATH/channel.tx -channelID $CHANNEL_NAME

    configtxgen -profile SetupChannel -outputAnchorPeersUpdate $FABRIC_DEST_PATH/afip_anchors.tx   -channelID $CHANNEL_NAME -configPath $FABRIC_DEST_PATH/ -asOrg AFIP
    configtxgen -profile SetupChannel -outputAnchorPeersUpdate $FABRIC_DEST_PATH/arba_anchors.tx   -channelID $CHANNEL_NAME -configPath $FABRIC_DEST_PATH/ -asOrg ARBA
    configtxgen -profile SetupChannel -outputAnchorPeersUpdate $FABRIC_DEST_PATH/comarb_anchors.tx -channelID $CHANNEL_NAME -configPath $FABRIC_DEST_PATH/ -asOrg COMARB

}


deployOrderer() {

    mkdir -p $FABRIC_DEPLOY_PATH/nodes/orderer/crypto-config/ordererOrganizations

    cp -f $HERE/.env $FABRIC_DEPLOY_PATH/nodes/orderer/
    cp -f $FABRIC_CONFIG_PATH/orderer.template.yaml $FABRIC_DEPLOY_PATH/nodes/orderer/docker-compose.yaml
    cp -f -r $FABRIC_DEST_PATH/crypto-config/ordererOrganizations $FABRIC_DEPLOY_PATH/nodes/orderer/crypto-config/
    cp -f $FABRIC_DEST_PATH/genesis.block $FABRIC_DEPLOY_PATH/nodes/orderer/crypto-config

    replaceKeys $FABRIC_DEPLOY_PATH/nodes/orderer/docker-compose.yaml \
        ORDERER_HOSTNAME \
        ORDERER_DOMAIN_NAME \
        ENVIRONMENT \
        ORDERER_NETWORK_DOMAIN_NAME

}


function prepareOrgNode() {

    ORG=$1
    PEER=$2
    MSPID=$3
    GOSSIP_NODE=$4
    COMPOSE_FILE=$5

    cp $HERE/.env $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER
    cp $FABRIC_CONFIG_PATH/peer.template.yaml $COMPOSE_FILE
    cp $FABRIC_DEST_PATH/channel.tx $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER/crypto-config
    cp $FABRIC_DEST_PATH/$1_anchors.tx $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER/crypto-config


    echo "PEER_NAME=$PEER_NAME" >> $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER/.env
    echo "ORG_NAME=$ORG" >> $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER/.env

    echo "PEER_MSP=$MSPID" >> $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER/.env
    echo "PEER_ANCHOR_NAME=$GOSSIP_NODE" >> $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER/.env

    replaceKeys $COMPOSE_FILE \
        PEER_NAME \
        BLOCKCHAIN_NETWORK_NAME \
        ENVIRONMENT \
        ORGS_NETWORK_DOMAIN_NAME \
        ORG

}

deployOrg() {

    ORG=$1
    MSPID=$2
    DOMAIN=$3
    PEER_NAME=$4
    GOSSIP_PEER=$5

    mkdir -p $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/crypto-config/peerOrganizations/
    mkdir -p $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/crypto-config/ordererOrganizations/orderer/tlsca

    cp -fr $FABRIC_DEST_PATH/crypto-config/peerOrganizations/$DOMAIN \
           $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/crypto-config/peerOrganizations/
    cp -fr ${FABRIC_DEST_PATH}/crypto-config/ordererOrganizations/*/tlsca/*.pem \
           $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/crypto-config/ordererOrganizations/orderer/tlsca

    mv $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/crypto-config/ordererOrganizations/orderer/tlsca/*.pem \
       $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/crypto-config/ordererOrganizations/orderer/tlsca/tlsca.pem

    prepareOrgNode $ORG $PEER_NAME $MSPID $GOSSIP_PEER $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/docker-compose.yaml

}

deployClientOrg() {
    mkdir -p $FABRIC_DEPLOY_PATH/nodes/$1/crypto-config/peerOrganizations/
    cp -fr $FABRIC_DEST_PATH/crypto-config/peerOrganizations/$2 \
           $FABRIC_DEPLOY_PATH/nodes/$1/crypto-config/peerOrganizations/
}

deployCreateChannelScript() {
    ORG=$1
    PEER_NAME=$2
    deployCreateJoinScript $ORG $PEER_NAME ch.create
}

deployJoinChannelScript() {
    ORG=$1
    PEER_NAME=$2
    deployCreateJoinScript $ORG $PEER_NAME ch.join
}

deployCreateJoinScript() {
    ORG=$1
    PEER_NAME=$2
    SCRIPT=$3
    cp $FABRIC_CONFIG_PATH/$SCRIPT.sh $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/$SCRIPT.sh
    chmod +x $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/$SCRIPT.sh
}

deployCCdeployScript() {
    ORG=$1
    PEER_NAME=$2
    mkdir -p $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/gopath/download
    mkdir -p $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/gopath/src
    cp $FABRIC_CONFIG_PATH/cc.download.sh $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/
    cp $FABRIC_CONFIG_PATH/cc.install.sh $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/cc.install.sh
    chmod +x $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/cc.install.sh
    chmod +x $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/cc.download.sh
}

deployInstantiateCCScript() {
    ORG=$1
    PEER_NAME=$2
    instantiateUpgradeCCScript $ORG $PEER_NAME instantiate
}

deployUpgradeCCScript() {
    ORG=$1
    PEER_NAME=$2
    instantiateUpgradeCCScript $ORG $PEER_NAME upgrade
}

instantiateUpgradeCCScript() {
    ORG=$1
    PEER_NAME=$2
    SCRIPT=$3
    cp $FABRIC_CONFIG_PATH/cc.$SCRIPT.sh $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/cc.$SCRIPT.sh
    chmod +x $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/cc.$SCRIPT.sh
}

deployCallCCScript() {
    ORG=$1
    PEER_NAME=$2
    cp $FABRIC_CONFIG_PATH/cc.call.sh $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/
    chmod +x $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/cc.call.sh
}

deployUpdateAnchorsPeersScript() {
    ORG=$1
    PEER_NAME=$2
    cp $FABRIC_CONFIG_PATH/ch.add.anchor.sh $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/
    chmod +x $FABRIC_DEPLOY_PATH/nodes/$ORG.$PEER_NAME/ch.add.anchor.sh
}

FABRIC_DEST_PATH="$HERE/distribution"
FABRIC_CONFIG_PATH="$HERE/config"
FABRIC_DEPLOY_PATH="$HERE/deploy"

test -d $FABRIC_CONFIG_PATH || mkdir -p $FABRIC_CONFIG_PATH
test -d $FABRIC_DEPLOY_PATH || mkdir -p $FABRIC_DEPLOY_PATH
test -d $FABRIC_DEST_PATH || mkdir -p $FABRIC_DEST_PATH

echo "FABRIC_DEST_PATH: $FABRIC_DEST_PATH"
echo "FABRIC_CONFIG_PATH: $FABRIC_CONFIG_PATH"

echo "Prepare cryptoconfig data"
prepareCryptoConfig

echo "Prepare scripts for Orderer node"
deployOrderer

deployOrg afip AFIP $BLOCKCHAIN_NETWORK_NAME.$ENVIRONMENT.afip.$ORGS_NETWORK_DOMAIN_NAME peer0 peer0
deployOrg afip AFIP $BLOCKCHAIN_NETWORK_NAME.$ENVIRONMENT.afip.$ORGS_NETWORK_DOMAIN_NAME peer1 peer0

deployOrg comarb COMARB $BLOCKCHAIN_NETWORK_NAME.$ENVIRONMENT.comarb.$ORGS_NETWORK_DOMAIN_NAME peer0 peer0
deployOrg comarb COMARB $BLOCKCHAIN_NETWORK_NAME.$ENVIRONMENT.comarb.$ORGS_NETWORK_DOMAIN_NAME peer1 peer0

deployOrg arba ARBA $BLOCKCHAIN_NETWORK_NAME.$ENVIRONMENT.arba.$ORGS_NETWORK_DOMAIN_NAME peer0 peer0
deployOrg arba ARBA $BLOCKCHAIN_NETWORK_NAME.$ENVIRONMENT.arba.$ORGS_NETWORK_DOMAIN_NAME peer1 peer0

deployClientOrg multiorgs multiorgs.$BLOCKCHAIN_NETWORK_NAME.$ENVIRONMENT.afip.$ORGS_NETWORK_DOMAIN_NAME

deployCreateChannelScript afip peer0

deployJoinChannelScript afip peer1

deployJoinChannelScript arba peer0
deployJoinChannelScript arba peer1

deployJoinChannelScript comarb peer0
deployJoinChannelScript comarb peer1

deployCCdeployScript afip peer0
deployCCdeployScript afip peer1

deployCCdeployScript arba peer0
deployCCdeployScript arba peer1

deployCCdeployScript comarb peer0
deployCCdeployScript comarb peer1

deployInstantiateCCScript afip peer0
deployUpgradeCCScript afip peer0

deployCallCCScript afip peer0
deployCallCCScript arba peer0
deployCallCCScript comarb peer0

deployUpdateAnchorsPeersScript afip peer0
deployUpdateAnchorsPeersScript arba peer0
deployUpdateAnchorsPeersScript comarb peer0
