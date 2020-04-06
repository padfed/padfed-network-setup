#!/bin/bash
[[ -v DEBUG ]] && set -x
set -Eeuo pipefail

BASE=$(dirname $(readlink -f $0))

source $BASE/.env
source $BASE/lib-cctest.sh
source $BASE/test-data.sh

usage() {
   echo "Uso: $(basename $0) [-d|--debug] [-v|--verbose]" 1>&2
   exit 1
}

OPTS=$(getopt -o 'dv' -l 'debug,verbose' -- "$@")
eval set -- "$OPTS"
while true; do
   case "$1" in
      -d|--debug) DEBUG=1; shift;;
      -v|--verbose) VERBOSE=1; shift;;
      --) shift; break;;
      *) usage;;
   esac
done

################################################################################
###### CHAINCODE INFO

query GetVersion
query GetFunctions

################################################################################
###### FUNCION INEXISTENTE

query -fo NoExiste | assert -R 'test("function '"'NoExiste'"' is not implemented")'

################################################################################
###### PERSONAS

invoke -a DelPersona "$P1_ID"
query -o HasPersona "$P1_ID" | assert ".content == false"
invoke PutPersona "$P1"
query -o GetPersona "$P1_ID" | assert ".content.persona.id == $P1_ID"
invoke PutPersonaList "[$P2,$P1]"
query -o HasPersona "$P1_ID" | assert ".content == true"
query -o HasPersona "$P2_ID" | assert ".content == true"
query GetPersonaRange 20000000001 34999999990 | assert ".content | length == 2"
invoke DelPersonaRange 20000000001 34999999990
query -o GetPersonaRange 20000000001 34999999990 | assert ".content == []"
invoke PutPersona "$P1"
invoke PutPersona "$P2"
invoke DelPersona "$P1_ID"
invoke DelPersona "$P2_ID"
query GetPersonaRange 20000000001 34999999990 | assert ".content == []"

################################################################################
###### STATE

invoke PutStates 'a1' 'foo'
query -o GetStates 'a1' | assert '.content == "foo"'
invoke PutStates 'a1' 'bar' 'a2' 'baz' 'a3' 'qux'
query -o GetStates 'a1' | assert '.content == "bar"'
query -o GetStates '["a1","a2"]' | assert '.content == [{"key":"a1","content":"bar"},{"key":"a2","content":"baz"}]'
query -o GetStates '[["a"]]' | assert '.content[0] == [{"key":"a1","content":"bar"},{"key":"a2","content":"baz"},{"key":"a3","content":"qux"}]'
query -o GetStates '[["a1","a2"]]' | assert '.content[0] == [{"key":"a1","content":"bar"}]'
query -o GetStates '[["a1","a3"]]' | assert '.content[0] == [{"key":"a1","content":"bar"},{"key":"a2","content":"baz"}]'
query GetStatesHistory 'a1'
query GetStatesHistory 'a2'
query GetStatesHistory '["a1"]'
query GetStatesHistory '[["a1"]]'
query GetStatesHistory '[["a1","a2"]]'
query GetStatesHistory '[["a1","az"]]'
query GetStatesHistory '[["a"]]'
invoke DelStates '[["a"]]'
query GetStates '[["a"]]'

################################################################################
###### IMPUESTOS

invoke PutImpuesto "$I1"
query HasImpuesto "$I1_ID"
query GetImpuesto "$I1_ID"
invoke PutImpuesto "$I2"
query GetImpuesto "$I2_ID"
query HasImpuesto "$I2_ID"
query GetImpuestoAll
query GetImpuestoRange 1 99
invoke DelImpuesto "$I1_ID"
invoke DelImpuesto "$I2_ID"
query GetImpuestoAll
invoke PutImpuestoList "[$I1,$I2]"
query GetImpuestoAll
invoke DelImpuestoRange 1 25
query GetImpuestoAll
invoke DelImpuestoRange 1 9999

################################################################################
################################################################################

failreport
