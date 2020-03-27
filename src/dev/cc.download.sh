#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
readonly BASE="$(dirname $(readlink -f $0))"

"$BASE/../prod/config/cc.download.sh" "$@"
