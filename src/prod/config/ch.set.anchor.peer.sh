#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))
source $BASE/.env

$BASE/ch.config.tool.sh set_anchor -x \
                        -m $MSPID \
                        -n $ANCHOR_PEER_NAME \
                        -p $PEER_PORT \
