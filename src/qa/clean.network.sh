#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
ME=$(basename $0)
HERE=$(dirname $(readlink -f $0))

rm -rf $HERE/distribution
sudo rm -rf $HERE/deploy
