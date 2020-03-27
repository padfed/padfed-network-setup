#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

die() {
    echo "$@"
    exit 1
}

cc() {
    local OP=$1
    shift
    local ARGS='{"Args":[]}'
    ARGS=$(jq <<<$ARGS -c ".function=\"$1\"")
    shift
    for ARG in "$@"
    do
        ARG=$(jq -c <<<$ARG . || echo $ARG)
        ARGS=$(jq <<<$ARGS -c '.Args+=[$a]' --arg a $ARG)
    done
    ./tribfed_chaincode_invoke.sh $OP $ARGS
}

invoke() {
    cc invoke "$@"
}

query() {
    cc query "$@"
}

echo '#################################################### (test putPersonas)'
invoke PutPersonas '[
      {
         "id":20176058650,
         "persona":{
            "id":20176058650,
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
         }
      },
      {
         "id":20322608846,
         "persona":{
            "id":20322608846,
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
         }
      }
   ]'

echo '#################################################### (CHAINCODE DELETE PERSONA)'
invoke delPersona 20176058650

echo '#################################################### (test putPersona I[debe fallar])'
P='{
  "id":30537647716,
  "persona":{
      "id": 30537647716,
      "tipo": "J",
      "estado": "A",
      "razonSocial": "FABRICACIONES_INDUSTRIALES_SA",
      "formaJuridica": 1,
      "inscripcion": "1965-11-01",
      "fechaCierre": "1965-11-01"
  }
}'

!(invoke PutPersona "$P") || die "Debió fallar!"

echo '#################################################### (test putPersona II)'
P='{
  "id":20322608846,
  "persona":{
      "id": 20322608846,
      "tipo": "F",
      "tipoid":"C",
      "estado": "A",
      "nombre": "ANTONIO",
      "apellido": "OTONIO",
      "documento":{
           "tipo":90,
           "numero":"XX"
      },
      "nacimiento": "1965-11-01",
      "fallecimiento": "1965-11-01"
  }
}'
invoke PutPersona "$P"


echo '#################################################### (test putPersona III)'
P='{
  "id": 20224235020,
  "persona":{
      "id": 20224235020,
      "tipo": "F",
      "estado": "A",
      "nombre": "COCO",
      "tipoid":"C",
      "apellido": "KARP",
      "documento":{
           "tipo":90,
           "numero":"17605865"
      },
      "nacimiento": "1965-11-01"
  },
  "impuestos": {
   "11":
    {
      "impuesto": 11,
      "periodo": 201000,
      "estado": "AC",
      "inscripcion": "2017-11-23"
    },
    "30":
    {
      "impuesto": 30,
      "periodo": 201001,
      "estado": "AC",
      "inscripcion": "2017-11-20"
    },
    "32":
    {
      "impuesto": 32,
      "periodo": 201001,
      "estado": "AC",
      "inscripcion": "2017-11-21"
    },
    "33":
    {
      "impuesto": 33,
      "periodo": 201002,
      "estado": "AC",
      "inscripcion": "2017-11-22"
    },
    "34":
    {
      "impuesto": 34,
      "periodo": 201003,
      "estado": "AC",
      "inscripcion": "2017-11-23"
    }
  }
}'
invoke PutPersona "$P"

echo '#################################################### (test queryByKeyRange)'
query queryByKeyRange "per:20104249720" "per:30000000000"

echo "TODO OK"
