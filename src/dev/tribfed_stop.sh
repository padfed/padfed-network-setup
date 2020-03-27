#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

# cd al directorio donde está ubicado este script
cd "$(dirname $(readlink -f "$0"))"

# stop the containers that might be running
docker-compose down --remove-orphans
