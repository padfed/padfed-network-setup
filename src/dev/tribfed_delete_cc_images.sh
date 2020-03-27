#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

# buscar imágenes cuyos nombres contengan padfedcc devolviendo sus id
docker images -f "reference=dev-*" --format '{{.ID}}' \
    | xargs -r docker rmi -f # borrar imágenes por id (sólo si hay algún id)
