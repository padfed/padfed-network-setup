#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

if [[ $# == 0 ]]; then
   echo "Cantidad de argumentos [$#] inesperada."
   echo "$0 functionName [arg1 arrg2 ...]"
   exit 1
fi

./cc.invoke.sh query "$@"
