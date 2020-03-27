#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

BASE=$(dirname $(readlink -f $0))
source $BASE/.env

CHANNEL_ID=$1

cp solo_to_raft_metadata.json ${1}_solo_to_raft_metadata.json

PEM=$( cat fabric-instance/crypto-config/peerOrganizations/afip.tribfed.gob.ar/peers/orderer.afip.tribfed.gob.ar/tls/server.crt | base64 -w0 )

sed -i 's/PEM/'${PEM}'/g' ${1}_solo_to_raft_metadata.json
sed -i 's/solo/etcdraft/g' ${1}_solo_to_raft_metadata.json



