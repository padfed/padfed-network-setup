#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

readonly BASE=$(dirname "$(readlink -f "$0")")
. "$BASE/lib.sh"

echo_running

PATH=$(realpath ../bin):$PATH
[[ -d $PWD/bin ]] && PATH="$PWD/bin:$PATH"

#readonly -A CONFIG_PATHS_MAP=(
readonly -A CONFIG_MSP_VALUE_MAP=(
      # [Application|Orderer].groups.[MSPID].values.MSP.value
      [anchor_peer]=".values.AnchorPeers.value.anchor_peers[0]"
      [fabric_node_ous]=".values.MSP.value.config.fabric_node_ous"
      [fabric_node_ous_admin]=".values.MSP.value.config.fabric_node_ous.admin_ou_identifier.certificate"
      [fabric_node_ous_client]=".values.MSP.value.config.fabric_node_ous.client_ou_identifier.certificate"
      [fabric_node_ous_peer]=".values.MSP.value.config.fabric_node_ous.peer_ou_identifier.certificate"
      [fabric_node_ous_orderer]=".values.MSP.value.config.fabric_node_ous.orderer_ou_identifier.certificate"
      [organizational_unit_identifiers]=".values.MSP.value.config.organizational_unit_identifiers"
      [organizational_unit_identifier]=".values.MSP.value.config.organizational_unit_identifiers[0].certificate"
      [admins]=".values.MSP.value.config.admins"
      [root_certs]=".values.MSP.value.config.root_certs"
      [intermediate_certs]=".values.MSP.value.config.intermediate_certs"
      [revocation_list]=".values.MSP.value.config.revocation_list"
      [tls_root_certs]=".values.MSP.value.config.tls_root_certs"
      [tls_intermediate_certs]=".values.MSP.value.config.tls_intermediate_certs"
)
readonly -A CONFIG_ORDERER_VALUE_MAP=(
      # Orderer
      [absolute_max_bytes]=".values.BatchSize.value.absolute_max_bytes"
      [max_message_count]=".values.BatchSize.value.max_message_count"
      [preferred_max_bytes]=".values.BatchSize.value.preferred_max_bytes"
      [timeout]=".values.BatchTimeout.value.timeout"
      [election_tick]=".values.ConsensusType.value.metadata.options.election_tick"
      [max_inflight_blocks]=".values.ConsensusType.value.metadata.options.max_inflight_blocks"
      [snapshot_interval_size]=".values.ConsensusType.value.metadata.options.snapshot_interval_size"
      [max_inflight_blocks]=".values.ConsensusType.value.metadata.options.max_inflight_blocks"
      [tick_interval]=".values.ConsensusType.value.metadata.options.tick_interval"
      [consenter]=".values.ConsensusType.value.metadata.consenters"
      [consenters]=".values.ConsensusType.value.metadata.consenters"
)

readonly KEY_CRYPTO_MATERIAL_SET="common_ica_certs admins root_certs intermediate_certs tls_root_certs tls_intermediate_certs revocation_list"

readonly KEY_CRYPTO_MATERIAL="$KEY_CRYPTO_MATERIAL_SET fabric_node_ous_admin fabric_node_ous_client fabric_node_ous_peer fabric_node_ous_orderer organizational_unit_identifier"

function key_is_msp_value() {
   [[ ${CONFIG_MSP_VALUE_MAP[$1]:+key_found} == "key_found" ]]
}

function key_is_orderer_value() {
   [[ ${CONFIG_ORDERER_VALUE_MAP[$1]:+key_found} == "key_found" ]]
}

function key_is_msp_or_orderer_value() {
   if ( key_is_msp_value "$1" );     then return 0; fi
   if ( key_is_orderer_value "$1" ); then return 0; fi
   return 1 # false
}

function key_is_readable() {
   [[ $1 == "none" ]] && return 0
   if ( key_is_msp_or_orderer_value "$1" ); then return 0; fi
   return 1 # false
}

function get_path_from_key() {
   case "$1" in
   none ) echo "."
          return 0
          ;;
   OrdererAddresses )
          echo ".channel_group.values.OrdererAddresses.value.addresses"
          return 0
          ;;
   esac
   if ( key_is_msp_value "$1" );     then { echo "${CONFIG_MSP_VALUE_MAP[$1]}";     return 0; } fi
   if ( key_is_orderer_value "$1" ); then { echo "${CONFIG_ORDERER_VALUE_MAP[$1]}"; return 0; } fi
   echo_red "ERROR: key [$1] unknow"
   exit 1
}

function key_is_crypto_material_set() {
   for k in $KEY_CRYPTO_MATERIAL_SET; do
       [[ $k == "$1" ]] && return 0
   done
   return 1 # Not exists
}

function key_is_crypto_material() {
   for k in $KEY_CRYPTO_MATERIAL; do
       [[ $k == "$1" ]] && return 0
   done
   return 1 # Not exists
}

function check_org_value() {
   local string_file_or_dir="$1"
   local l_value

   if [[ $string_file_or_dir == "none" ]]; then
      echo_red "ERROR: task [$TASK] -k [$KEY] requires -v <org config.json>"
      exit 1
   fi
   if   [[ -f $string_file_or_dir && -s $string_file_or_dir ]]; then
        echo "Adding org from file [$string_file_or_dir] ..."
        l_value=$( cat "$string_file_or_dir" )

   elif [[ -d $string_file_or_dir ]]; then
        if [[ ! $( basename "$string_file_or_dir" ) == "msp" ]]; then
           echo_red "ERROR: task [$TASK] -v [$string_file_or_dir] must be a msp directory"
           exit 1
        fi
        echo "Adding org from msp-dir [$string_file_or_dir] ..."
        for yaml in configtx.yaml config.yaml; do
            if [[ ! -f "$string_file_or_dir/$yaml" ]]; then
               echo_red "ERROR: task [$TASK] -v [$string_file_or_dir] dir must contain a $yaml"
               exit 1
            fi
        done
        l_value=$(configtxgen -configPath "$string_file_or_dir" -printOrg "$MSPID")
   else
        l_value="$string_file_or_dir"
   fi

   local l_jpath=".values.MSP.value.config.fabric_node_ous.client_ou_identifier.organizational_unit_identifier"
   local l_found
         l_found=$( echo "$l_value" | jq -r "$l_jpath" )
   local l_want="client"

   if [[ $l_want != "$l_found" ]]; then
      echo_red "ERROR: task [$TASK] -k [$KEY] -v [config json] whitout client_ou_identifier"
      echo_red "want [$l_want] - found [$l_found]"
      exit 1
   fi

   # OU=admin - New from 1_4_3
   l_jpath=".values.MSP.value.config.fabric_node_ous.admin_ou_identifier.organizational_unit_identifier"
   l_found=$( echo "$l_value" | jq -r "$l_jpath" )
   l_want="admin"
   if [[ $l_want != "$l_found" ]]; then
      echo_red "ERROR: $l_name: org config json whitout admin_ou_identifier"
      echo_red "want [$l_want] - found [$l_found]"
      exit 1
   fi

   l_jpath=".values.MSP.value.config.name"
   l_found=$( echo "$l_value" | jq -r "$l_jpath" )
   if [[ $MSPID != "$l_found" ]]; then
      echo_red "ERROR: $l_name org config json whith name [$l_found], want [$MSPID]"
      exit 1
   fi

   GROUP_CONFIG_JSON="$l_value"
}

function check_consenter_json() {
   local string_or_file="$1"
   local l_value

   if [[ $string_or_file == "none" ]]; then
      echo_red "ERROR: task [$TASK] -k [$KEY] requires -v <consenter.json>"
      exit 1
   fi
   if [[ -s $string_or_file ]]; then
      echo "Adding consenter from file [$string_or_file] ..."
      l_value=$( cat "$string_or_file" )
   else
      l_value="$string_or_file"
   fi

   local l_client_tls_cert l_server_tls_cert l_host l_port

   l_client_tls_cert=$( echo "$l_value" | jq -r ".client_tls_cert" )
   l_server_tls_cert=$( echo "$l_value" | jq -r ".server_tls_cert" )
   l_host=$( echo "$l_value" | jq -r ".host" )
   l_port=$( echo "$l_value" | jq -r ".port" )

   if [[ -z "$l_client_tls_cert" ]]; then
      echo_red "ERROR: task [$TASK] -k [$KEY] consenter.client_tls_cert [$l_client_tls_cert] not found in json"
      exit 1
   fi
   check_single_b64_x509_crt " consenter.client_tls_cert" "$l_client_tls_cert"

   if [[ -z "$l_server_tls_cert" ]]; then
      echo_red "ERROR: task [$TASK] -k [$KEY] consenter.server_tls_cert [$l_server_tls_cert] not found in json"
      exit 1
   fi
   check_single_b64_x509_crt " consenter.server_tls_cert" "$l_server_tls_cert"

   if [[ ! $l_host =~ orderer* ]]; then
      echo_red "ERROR: task [$TASK] -k [$KEY] consenter.host [$l_host] must be an orderer name"
      exit 1
   fi
   if [[ ! $l_port == *[[:digit:]]* ]]; then
      echo_red "ERROR: task [$TASK] -k [$KEY] consenter.port [$l_port] must be an integer"
      exit 1
   fi

   local l_jp
         l_jp=$( get_path_from_key consenters )

   for host in $(echo "$GROUP_CONFIG_JSON" | jq -r "${l_jp}[].host" ); do
       if [[ $host == "$l_host" ]]; then
          echo_red "ERROR: task [$TASK] -k [$KEY] consenter.host [$host] alreadey exists"
          exit 1
       fi
   done

   l_jp=$( get_path_from_key OrdererAddresses )

   for host in $( jq -r "$l_jp" "$MODIFIED_TRIMMED_CONFIG_JSON" ); do
       if [[ $host =~ $l_host* ]]; then
          echo_red "ERROR: task [$TASK] -k [$KEY] consenter.host [$l_host] alreadey exists in OrdererAddresses"
          exit 1
       fi
   done
}

function check_single_b64_x509_crt() {
   local l_name="$1"
   local l_value="$2"
   local l_tmpfile
   l_tmpfile=$( mktemp2 "$l_name.crt" )
   echo "$l_value" | base64 --decode -i > "$l_tmpfile"
   if ! ( is_x509_crt "$l_tmpfile" ); then
      echo_red "ERROR: $l_name [${l_value:0:40}...] is not a x509 certificate"
      exit 1;
   fi
}

function check_single_b64_crl() {
   local l_name="$1"
   local l_value="$2"
   local l_tmpfile
   l_tmpfile=$( mktemp2 "$l_name.crl" )
   echo "$l_value" | base64 --decode -i > "$l_tmpfile"
   if ! ( is_crl "$l_tmpfile" ); then
      echo_red "ERROR: $l_name [${l_value:0:40}...] is not a crl certificate"
      exit 1;
   fi
}

function check_array_b64_x509_crt() {
   local l_empty="true"
   for row in $(echo "$2" | jq -r '.[]'); do
       check_single_b64_x509_crt "$1" "$row";
       local l_empty="false"
   done
   if [[ $l_empty == "true" ]]; then
      echo_red "ERROR: $1 is an empty array"
      exit 1
   fi
}

function check_b64_x509_crt() {
   case $1 in
   \[*\] ) check_array_b64_x509_crt  "$1" "$2" ;;
   * )     check_single_b64_x509_crt "$1" "$2" ;;
   esac
}

function check_exists() {
   local l_name="$1"
   local l_value="$2"
   local l_json_name="$3"
   local l_json_value="$4"

   if  [[ ! $l_json_value == *$l_value* ]]; then
       echo_red "ERROR: $l_name [${l_value:0:40}...] does not exist in $CHANNEL_GROUP.$MSPID $l_json_name"
       exit 1
   fi
}

function mktemp2() {
   mkdir -p ./tmp
   echo "./tmp/$$.${TASK,,}.${CHANNEL_GROUP,,}.${MSPID:-none}.$1"
}

function proto_encode() {
   configtxlator proto_encode --input "$1" --type common.Config --output "$1.pb"
}

function update_channel() {
   local original="$1"
   local updated="$2"

   for f in "$original" "$updated"; do
       proto_encode "$f"
       check_file   "$f.pb"
   done

   readonly UPDATE_PB=$( mktemp2 update.pb )

   configtxlator compute_update \
               --channel_id "$CHANNEL_NAME" \
               --original  "$original.pb" \
               --updated   "$updated.pb" \
               --output    "$UPDATE_PB"

   check_file "$UPDATE_PB"

   configtxlator proto_decode \
               --input "$UPDATE_PB" \
               --type common.ConfigUpdate \
               | jq . > "$UPDATE_PB.json"

   check_file "$UPDATE_PB.json"

   local value
   value=$( cat "$UPDATE_PB.json" )
   echo "{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"${CHANNEL_NAME}\",\"type\":2}},\"data\":{\"config_update\":${value}}}}" | jq . > "$UPDATE_PB-envelop.json"

   check_file "$UPDATE_PB-envelop.json"

   readonly FINAL_PB="${UPDATE_PB}-envelop-FINAL.pb"

   configtxlator proto_encode \
               --input  "$UPDATE_PB-envelop.json" \
               --type    common.Envelope \
               --output "$FINAL_PB"

   check_file "$FINAL_PB"

   echo "update tx protobuf generated [$FINAL_PB]"

   if [[ $OUTPUT != none ]]; then
      cp "$FINAL_PB" "$OUTPUT"
      echo "update tx protobuf generated [$OUTPUT]"
   fi

   [[ $EXECUTE == "true" ]] && "$BASE/ch.update.sh" -t "$FINAL_PB" -c "$CHANNEL_NAME"

   return 0
}

function replace_b64_x590() {
   check_exists "-v" "$1" "config" "$GROUP_CONFIG_JSON"
   case $TASK in
   *crt ) check_single_b64_x509_crt " -v" "$1"
          check_single_b64_x509_crt " -V" "$2"
          ;;
   *crl ) check_single_b64_crl " -v" "$1"
          check_single_b64_crl " -V" "$2"
          ;;
   esac
   GROUP_CONFIG_JSON=${GROUP_CONFIG_JSON//$1/$2} # replace all

   check_exists "-V" "$2" "changed config" "$GROUP_CONFIG_JSON"
}

# TODO: Refactorizar

function add_consenter_item() {
   echo "Adding consenter item ..."

   local l_jp
         l_jp="$( get_path_from_key consenters )"

   GROUP_CONFIG_JSON=$( echo "$GROUP_CONFIG_JSON" | jq "$l_jp += [${1}]" )

   if [[ -z $GROUP_CONFIG_JSON ]]; then
      echo_red "ERROR: task [$TASK] -k [$KEY] consenter could not be added (empty result)"
      exit 1
   fi
   local l_host
         l_host=$( echo "${1}" | jq -r ".host" )

   for host in $(echo "$GROUP_CONFIG_JSON" | jq -r "${l_jp}[].host" ); do
       [[ $host == "$l_host" ]] && return 0 # OK !!!
   done

   echo_red "ERROR: task [$TASK] -k [$KEY] consenter.host [$host] could not be added"
   exit 1
}

function modify_trimmed_config_json() {
   jq "$1" "$MODIFIED_TRIMMED_CONFIG_JSON" > "$MODIFIED_TRIMMED_CONFIG_JSON".tmp
   mv "$MODIFIED_TRIMMED_CONFIG_JSON".tmp "$MODIFIED_TRIMMED_CONFIG_JSON"
}

function add_orderer_address() {
   echo "Adding orderer address item ..."

   local l_value="$1"
   local l_host
         l_host=$( echo "$l_value" | jq -r ".host" )
   local l_port
         l_port=$( echo "$l_value" | jq -r ".port" )
   local l_item="$l_host:$l_port"
   local l_jp
         l_jp=$( get_path_from_key OrdererAddresses )

   modify_trimmed_config_json "$l_jp += [\"$l_item\"]"

   if [[ ! -s $MODIFIED_TRIMMED_CONFIG_JSON ]]; then
      echo_red "ERROR: task [$TASK] consenter [$l_item] could not be added on OrdererAddresses (empty result)"
      exit 1
   fi

   for item in $( jq -r "${l_jp}[]" "$MODIFIED_TRIMMED_CONFIG_JSON" ); do
       [[ $item == "$l_item" ]] && return 0 # OK !!!
   done

   echo_red "ERROR: task [$TASK] consenter [$l_item] could not be added on OrdererAddresses"
   exit 1
}

function add_msp_key_item() {

   local l_jp
         l_jp="$( get_path_from_key "$1" )"
   echo "key_path [$l_jp]"

   GROUP_CONFIG_JSON="$( echo "$GROUP_CONFIG_JSON" | jq "$l_jp += [\"${2}\"]" )"

   if [[ -z $GROUP_CONFIG_JSON ]]; then
      echo_red "ERROR: [${2:0:40}...] could not be added (empty result)"
      exit 1
   fi

   for item in $(echo "$GROUP_CONFIG_JSON" | jq -r "${l_jp}[]" ); do
       [[ $item == "$2" ]] && return 0 # OK !!!
   done

   echo_red "ERROR: [${2:0:40}...] could not be added"
   exit 1
}

function set_anchor() {
   local l_name="$1"
   local l_port=$2

   local l_anchor_peers="{\"AnchorPeers\":{\"mod_policy\": \"Admins\",\"value\":{\"anchor_peers\": [{\"host\": \"$l_name\",\"port\": $l_port}]},\"version\": \"0\"}}"

   GROUP_CONFIG_JSON=$( echo "$GROUP_CONFIG_JSON" | jq ".values += $l_anchor_peers" )
}

function is_decodable() {
   [[ $TASK == "read" ]] && return 1 # no decodeable
   if ( key_is_crypto_material "$key" ); then return 0; fi
   return 1 # no decodeable
}

function read_or_decode() {
   local key="$1"
   if ! ( key_is_readable "$1" ); then
      echo_red "ERROR: -k [$key] unknow"
      exit 1
   fi
   local key_path
         key_path=$( get_path_from_key "$1" )

   echo "key [$key]"
   echo "key path [$key_path]"
   local value
         value=$( echo "$GROUP_CONFIG_JSON" | jq "$key_path" )

   if [[ -z $value ]]; then
      echo "key [$key] not found or empty"
      return 0
   fi

   if ( is_decodable "$TASK" "$key" ); then
      readonly RESULT=$( echo "$value" | base64 --decode -i )
      if [[ $OUTPUT == none ]]; then
         echo_green "$TASK key [$key]"
         echo "$RESULT"
      fi
   else
      readonly RESULT=$( echo "$value" | jq . )
      if [[ $OUTPUT == none ]]; then
         echo_green "$TASK key [$key]"
         echo "$value" | jq
      fi
   fi

   if [[ $OUTPUT != "none" ]]; then
      echo "$RESULT" > "$OUTPUT"
      check_file "$OUTPUT"
      echo_green "output file [$OUTPUT] available"
   fi
}

function proto_decode_common_block() {
   check_file "$1"
   ls -la "$1"
   rm -f "$2"
   configtxlator proto_decode --input "$1" --type common.Block > "$2"
   check_file "$2"
}

function fetch_config() {
   rm -f "$1"
   "$BASE/ch.fetch.block.sh" config -c "$CHANNEL_NAME" -u "$1"
   check_file "$1"
}

function set_value() {

   local key="$1"
   local new_value="$2"

   if ! ( key_is_msp_or_orderer_value "$key" ); then
      echo_red "ERROR: key [$key] from -f [$KV_FILE] not supported"
      exit 1
   fi

   local key_path
         key_path="$( get_path_from_key "$key" )"
   echo "key_path [$key_path]"
   local current_value
         current_value=$( echo "$GROUP_CONFIG_JSON" | jq -c "$key_path" )

   if [[ $new_value == "$current_value" ]]; then
      echo "WARN: key [$key] from -f [$KV_FILE] has the same value [$new_value] of the one in original config"
      return 0
   fi

   if ( key_is_crypto_material "$key" ); then
        if [[ $MSPID == "none" ]]; then
           echo_red "ERROR: -k [$key] of crypto material type requires -m <MSPID>"
           exit 1
        fi
   fi

   echo "key [$key] new value [$new_value] current value [$current_value]"

   GROUP_CONFIG_JSON=$( echo "$GROUP_CONFIG_JSON" | jq "$key_path = $new_value" )
}

function set_values() {
   while IFS='=' read -r l_key l_value; do
         [[ ! -z $l_key ]] && set_value "$l_key" "$l_value"
   done < "$KV_FILE"
   return 0
}

function dependencies {
    echo "Checking dependencias ..."
    command -V "$BASE/ch.fetch.block.sh"
    command -V "$BASE/ch.update.sh"
    command -V basename
    command -V openssl
    command -V base64
    command -V jq

    command -V configtxgen
    configtxgen -version

    command -V configtxlator
    configtxlator version
}

usage() {
  echo "Usage: $0 task options"
  echo "   task: read|decode|add|set_anchor|replace_crt|replace_crl|set_value|set_values"
  echo "   options:"
  echo "   -o <original config>: fetch (default)|*.pb (protobuf)|*.block (protobuf)|*.protobuf|*.json"
  echo "   -c <channel name>"
  echo "   -m <MSPID>: case sensitive"
  echo "   -g <channel group>: Application|Orderer"
  echo "   -k <key>: org anchor_peer consenter fabric_node_ous $KEY_CRYPTO_MATERIAL"
  echo "   -v <value>:"
  echo "           - pem oneline base64 encoded"
  echo "           - org config: filename (json), string (json) or msp-dir"
  echo "   -V <b64 pem>: "
  echo "           - pem oneline base64 encoded to replace"
  echo "           - some scalar value"
  echo "   -u <output file name>"
  echo "   -x: executes channel update"
}

function main() {

   if [[ $# == 0 ]]; then
      echo_red "ERROR: $# unexpected number of params"
      usage
      exit 1
   fi

   readonly TASK=${1,,};shift
   case $TASK in
   add )           ;;
   set_anchor )    ;;
   set_value )     ;;
   set_values )    ;;
   replace_crt )   ;;
   replace_crl )   ;;
   read | decode ) ;;
   *) echo_red "ERROR: p1 [$TASK] task unknow"
      usage
      exit 1
   esac

   # opts
   CHANNEL_NAME="padfedchannel"
   CHANNEL_GROUP="none"
   MSPID="none"
   ORIGINAL_CONFIG="fetch"
   PEER_NAME="none"
   PEER_PORT=7051
   KEY="none"
   VALUE="none"
   VALUE2="none"
   OUTPUT="none"
   KV_FILE="none"
   EXECUTE="none"

   while getopts "h?o:c:g:m:n:p:k:v:V:f:u:x" opt; do
         case "$opt" in
         h|\?) usage
               exit 0
               ;;
         o) ORIGINAL_CONFIG=$OPTARG ;;
         c) CHANNEL_NAME=${OPTARG,,} ;;
         g) CHANNEL_GROUP=${OPTARG,,} ;;
         m) MSPID=$OPTARG ;;
         n) PEER_NAME=$OPTARG ;;
         p) PEER_PORT=$OPTARG ;;
         k) KEY=$OPTARG ;;
         v) VALUE=$OPTARG ;;
         V) VALUE2=$OPTARG ;;
         f) KV_FILE=$OPTARG ;;
         u) OUTPUT=$OPTARG ;;
         x) EXECUTE="true" ;;
         esac
   done

   if [[ $TASK == "add" ]]; then
      if [[ $KEY == "none" ]]; then
         echo_red "ERROR: task [$TASK] requires -k"
         usage
         exit 1
      fi
      if [[ $VALUE == "none" ]]; then
         echo_red "ERROR: task [$TASK] requires -v"
         usage
         exit 1
      fi
   fi

   case "$CHANNEL_GROUP" in
   none ) if ( key_is_orderer_value "$KEY" ); then
               CHANNEL_GROUP=Orderer
          elif [[ $KEY == "anchor_peer" ]]; then
               CHANNEL_GROUP=Application
          else
               case "$TASK" in
               set_anchor )
                     CHANNEL_GROUP=Application
                     ;;
               read | decode )
                     if [[ $MSPID != "none" ]]; then
                        echo_red "ERROR: task [$TASK] -m [$MSPID] requires -g <Application|Orderer>"
                        exit 1
                     fi
                     ;;
               add ) if [[ $KEY == "org" ]]; then
                        echo_red "ERROR: task [$TASK] -k [$KEY] requires -g <Application|Orderer>"
                        exit 1
                     fi
                     ;;
               set_values )
                     echo_red "ERROR: task [$TASK] requires -g <Application|Orderer>"
                     exit 1
               esac
          fi
          ;;
   application ) CHANNEL_GROUP=Application
                 ;;
   orderer )     CHANNEL_GROUP=Orderer
                 ;;
   *) echo_red "ERROR: -g [$CHANNEL_GROUP] must be Application|Orderer"
      usage
      exit 1
   esac
   echo "CHANNEL_GROUP -g [$CHANNEL_GROUP]"

   case "$ORIGINAL_CONFIG" in
   *.json ) check_param_file " -o" "$ORIGINAL_CONFIG"
            readonly CONFIG_JSON="$ORIGINAL_CONFIG"
            ;;
   *.pb | *.block | *.protobuf )
            check_param_file " -o" "$ORIGINAL_CONFIG"
            readonly CONFIG_JSON=$( mktemp2 "original.$(basename "$ORIGINAL_CONFIG").json" )
            proto_decode_common_block "$ORIGINAL_CONFIG" "$CONFIG_JSON"
            ;;
   fetch )  readonly CONFIG_PB=$(   mktemp2 "original.config.protobuf" )
            readonly CONFIG_JSON=$( mktemp2 "original.config.json" )
            fetch_config "$CONFIG_PB"
            proto_decode_common_block "$CONFIG_PB" "$CONFIG_JSON"
            ;;
   *) echo_red "ERROR: -o [$ORIGINAL_CONFIG] unexpected, must be fetch|*.pb|*.block|*.protobuf|*.json"
      usage
      exit 1
   esac

   readonly ORIGINAL_TRIMMED_CONFIG_JSON="$( mktemp2 original.trimmed.config.json )"
   readonly MODIFIED_TRIMMED_CONFIG_JSON="$( mktemp2 modified.trimmed.config.json )"
   jq .data.data[0].payload.data.config "$CONFIG_JSON" > "$ORIGINAL_TRIMMED_CONFIG_JSON"
   cp "$ORIGINAL_TRIMMED_CONFIG_JSON" "$MODIFIED_TRIMMED_CONFIG_JSON"

   if   [[ $CHANNEL_GROUP == "none" && $MSPID == "none" ]]; then
        readonly GROUP_CONFIG_JSON=$( cat "$CONFIG_JSON" )

   elif [[ $CHANNEL_GROUP != "none" && $MSPID == "none" ]]; then
        readonly CHANNEL_GROUPS="$CHANNEL_GROUP"
        local GROUP_CONFIG_JSON
              GROUP_CONFIG_JSON="$( jq ".channel_group.groups.$CHANNEL_GROUP" "$ORIGINAL_TRIMMED_CONFIG_JSON" )"

        if [[ -z $GROUP_CONFIG_JSON || $GROUP_CONFIG_JSON == "null" ]]; then
           echo_red "ERROR: -g [$CHANNEL_GROUP] not found in config"
           exit 1
        fi
   elif [[ $CHANNEL_GROUP == "none" && $MSPID != "none" ]]; then
        local msp_config GROUP_CONFIG_JSON CHANNEL_GROUPS=""
        for g in Application Orderer Consortiums; do
            if [[ $g == "Consortiums" ]]; then
               msp_config="$( jq ".channel_group.groups.$g.groups" "$ORIGINAL_TRIMMED_CONFIG_JSON" )"
               if [[ ! -z $msp_config && $msp_config != "null" ]]; then
                  msp_config="$( jq ".channel_group.groups.$g.groups[].groups.$MSPID" "$ORIGINAL_TRIMMED_CONFIG_JSON" )"
               fi
            else
               msp_config="$( jq ".channel_group.groups.$g.groups.$MSPID" "$ORIGINAL_TRIMMED_CONFIG_JSON" )"
            fi
            if [[ ! -z $msp_config && $msp_config != "null" ]]; then
               echo "MSPID -m [$MSPID] exists in GROUP [$g]"
               CHANNEL_GROUPS="$CHANNEL_GROUPS $g"
               GROUP_CONFIG_JSON="$msp_config"
            fi
        done
        if [[ -z $CHANNEL_GROUPS ]]; then
           echo_red "ERROR: -m [$MSPID] does not exist in channel"
           exit 1
        fi
   else # $CHANNEL_GROUP != "none" && $MSPID != "none"
        readonly CHANNEL_GROUPS="$CHANNEL_GROUP"
        local GROUP_CONFIG_JSON
              GROUP_CONFIG_JSON="$( jq ".channel_group.groups.$CHANNEL_GROUP.groups.$MSPID" "$ORIGINAL_TRIMMED_CONFIG_JSON" )"

        if [[ ( $TASK != "add" || $KEY != "org" ) && ( -z $GROUP_CONFIG_JSON || $GROUP_CONFIG_JSON == "null" ) ]]; then
           echo_red "ERROR: -m [$MSPID] does not exist in -g [$CHANNEL_GROUP]"
           exit 1
        fi
        if [[ $TASK == "add" && $KEY == "org" && ! -z $GROUP_CONFIG_JSON && $GROUP_CONFIG_JSON != "null" ]]; then
           echo_red "ERROR: -m [$MSPID] already exists in -g [$CHANNEL_GROUP]"
           exit 1
        fi
   fi
   echo "CHANNEL_GROUPS [${CHANNEL_GROUPS:=""}]"

   if [[ -f $OUTPUT ]]; then
      echo_red "ERROR: -u [$OUTPUT] file must not exist"
      exit 1
   fi

   case "$TASK" in
   read | decode )
      if [[ $EXECUTE == "true" ]]; then
         echo_red "ERROR: task [$TASK] does not support -x (execute update channel)"
         exit 1
      fi
      read_or_decode "$KEY"
      echo_success
      exit 0
   esac

   case "$TASK" in
   set_anchor )
        if [[ $MSPID == "none" ]]; then
           echo_red "ERROR: task [$TASK] requires -m <MSPID>"
           exit 1
        fi
        case "$PEER_NAME" in
        peer0* ) ;; # OK
        * ) echo_red "ERROR: -n [$PEER_NAME] peer name must be a peer0 name"
            exit 1
        esac
        if [[ ! $PEER_PORT == *[[:digit:]]* ]]; then
           echo_red "ERROR: -p [$PEER_PORT] peer port must be an integer"
           exit 1
        fi
        set_anchor "$PEER_NAME" "$PEER_PORT"
        ;;
   set_value )
        if [[ $KEY == "none" || $VALUE == "none" ]]; then
           echo_red "ERROR: task [$TASK] requires -k and -v"
           exit 1
        fi
        if [[ $KV_FILE != "none" ]]; then
           echo_red "ERROR: task [$TASK] does not require -f <key value filename>"
           exit 1
        fi
        set_value "$KEY" "$VALUE"
        ;;
   set_values )
        if [[ $KEY != "none" && $VALUE != "none" ]]; then
           echo_red "ERROR: task [$TASK] does not require -k <key> and -v <value>"
           exit 1
        fi
        if [[ $KV_FILE == "none" ]]; then
           echo_red "ERROR: $TASK requires -f <key value filename>"
           exit 1
        fi
        if [[ ! -r $KV_FILE && ! -s $KV_FILE ]]; then
           echo_red "ERROR: -f <key value filename> not found or empty"
           exit 1
        fi
        set_values
        ;;
   replace_* )
        if [[ $VALUE == "none" || $VALUE2 == "none" ]]; then
           echo_red "ERROR: task [$TASK] requires -v <base64 x509 pem> and -V <base64 x509 pem>"
           exit 1
        fi
        replace_b64_x590 "$VALUE" "$VALUE2"
        ;;
   add )
        case "$KEY" in
        org ) if [[ $MSPID == "none" ]]; then
                 echo_red "ERROR: task [$TASK] -k [$KEY] requires -m <MSPID>"
                 exit 1
              fi
              check_org_value "$VALUE"
              ;;
        consenter )
              if [[ $MSPID != "none" ]]; then
                 echo_red "ERROR: task [$TASK] -k [$KEY] does not requires -m [$MSPID]"
                 exit 1
              fi
              check_consenter_json "$VALUE"
              add_consenter_item "$VALUE"
              add_orderer_address "$VALUE"
              ;;
        * )
           if [[ $MSPID == "none" ]]; then
              echo_red "ERROR: task [$TASK] -k [$KEY] requires -m <MSPID>"
              exit 1
           fi
           if   [[ $KEY == revocation_list ]]; then
                check_single_b64_crl " -v" "$VALUE"

           elif ( key_is_crypto_material_set "$KEY" ); then
                check_single_b64_x509_crt " -v" "$VALUE"
           else
                echo_red "ERROR: task [$TASK] does not support -k [$KEY]"
                echo "valid keys: [$KEY_CRYPTO_MATERIAL_SET]"
                exit 1
           fi
           if [[ $KEY == common_ica_certs ]]; then
              add_msp_key_item intermediate_certs     "$VALUE"
              add_msp_key_item tls_intermediate_certs "$VALUE"
           else
              add_msp_key_item "$KEY" "$VALUE"
           fi
        esac
   esac

   if [[ -z $GROUP_CONFIG_JSON || $GROUP_CONFIG_JSON == "null" ]]; then
      echo_red "ERROR: GROUP_CONFIG_JSON [$GROUP_CONFIG_JSON] is null or empty"
      exit 1
   fi

   if [[ $MSPID == "none" ]]; then
          echo "Applying change on [$CHANNEL_NAME] group [$CHANNEL_GROUP] ..."
          modify_trimmed_config_json ".channel_group.groups.$CHANNEL_GROUP = $GROUP_CONFIG_JSON"
   else
      for g in $CHANNEL_GROUPS; do
          echo "Applying change on [$CHANNEL_NAME] group [$g] org [$MSPID]..."
          case $g in
          Application | Orderer ) modify_trimmed_config_json ".channel_group.groups.$g.groups.$MSPID = $GROUP_CONFIG_JSON" ;;
          Consortiums )           modify_trimmed_config_json ".channel_group.groups.$g.groups[].groups.$MSPID = $GROUP_CONFIG_JSON" ;;
          esac
      done
   fi
   check_file_size "$MODIFIED_TRIMMED_CONFIG_JSON"
   update_channel  "$ORIGINAL_TRIMMED_CONFIG_JSON" "$MODIFIED_TRIMMED_CONFIG_JSON"
}

dependencies

main "$@"

set +x

echo_success
