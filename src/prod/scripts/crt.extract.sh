#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

readonly BASE=$(dirname "$(readlink -f "$0")")

. "$BASE/lib.sh"

function process_chain {
   local INPUT_FILE_NAME="$1"

   local ISSUER_CN=$( get_CN_from_crypto_material x509 issuer  "$INPUT_FILE_NAME")
   local SUBJECT_CN=$(get_CN_from_crypto_material x509 subject "$INPUT_FILE_NAME")
   echo "ISSUER_CN [$ISSUER_CN]"
   echo "SUBJECT_CN [$SUBJECT_CN]"

   local OUTPUT_FILE_NAME_TMP="$1.first.crt.tmp"
   rm -f "$OUTPUT_FILE_NAME_TMP"
   openssl x509 -in "$INPUT_FILE_NAME" > "$OUTPUT_FILE_NAME_TMP"

   local ISSUER_CN_2=$( get_CN_from_crypto_material x509 issuer  "$OUTPUT_FILE_NAME_TMP")
   local SUBJECT_CN_2=$(get_CN_from_crypto_material x509 subject "$OUTPUT_FILE_NAME_TMP")
   echo "ISSUER_CN_2 [$ISSUER_CN_2]"
   echo "SUBJECT_CN_2 [$SUBJECT_CN_2]"

   if [[ $ISSUER_CN != "$ISSUER_CN_2" || $SUBJECT_CN != "$SUBJECT_CN_2" ]]; then
      echo_red "ERROR: issuer or subject error"
      exit 1
   fi

   case "$ISSUER_CN_2" in
   BLOCKCHAIN-MSP-CA-* ) local SERVICE=msp ;;
   BLOCKCHAIN-TLS-CA-* ) local SERVICE=tls ;;
   BLOCKCHAIN-OS-CA-* )  local SERVICE=ope ;;
   * ) echo_red "ERROR: issuer [$ISSUER_CN_2] unknow"
       exit 1
   esac
   
   local OUTPUT_FILE_NAME="none"
   if [[ $SERVICE == "tls" ]]; then
      case $SUBJECT_CN_2 in
      *.$DOMAIN ) OUTPUT_FILE_NAME="$2/$SUBJECT_CN_2-tls-server.crt" ;;
      esac
   fi
   if [[ $OUTPUT_FILE_NAME == "none" ]]; then
      local SEP="@"
      case $SUBJECT_CN_2 in
         orderer* | peer* ) SEP="." ;;
      esac
      local CLIENT_OR_SERVER="client"
      if [[ $SERVICE == "msp" ]]; then
         case $SUBJECT_CN_2 in
            orderer* | peer* ) CLIENT_OR_SERVER="server" ;;
         esac
      fi
      local CN_WITHOUT_SUFFIX=${SUBJECT_CN_2/$CRT_DN_CN_SUFFIX/""}
      OUTPUT_FILE_NAME="$2/${CN_WITHOUT_SUFFIX}${SEP}${DOMAIN}-${SERVICE}-${CLIENT_OR_SERVER}.crt"     
   fi 
     
   if [[ -s $OUTPUT_FILE_NAME ]]; then
      echo_red "ERROR: file [$OUTPUT_FILE_NAME] already exists"
      exit 1
   fi
   
   mv -f "$OUTPUT_FILE_NAME_TMP" "$OUTPUT_FILE_NAME"
   
   cat "$OUTPUT_FILE_NAME"
   
   echo "crt [$OUTPUT_FILE_NAME] extracted !!!"

   ((CRT_COUNTER=CRT_COUNTER+1))
}

function process_tar() {
   echo "Processing tar [$1] ..."

   local TMP_TARGET_DIR="$PWD/tmp"
   rm -rf "$TMP_TARGET_DIR"
   mkdir -p "$TMP_TARGET_DIR"
   set -x
   tar -vxf "$1" -C "$TMP_TARGET_DIR"
   set +x
   process_dir "$TMP_TARGET_DIR" "$2"
   rm -rf "$TMP_TARGET_DIR"
}

function process_file() {
   echo "Processing file [$1] ..."
   case ${1,,} in
   *.pem | *.crt | *.cert ) process_chain "$1" "$2" ;;
   *.tar ) process_tar "$1" "$2" ;;
   * ) echo_red "ERROR: p1 [$1] file extension must be pem | crt | cert | tar"
       exit 1
       ;;
   esac
}

function process_dir() {
   echo "Processing dir [$1] ..."
   local file_found="false"
   for f in $( find $1 -maxdepth 1 -type f ); do
       case ${f,,} in
       *.pem | *.crt | *.cert ) 
             process_chain "$f" "$2"
             file_found="true"
             ;;
       *.tar ) 
             process_tar "$f" "$2"
             file_found="true"
             ;;
       esac
   done
   if [[ $file_found == "false" ]]; then
      echo_red "ERROR: p1 [$1] directory does not have files with extension pem | crt | cert | tar"
      exit 1
   fi
}

function main() {

   echo_running

   # Check args
   if [[ $# != 1 ]]; then
      echo_red "ERROR: p1 must be a file or a directory"
      exit 1
   fi
   local INPUT_FILE_NAME="$1"
   if [[ ! -s $INPUT_FILE_NAME && ! -d $INPUT_FILE_NAME ]]; then
      echo_red "ERROR: p1 [$INPUT_FILE_NAME] must be a file or a directory"
      exit 1
   fi

   check_file "setup.conf" && source "setup.conf"

   # Check env variables
   check_env MSPID 
   check_env DOMAIN 
   check_env CRYPTO_STAGE_PATH 
   check_env CRT_DN_CN_SUFFIX 

   for d in $(find . -type d -name '*-crypto-requests'); do
       case $(basename "$d") in 
          $MSPID-*-crypto-requests )
             TARGET_DIR="$d-crts"
             warn_backup_rm "$TARGET_DIR"
             mkdir -p "$TARGET_DIR"
             break
       esac
   done
   if [ ! -v TARGET_DIR ]; then
      echo_red "ERROR: directory [*-crypto-requests] not found"
      exit 1
   fi

   CRT_COUNTER=0

   if [[ -d $INPUT_FILE_NAME ]]; then
      process_dir  "$INPUT_FILE_NAME" "$TARGET_DIR"
   else
      process_file "$INPUT_FILE_NAME" "$TARGET_DIR"
   fi

   echo_success "[$CRT_COUNTER] crts extracted -"   
}

##################################################

main "$@"
