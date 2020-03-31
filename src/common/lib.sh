#!/bin/bash

readonly BOLD=$(tput bold)
readonly GREEN=$(tput setaf 2)
readonly RED=$(tput setaf 1)
readonly NORMAL=$(tput sgr0)
readonly BLUE="\033[1;34m"

function echo_red()   { echo -e "$RED$*$NORMAL"; }
function echo_green() { echo -e "$GREEN$*$NORMAL"; }
function echo_blue()  { echo -e "$BLUE$*$NORMAL"; }

function docker() {
   [[ -v DOCKERDEBUG ]] && echo "[DOCKERDEBUG] docker $*"

   command docker "$@"
}

function echo_sep() {
   [[ -v DEBUG ]] && return 0

   for i in {1..80}; do echo -n "-"; done
   echo
   [[ $# -eq 1 ]] && echo "$1"
}

function echo_bold_sep() {
   [[ -v DEBUG ]] && return 0

   for i in {1..80}; do echo -n "#"; done
   echo
}

function check_param_file() {
[[ -f $2 ]] || { echo_red "ERROR: p$1: File [$2] not found !!!"; exit 1; }
}

function check_file() {
[[ -f $1 ]] || { echo_red "ERROR: File [$1] not found !!!"; exit 1; }
}

function check_file_size() {
[[ -r $1 && -s $1 ]] || { echo_red "ERROR: File [$1] not readeable or empty !!!"; exit 1; }
}

function check_dir() {
[[ -d $1 ]] || { echo_red "ERROR: Dir [$1] not found !!!"; exit 1; }
}

function check_no_empty_dir() {
check_dir "$1"
local FILES
FILES=$(ls -A "$1")
[[ $FILES ]] || { echo_red "ERROR: Dir [$1] is empty !!!"; exit 1; }
}

function check_exe() {
local command
command="$(command -v "$1")"
if [[ -x $command ]]; then
  echo "checked command [$command]"
  return 0 # OK
fi
echo_red "ERROR: command [$1] not found !!!"
exit 1 # Fail
}

function check_number_of_params() {
if [[ $1 -ne "$2" ]]; then
   echo_red "ERROR: $1 unexpected number of params"
   usage
fi
}

function check_env() {
[[ -v "$1" ]] || { echo_red "ERROR: .env [$1] not found !!!"; exit 1; }
}

function backup_dir() {
local SOURCE_DIR="$1"

local TAG_NAME="-" && [[ "$#" -eq 2 ]] && TAG_NAME="-$2-"

if [[ -d "$SOURCE_DIR" ]]; then

    mkdir -p "${SOURCE_DIR}-backup"

    local FILE
    FILE=backup-$(basename "$SOURCE_DIR")$TAG_NAME$(date +%Y%m%d%H%M%S).tar.xz
    tar --create --gzip --file="${SOURCE_DIR}-backup/$FILE" "$SOURCE_DIR"
fi
}

function replaceKeys() {
    local FILE="$1"
    shift
    while [[ $# -gt 0 ]]; do
        local NAME="$1"
        sed -i "s/{{$NAME}}/${!NAME}/g" "$FILE"
        shift
    done
}

# Ask user for confirmation to proceed
function askProceed() {
  read -p "Continue? [Y/n] " ans
  case "$ans" in
  y | Y )
    echo "proceeding ..."
    ;;
  n | N )
    echo "exiting..."
    exit 1
    ;;
  *)
    echo "invalid response"
    askProceed
    ;;
  esac
}

function echo_running() {
    readonly THIS=$(basename "$0")
    echo_bold_sep
    echo_blue "[$THIS] running ..."
}

function echo_success() {
    echo_green "[${THIS:-}] ${1:-"exit OK !!!"}"
    echo_bold_sep
}

function is_x509_crt() {
    [[ -r $1 ]] && openssl x509 -in "$1" -text &> /dev/null
}

check_x509_crt() {
is_x509_crt "$1" || { echo_red "ERROR: File [$1] is not a x509 certificate !!!"; exit 1; }
}

function is_crl() {
    [[ -r $1 ]] && openssl crl -in "$1" -text &> /dev/null
}

check_crl() {
is_crl "$1" || { echo_red "ERROR: File [$1] is not a crl certificate !!!"; exit 1; }
}

function jq_check_value() {
   echo "Checking json path ..."
   local JSON_FILE="$1"
   local JSON_PATH="$2"
   local WANT="$3"

   local VALUE
   VALUE=$( jq "$JSON_PATH" "$JSON_FILE" )

   echo "WANT [$WANT] VALUE [$VALUE]"

   [[ $WANT == "$VALUE" ]]
}

function get_tls_parameters() {
  local TLS_PARAMETERS=""
  if [[ $TLS_ENABLED == true ]]; then
    TLS_PARAMETERS="--tls --cafile /etc/hyperledger/orderer/tls/tlsca.afip.tribfed.gob.ar-cert.pem"

    if [[ $TLS_CLIENT_AUTH_REQUIRED == true ]]; then
       TLS_PARAMETERS="$TLS_PARAMETERS --clientauth"
       TLS_PARAMETERS="$TLS_PARAMETERS --keyfile /etc/hyperledger/admin/tls/client.key"
       TLS_PARAMETERS="$TLS_PARAMETERS --certfile /etc/hyperledger/admin/tls/client.crt"
    fi
  fi
  echo "$TLS_PARAMETERS"
}
