#!/bin/bash
[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail
ME=$(basename $0)
BASE=$(dirname $(readlink -f $0))

SYSTEM="padfed"
APPLICATION="padfed-network-setup"
REPOSITORY="padfed-bc-raw"

BASEURL="https://nexus.cloudint.afip.gob.ar/nexus/repository/$REPOSITORY/$SYSTEM/$APPLICATION"

CREDENTIALS="$HOME/.netrc"
TARGET="$BASE/target"

function usage {
    echo "Uso: $(basename $0) <version>"
}

function upload {
    local VERSION=$1
    local ARCHIVE=$2
    local URL="$BASEURL/$VERSION/$(basename $ARCHIVE)"
    if [[ ! -r "$CREDENTIALS" ]]
    then
        echo "No se puede acceder a credenciales de autenticación a Nexus. Se debe utilizar el archivo $CREDENTIALS. Ver man 5 netrc para conocer más de su contenido."
        return 1
    fi
    echo "Publicando $(realpath --relative-base $PWD $ARCHIVE) en $URL..."
    curl \
        --progress-bar \
        --fail \
        --noproxy "*" \
        --cacert ca.crt \
        --netrc-file "$CREDENTIALS" \
        --upload-file "$ARCHIVE" \
        "$URL"
}

function mksum {
    local ALGO=$1
    local FILE=$2
    local T=($(${ALGO}sum $FILE))
    echo -n ${T[0]} > $FILE.$ALGO
}

function semver {
  local VERSION=$1
  local REGEX="^[vV]?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"
  if [[ "$VERSION" =~ $REGEX ]]; then
    # if a second argument is passed, store the result in var named by $2
    if [ "$#" -eq "2" ]; then
      local MAJOR=${BASH_REMATCH[1]}
      local MINOR=${BASH_REMATCH[2]}
      local PATCH=${BASH_REMATCH[3]}
      local PRERELEASE=${BASH_REMATCH[4]}
      local BUILD=${BASH_REMATCH[6]}
      eval "$2=(\"$MAJOR\" \"$MINOR\" \"$PATCH\" \"$PRERELEASE\" \"$BUILD\")"
    else
      echo "$VERSION"
    fi
  else
    return 1
  fi
}

function dependencies {
    echo "Verificando dependencias en el entorno:"
    command -V curl
    command -V git
    command -V tar
    command -V xz
    command -V md5sum
    command -V sha1sum
    command -V basename
    command -V realpath
}

function main {

    dependencies

    if [[ $# -ne 1 ]]
    then
        echo "No se específicó la versión a publicar."
        usage
        exit 1
    fi

    local VERSION=$1
    local ARCHIVE=$TARGET/$APPLICATION-$VERSION.tar.xz
    local ARCHIVE_PROD=$TARGET/$APPLICATION-PROD-$VERSION.tar.xz
    local TAG=v$VERSION

    echo "Verificando sintaxis de versión suministrada..."
    if ! semver "$VERSION" > /dev/null
    then
        echo "La versión suministrada '$VERSION' no es una SemVer2 válida."
        exit 1
    fi

    echo "Verificando que el directorio de trabajo no tenga modificaciones no commiteadas ni archivos sin seguimiento..."
    if [[ $(git status -s | wc -l) -ne 0 ]]
    then
        echo "El directorio de trabajo no está limpio."
        echo "Los siguientes archivos deben ser removidos o commiteados antes de reintentar la operación:"
        git status -s
        exit 1
    fi

    # si no exsite directorio target se crea
    [[ -d $TARGET ]] || mkdir $TARGET

    # si existe archivo destino se elimina
    [[ -f $ARCHIVE ]] && rm $ARCHIVE

    # si existe archivo prod destino se elimina
    [[ -f $ARCHIVE_PROD ]] && rm $ARCHIVE_PROD

    echo "Creando tag $TAG apuntando al commit $(git rev-parse HEAD)..."
    git tag $TAG -m "Release $VERSION"

    # Workaround al no funcionamento de --exclude-vcs-ignores
    #
    #       --exclude-vcs-ignores
    #          Exclude files that match patterns read from VCS-specific
    #          ignore files.  Supported files are: .cvsignore, .gitignore,
    #          .bzrignore, and .hgignore.
    #

    declare -a EXCLUDE_PATTERNS=(
             "configtxgen" "configtxlator" "cryptogen" "discover" "idemixgen" "orderer" "peer" \
             "**/fabric-storage" \
             "**/*backup" \
             "**/*instances" \
             "**/*instance" \
             "**/crypto-stage" \
             "**/*-crypto-requests*" \
             "**/*-crypto-admin" \
             "**/tmp" \
             "src/prod/test" 
             )

    local EXCLUDE_ARGUMENTS="--exclude-vcs --exclude-vcs-ignores"
    for p in ${EXCLUDE_PATTERNS[@]}; do
        EXCLUDE_ARGUMENTS="$EXCLUDE_ARGUMENTS --exclude=$p"
    done

    echo "Creando archivo $(realpath --relative-base $PWD $ARCHIVE)..."
    set -x
    tar -vcaf $ARCHIVE -C $BASE $EXCLUDE_ARGUMENTS \
        README.md \
        src 
    set +x
 
    echo "Creando archivo $(realpath --relative-base $PWD $ARCHIVE_PROD)..."
    set -x
    tar -vcaf $ARCHIVE_PROD -C $BASE $EXCLUDE_ARGUMENTS \
        README.md \
        src/bin \
        src/common \
        src/prod
    set +x

    echo "Creando sumas de comprobación de $(realpath --relative-base $PWD $ARCHIVE)..."
    mksum md5 $ARCHIVE
    mksum sha1 $ARCHIVE
    mksum md5 $ARCHIVE_PROD
    mksum sha1 $ARCHIVE_PROD

    # Ya estaríamos en condiciones de publicar en repositorio remoto git y en Nexus...

    # Y empezamos por el push al repositorio remoto git ya que es más "reversible"
    # en caso de problemas en la publicación a Nexus.

    echo "Publicando el tag $TAG en el repositorio remoto origin en $(git remote get-url origin)..."
    git push origin $TAG

    echo "Publicando archivos en el repositorio Nexus $REPOSITORY en $BASEURL..."
    upload $VERSION $ARCHIVE.sha1
    upload $VERSION $ARCHIVE.md5
    upload $VERSION $ARCHIVE

    echo "Publicando archivos productivos en el repositorio Nexus $REPOSITORY en $BASEURL..."
    upload $VERSION $ARCHIVE_PROD.sha1
    upload $VERSION $ARCHIVE_PROD.md5
    upload $VERSION $ARCHIVE_PROD
}

main "$@"
