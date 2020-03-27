
BOLD=$(tput bold)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NORMAL=$(tput sgr0)

docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

run() {
    [[ -v RUNDEBUG  ]] && echo "$@"
    command "$@"
}

die() {
    echo "$@"
    exit 1
}

fail() {
    echo "$RED$BOLD!!!! $*$NORMAL" >/dev/stderr
    FAILURES=$((${FAILURES:-0}+1))
}

failreport() {
    if [[ ${FAILURES:-0} -gt 0 ]]
    then
        echo "$RED$BOLD!!!! $FAILURES TESTS FAILED$NORMAL" > /dev/stderr
        return 1
    fi
}

assert() {
    jq -e "$@" > /dev/null || fail "ASSERTION FAILED: $@"
}

cc() {
    local OPTS=$(getopt -o 'ofa' -l 'must-fail,can-fail,out' -- "$@")
    eval set -- "$OPTS"
    while true; do
        case "$1" in
            -o|--out) local PRINTOUTPUT=1 ; shift ;;
            -f|--must-fail) local EXPECTFAILURE=1 ; shift ;;
            -a|--can-fail) local ACCEPTFAILURE=1 ; shift ;;
            --) shift ; break ;;
            *) echo "${RED}error: opción inválida: $BOLD$o$NORMAL" ; exit 1 ;;
        esac
    done

    local SUBCOMMAND="$1"
    shift

    local PRINTFUNCTION="$1"
    local ARGS='{"Args":[]}'
    ARGS=$(jq <<<$ARGS -c ".function=\"$1\"")
    shift

    local PRINTARGS=""
    for ARG in "$@"
    do
        ARG=$(jq -c '.' <<<$ARG 2>/dev/null || echo "$ARG")
        ARGS=$(jq -c '.Args+=[$a]' --arg a "$ARG" <<<$ARGS)
        PRINTARGS="${PRINTARGS:+$PRINTARGS }$ARG"
    done

    if [[ ! -v VERBOSE && ${#PRINTARGS} -gt 40 ]]; then
        PRINTARGS=${PRINTARGS:0:40}...
    fi
    echo "$GREEN===> $BOLD$SUBCOMMAND$NORMAL $PRINTFUNCTION $PRINTARGS" > /dev/stderr

    local PEER_CLI_TLS_WITH_ORG=""
    if [[ "$TLS_ENABLED" == "true" ]]; then
        PEER_CLI_TLS_WITH_ORDERER="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem"
        ORGS=AFIP
        [[ $SUBCOMMAND == invoke ]] && ORGS=$ORGS_WITH_PEERS
        for ORG in $ORGS; do
            PEER_CLI_TLS_WITH_ORG="$PEER_CLI_TLS_WITH_ORG --peerAddresses peer0.${ORG,,}.tribfed.gob.ar:7051 --tlsRootCertFiles /etc/hyperledger/tls_root_cas/tlsca.${ORG,,}.tribfed.gob.ar-cert.pem"
        done
        if [[ "$TLS_CLIENT_AUTH_REQUIRED" == "true" ]]; then
            PEER_CLI_TLS_WITH_ORDERER="$PEER_CLI_TLS_WITH_ORDERER --clientauth --keyfile /etc/hyperledger/tls/client.key --certfile /etc/hyperledger/tls/client.crt"
        fi
    fi

    case $SUBCOMMAND in
        invoke)
            WAIT_FOR_EVENT="--waitForEvent"
            ;;
        query)
            WAIT_FOR_EVENT=""
            ;;
        *)
            echo "unknown command" > /dev/stderr
            exit 1
    esac

    ENV="-e FABRIC_LOGGING_SPEC=error"

    set +e
    OUTPUT="$(docker exec $ENV peer0_afip_cli peer chaincode \
                $SUBCOMMAND \
                $PEER_CLI_TLS_WITH_ORDERER \
                $PEER_CLI_TLS_WITH_ORG \
                $WAIT_FOR_EVENT \
                -o $ORDERER \
                -C $CHANNEL_NAME \
                -n $CHAINCODE_NAME \
                -c "$ARGS" 2>&1)"
    STATUS=$?
    set -e

    if [[ $STATUS -eq 0 ]]; then
        # éxito
        if [[ ! -v EXPECTFAILURE ]]; then
            echo "     ${GREEN}EXPECTED SUCCESS$NORMAL" >/dev/stderr
        else
            fail "UNEXPECTED SUCCESS"
            echo "     OPERATION: $SUBCOMMAND $ARGS" >/dev/stderr
            echo "     PEER CLIENT OUTPUT: $OUTPUT" >/dev/stderr
        fi
    else
        # fallo
        if [[ -v ACCEPTFAILURE ]]; then
            echo "     ${GREEN}ACCEPTED FAILURE$NORMAL" >/dev/stderr
        else
            if [[ -v EXPECTFAILURE ]]; then
                echo "     ${GREEN}EXPECTED FAILURE$NORMAL" >/dev/stderr
            else
                fail "UNEXPECTED FAILURE"
                echo "     OPERATION: $SUBCOMMAND $ARGS" >/dev/stderr
                echo "     PEER CLIENT OUTPUT: $OUTPUT" >/dev/stderr
            fi
        fi
    fi

    # si se pasa -o se imprime por stdout para hacer validaciones sobre la salida
    if [[ -v PRINTOUTPUT ]]; then
        echo "$OUTPUT"
    fi

    # si está verbose se imprime por stderr (sólo para visualización)
    if [[ -v VERBOSE && -n "$OUTPUT" ]]; then
        echo "$GREEN<···$NORMAL $OUTPUT" > /dev/stderr
    fi

}

invoke() {
   cc invoke "$@"
}

query() {
   cc query "$@"
}
