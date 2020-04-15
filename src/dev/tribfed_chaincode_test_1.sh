#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

die() {
    red_echo "$@"
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

readonly PF='{
   "id":20104249729,
   "persona":{
      "id":20104249729,
      "tipoid":"C",
      "tipo":"F",
      "estado":"A",
      "nombre":"XXXXXXXXXXXX",
      "apellido":"XXXXXXXX",
      "materno":"XXXXXXX",
      "sexo":"M",
      "nacimiento":"1952-05-25",
      "documento":{
         "tipo":96,
         "numero":"XXXXXXXX"
      }
   },
   "impuestos":{
      "11":{
         "impuesto":11,
         "periodo":201807,
         "estado":"BD",
         "dia":31,
         "motivo":{
            "id":64
         },
         "inscripcion":"1994-03-01",
         "ds":"2003-04-14"
      },
      "20":{
         "impuesto":20,
         "periodo":201808,
         "estado":"BD",
         "dia":31,
         "motivo":{
            "id":40
         },
         "inscripcion":"2007-11-01",
         "ds":"2018-05-18"
      },
      "21":{
         "impuesto":21,
         "periodo":201105,
         "estado":"NA",
         "dia":1,
         "motivo":{
            "id":109
         },
         "inscripcion":"2007-11-01",
         "ds":"2011-09-06"
      },
      "30":{
         "impuesto":30,
         "periodo":201811,
         "estado":"AC",
         "dia":1,
         "motivo":{
            "id":44
         },
         "inscripcion":"2018-10-16",
         "ds":"2018-10-16"
      },
      "308":{
         "impuesto":308,
         "periodo":200101,
         "estado":"AC",
         "dia":1,
         "motivo":{
            "id":64
         },
         "inscripcion":"1994-03-01",
         "ds":"2003-04-14"
      },
      "5243":{
         "impuesto":5243,
         "periodo":201808,
         "estado":"BD",
         "dia":31,
         "motivo":{
            "id":557
         },
         "inscripcion":"2018-07-12",
         "ds":"2018-07-12"
      },
      "5244":{
         "impuesto":5244,
         "periodo":201808,
         "estado":"BD",
         "dia":31,
         "motivo":{
            "id":555
         },
         "inscripcion":"2018-07-12",
         "ds":"2018-07-12"
      }
   },
   "categorias":{
      "20.61":{
         "impuesto":20,
         "categoria":61,
         "periodo":201804,
         "estado":"BD",
         "ds":"2018-05-18"
      },
      "20.62":{
         "impuesto":20,
         "categoria":62,
         "periodo":201808,
         "estado":"BD",
         "ds":"2011-09-06"
      },
      "21.11":{
         "impuesto":21,
         "categoria":11,
         "periodo":201105,
         "estado":"AC",
         "ds":"2011-09-06"
      }
   },
   "contribmunis":{
      "5244.98":{
         "impuesto":5244,
         "municipio":98,
         "provincia":3,
         "desde":"2018-07-01",
         "ds":"2018-07-12"
      }
   },
   "etiquetas":{
      "39":{
         "etiqueta":39,
         "periodo":20090407,
         "estado":"BD",
         "ds":"2009-04-07"
      },
      "77":{
         "etiqueta":77,
         "periodo":20080208,
         "estado":"BD",
         "ds":"2008-02-08"
      },
      "108":{
         "etiqueta":108,
         "periodo":20110531,
         "estado":"BD",
         "ds":"2013-08-08"
      }
   },
   "actividades":{
      "1.883-842100":{
         "org":1,
         "actividad":"883-842100",
         "orden":1,
         "desde":"2018-06-01",
         "ds":"2018-06-29"
      },
      "1.883-773030":{
         "org":1,
         "actividad":"883-773030",
         "orden":2,
         "desde":"2018-06-01",
         "ds":"2018-07-12"
      },
      "1.883-772099":{
         "org":1,
         "actividad":"883-772099",
         "orden":3,
         "desde":"2018-06-01",
         "ds":"2018-07-12"
      }
   },
   "domicilios":{
      "1.1.1":{
         "org":1,
         "tipo":1,
         "orden":1,
         "estado":11,
         "provincia":7,
         "localidad":"BARRIO-ACOSTA-NORTE",
         "cp":"5000",
         "nomenclador":"2115",
         "calle":"XXXXXXXXX.",
         "numero":1880,
         "unidad":"A",
         "piso":"02",
         "ds":"2018-07-12"
      },
      "1.2.1":{
         "org":1,
         "tipo":2,
         "orden":1,
         "estado":2,
         "provincia":7,
         "cp":"1429",
         "calle":"XXXXXXXXXXXXXXXXX",
         "numero":3377,
         "unidad":"A",
         "piso":"02",
         "ds":"2003-04-14"
      }
   },
   "emails":{
      "1":{
         "orden":1,
         "direccion":"XXXXXXXX@XXXX.XXX",
         "tipo":1,
         "estado":2,
         "ds":"2018-06-29"
      }
   },
   "telefonos":{
      "1":{
         "orden":1,
         "pais":200,
         "area":11,
         "numero":99999999,
         "tipo":2,
         "linea":1,
         "ds":"2018-06-29"
      }
   },
   "archivos":{
      "1":{
         "orden":1,
         "tipo":1,
         "ds":"2018-06-29"
      },
      "2":{
         "orden":2,
         "tipo":2,
         "ds":"2018-06-29"
      },
      "3":{
         "orden":3,
         "tipo":3,
         "ds":"2018-06-29"
      }
   }
}'

readonly PJ='{
   "id":30444444440,
   "persona":{
      "id":30444444440,
      "tipoid":"C",
      "tipo":"J",
      "estado":"A",
      "razonsocial":"XXXXX-XXX",
      "formajuridica":78,
      "mescierre":12,
      "contratosocial":"2008-02-19"
   },
   "impuestos":{
      "10":{
         "impuesto":10,
         "periodo":198010,
         "estado":"AC",
         "dia":1,
         "motivo":{
            "id":44
         },
         "inscripcion":"1980-10-01",
         "ds":"2003-06-07"
      },
      "30":{
         "impuesto":30,
         "periodo":198903,
         "estado":"AC",
         "dia":1,
         "motivo":{
            "id":44
         },
         "inscripcion":"1989-03-01",
         "ds":"2003-06-07"
      }
   },
   "jurisdicciones":{
      "900.0":{
         "org":900,
         "provincia":0,
         "desde":"2020-01-01",
         "ds":"2020-01-01"
      },
      "900.1":{
         "org":900,
         "provincia":1,
         "desde":"2020-01-01",
         "ds":"2020-01-01"
      }
   },
   "cmsedes":{
      "900.0":{
         "org":900,
         "provincia":0,
         "desde":"2020-01-01",
         "ds":"2020-01-01"
      }
   },
   "actividades":{
      "1.883-120091":{
         "org":1,
         "actividad":"883-120091",
         "orden":1,
         "desde":"2013-11-01",
         "ds":"2014-10-02"
      },
      "1.883-120099":{
         "org":1,
         "actividad":"883-120099",
         "orden":2,
         "desde":"2013-11-01",
         "ds":"2014-10-02"
      }
   },
   "domicilios":{
      "1.1.1":{
         "org":1,
         "tipo":1,
         "orden":1,
         "estado":6,
         "provincia":1,
         "localidad":"MERLO",
         "cp":"1722",
         "nomenclador":"72",
         "calle":"XX-XXXXXXXXX",
         "numero":26950,
         "ds":"2004-02-04"
      },
      "1.2.1":{
         "org":1,
         "tipo":2,
         "orden":1,
         "estado":2,
         "provincia":1,
         "localidad":"MERLO",
         "cp":"1722",
         "calle":"XXXXXXXXX",
         "numero":26950,
         "ds":"2003-06-07"
      },
      "1.3.1":{
         "org":1,
         "tipo":3,
         "orden":1,
         "estado":6,
         "provincia":7,
         "localidad":"MAIPU",
         "cp":"5515",
         "nomenclador":"5667",
         "calle":"XXXXXXXXXXX",
         "numero":2900,
         "adicional":{
            "tipo":5,
            "dato":"XXXXXXXXXXXXXXXX"
         },
         "ds":"2004-10-06"
      },
      "1.3.2":{
         "org":1,
         "tipo":3,
         "orden":2,
         "estado":6,
         "provincia":16,
         "localidad":"RESISTENCIA",
         "cp":"3500",
         "nomenclador":"3983",
         "calle":"XXXXXXXXXXXX",
         "adicional":{
            "tipo":5,
            "dato":"XXXXXXXXXXXXXXXX"
         },
         "ds":"2004-10-06"
      }
   },
   "telefonos":{
      "1":{
         "orden":1,
         "pais":200,
         "area":220,
         "numero":9999999,
         "tipo":6,
         "linea":1,
         "ds":"2013-12-16"
      }
   }
}'

for f in GetVersion GetFunctions; do
   echo "#################################################### (CHAINCODE $f)"
   query "$f"
done

for p in "$PF" "$PJ"; do
    id=$(echo "$p" | jq .id)
    echo "#################################################### (CHAINCODE DelPersona $id)"
    invoke DelPersona "$id" || true
    echo "#################################################### (CHAINCODE PutPersona $id)"
    invoke PutPersona "$p"
    echo "#################################################### (CHAINCODE GetPersona $id)"
    query GetPersona "$id"
done
