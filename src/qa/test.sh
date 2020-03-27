#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
ME=$(basename $0)
HERE=$(dirname $(readlink -f $0))
BASE="$HERE/deploy/nodes"

if [[ "$*" =~ "--debug" ]]; then
  set -x
  export DEBUG=1
fi

source $HERE/.env

bold=$(tput bold)
green=$(tput setaf 2)
normal=$(tput sgr0)

log() {
  echo -e "$*" | while read L; do
    printf "$bold$green[$ME]$normal $L\n"
  done
}

chaincodeCall() {
  log Calling chaincode $2 $3 on $1 node...
  local NODE=$1
  shift
  $BASE/$NODE/cc.call.sh "$@"
  log Done.
}

chaincodeCall afip.peer0 invoke putPersona '{
   "id":20066675573,
   "persona":{
      "id":20066675573,
      "tipoid":"C",
      "tipo":"F",
      "estado":"A",
      "nombre":"XXXX",
      "apellido":"XXXXXXXXX",
      "materno":"XXXXXX",
      "sexo":"M",
      "nacimiento":"1891-01-01",
      "fallecimiento":"2018-04-02",
      "documento":{
         "tipo":90,
         "numero":"XX"
      },
      "ds":"2019-02-21"
   },
   "impuestos":{
      "301":{
         "impuesto":301,
         "periodo":198907,
         "estado":"AC",
         "dia":27,
         "motivo":34,
         "inscripcion":"2004-08-19",
         "ds":"2012-01-02"
      }
   }
}'

chaincodeCall afip.peer0 query getPersona 20066675573

chaincodeCall afip.peer0 invoke delPersona 20066675573

log "Success!"
