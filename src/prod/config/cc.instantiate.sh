#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
BASE=$(dirname $(readlink -f $0))

WAIT="nowait"
while [[ $# -gt 0 ]]; do
  case $1 in
    --wait|-w)
      WAIT="wait"
      shift
      ;;
    -*)
      echo "Argumento inválido: $1"
      exit 1
      ;;
    *)
      VERSION=$1
      shift
      ;;
  esac
done

if [[ -z $VERSION ]]; then
  echo "Debe indicar la versión del chaincode a instanciar."
  exit 1
fi

$BASE/cc.activate.sh instantiate $VERSION $WAIT
