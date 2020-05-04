#!/bin/bash

set -Eeuo pipefail

BASE="$(dirname $0)"
. "$BASE/lib.sh"

function usage() {
  echo "Usage: $0 options"
  echo "   --mspid <mspid>"
  echo "   --root_cert <filepath>"
  echo "   --intermediate_cert <filepath> (optional)"
  echo "   --tls_root_cert <filepath> (optional, default root_cert)"
  echo "   --tls_intermediate_cert <filepath> (optional)"
  echo "   --output <filename>"
}

function replace_org_config_json() {
    ORG_CONFIG_JSON=$(echo "$ORG_CONFIG_JSON" | jq "$1")
}

function main() {

    if [[ $# == 0 ]]; then
       echo_red "ERROR: $# unexpected number of params"
       usage
       exit 1
    fi

    while [[ $# -gt 0 ]]; do
    case "$1" in
        --mspid )
            readonly MSPID="$2"
            ;;
        --root_cert | --root_certs )
            readonly ROOT_CERT="$2"
            ;;
        --intermediate_cert | --intermediate_certs )
            INTERMEDIATE_CERT="$2"
            ;;
        --tls_root_cert | --tls_root_certs )
            TLS_ROOT_CERT="$2"
            ;;
        --tls_intermediate_cert | --tls_intermediate_certs )
            TLS_INTERMEDIATE_CERT="$2"
            ;;
        --output )
            OUTPUT="$2"
            ;;
        *)  echo_red "ERROR: [$1] unexpected arg"
            break
            ;;
    esac
    shift 2
    done

    if [[ ! -v MSPID || -z $MSPID ]]; then
       echo_red "ERROR: arg --mspid is mandatory"
       usage
       exit 1
    fi
    if [[ ! -v ROOT_CERT || -z $ROOT_CERT ]]; then
       echo_red "ERROR: arg --root_cert is mandatory"
       usage
       exit 1
    fi

    echo "mspid [$MSPID]"
    echo "root_cert [$ROOT_CERT]"
    echo "intermediate_cert [${INTERMEDIATE_CERT:=""}]"
    echo "tls_root_cert [${TLS_ROOT_CERT:=$ROOT_CERT}]"
    echo "tls_intermediate_cert [${TLS_INTERMEDIATE_CERT:=""}]"

    readonly INTERMEDIATE_CERT TLS_ROOT_CERT TLS_INTERMEDIATE_CERT

    readonly ORG_CONFIG_JSON_FILE="$BASE/org-without-peer.config.template.json"
    check_file "$ORG_CONFIG_JSON_FILE"
    local ORG_CONFIG_JSON
          ORG_CONFIG_JSON=$(jq . "$ORG_CONFIG_JSON_FILE")

    if [[ -v OUTPUT ]]; then
        OUTPUT=$(realpath "$OUTPUT")
        echo "output [$OUTPUT]"
        if [[ -e $OUTPUT ]]; then
            echo_red "ERROR: output file [$OUTPUT] already exists"
            exit 1
        fi
    else
        OUTPUT="none"
    fi
    readonly OUTPUT

    local policy
    for policy in Admins Writers; do
        replace_org_config_json ".policies.$policy.policy.value.identities[0].principal.msp_identifier=\"$MSPID\""
    done

    replace_org_config_json ".values.MSP.value.config.name=\"$MSPID\""

    local key value onelineb64
    for key in ROOT_CERT INTERMEDIATE_CERT TLS_ROOT_CERT TLS_INTERMEDIATE_CERT; do
        value="${!key}"

        [[ -z $value ]] && continue

        if ( ! is_x509_crt "$value" ); then
            echo_red "ERROR: arg --$key [$value] must be an x509 cert"
            usage
            exit 1
        fi

        onelineb64=$(base64 -w 0 "$value")
        replace_org_config_json ".values.MSP.value.config.${key,,}s=[\"$onelineb64\"]"
    done

    if [[ -z $INTERMEDIATE_CERT ]]; then
        value="$ROOT_CERT"
    else
        value="$INTERMEDIATE_CERT"
    fi
    onelineb64=$(base64 -w 0 "$value")
    replace_org_config_json ".values.MSP.value.config.organizational_unit_identifiers[0].certificate=[\"$onelineb64\"]"

    echo "$ORG_CONFIG_JSON" | jq .

    readonly MUST_BE_REPLACED=$(echo "$ORG_CONFIG_JSON" | grep MUST_BE_REPLACED)

    if [[ ! -z $MUST_BE_REPLACED ]]; then
       echo_red "ERROR: not all \"MUST_BE_REPLACED\" token was replaced !!!"
       exit 1
    fi

    [[ $OUTPUT == none ]] && return 0

    echo "$ORG_CONFIG_JSON" > "$OUTPUT"
    if [[ ! -s $OUTPUT ]]; then
        echo_red "ERROR: empty output file [$OUTPUT]"
        exit 1
    fi
}

echo_running

main "$@"

echo_success
