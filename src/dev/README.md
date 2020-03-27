# network-setup ambiente dev

Este proyecto permite deployar una red Fabric integrada por 3 organizaciones, corriendo 6 nodos peers y un nodo orderer, en un único equipo.

## Convenciones

`$PROJECT_HOME`: Directorio en el cual se copio este proyecto.

## Archivos de configuración

El deploy se configura mediante los archivos:

- `.env`
- tribfed\_crypto-config.yaml
- tribfed\_configtx.yaml
- docker-compose.yaml

## Prerequisitos

En `.env:HLF_VERSION` se setea la versión de HLF que se utilizará para el deploy. Ej: `1.4.0`

El equipo donde se hace el deploy requiere:

- docker 18.09 o superior
- docker-compose 1.23.1 o superior
- binarios de HLF cryptogen y configtxgen localizados en `$PROJECT_HOME/bin/hlf-{.env:HLF_VERSION}/`
- set `PATH` conteniendo `$PROJECT_HOME/bin/hlf-{.env:HLF_VERSION}/`
- GOLANG 1.10.x o superior
- set `GOPATH` conteniendo `~/go`
- chaincode en `$CHAINCODE_DIR/main.go`

Los binarios binarios de HLF `cryptogen` y `configtxgen` se pueden obtener con el siguiente comando:

``` {.sh}
curl -sSL http://bit.ly/2ysbOFE | bash -s -- $HLF_VERSION -d -s
```

**`HINT: El src del chaincode se puede obtener desde https://gitlab.cloudint.afip.gob.ar/blockchain-team/padfed-chaincode.git`**

## Scripts disponibles

| script                        | uso                                                                                                                                                       |
|-------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `tribfed_start_fresh.sh`      | Reinicia la red desde cero generando nuevamente los artefactos criptograficos y reseteando el ledger.                                                     |
| `tribfed_start.sh`            | Inicia la red sin resetear el ledger. Se puede utilizar ante un cambio en la configuración de docker o para reiniciar la red luego de un reinicio del SO. |
| `tribfed_stopFabric.sh`       | Detiene la ejecución de todos los containers referenciados en el `docker-compose.yml`                                                                     |
| `tribfed_setup.sh`            | Genera los artefactos criptograficos, el bloque genesis, la tx para la creacion del channel y las txs para declarar los anchors peers de cada org         |
| `tribfed_chaincode_update.sh` | Despliega el chaincode que debe estar disponible en `$CHAINCODE_DIR`                                                                                      |

## Seteos de configuración mediante el .env

| variable                   | uso                                                                                          | ejemplo                                                             |
|----------------------------|----------------------------------------------------------------------------------------------|---------------------------------------------------------------------|
| `FABRIC_NETWORK_NAME`      | Nombre de la red.                                                                            | `fabric_tribfed`                                                    |
| `FABRIC_INSTANCE_PATH`     | Path donde se crean los materiales criptograficos y los ledger de cada nodo.                 | `./fabric-instance`                                                 |
| `NETWORK_DOMAIN`           | Dominio de la red común a todas las orgs y peers.                                            | `tribfed.gob.ar`                                                    |
| `TLS_ENABLED`              | Habilitacion de TLS.                                                                         | `true` o `false`                                                    |
| `TLS_CLIENT_AUTH_REQUIRED` | Habilitacion de verificacion de cliente para TLS.                                            | `true` o `false`                                                    |
| `LOG_LEVEL`                | Nivel de log de Fabric.                                                                      | `info`, `debug`, ...                                                |
| `CHANNEL`                  | Nombre del channel. Debe conincidir con el de un perfil definido en `tribfed_configtx.yaml`. | `padfedchannel`                                                     |
| `CHAINCODE`                | Nombre del chaincode.                                                                        | `padfedcc`                                                          |
| `CHAINCODE_DIR`            | Path absoluto al código fuente del chaincode                                                 | `/home/pedro/dev/padfed-chaincode`                                  |
| `CHAINCODE_PACKAGE`        | Paquete Go del chaincode (no debería modificarse)                                            | `gitlab.cloudint.afip.gob.ar/blockchain-team/padfed-chaincode.git`  |
| `ENDORSEMENT_POLICY`       | Politica de respaldo de txs.                                                                 | `"OutOf(2,'AFIP.peer','ARBA.peer','COMARB.peer')"`                  |
| `CHAINCODE_REPO_URL`       | Repo del chaincode (para uso futuro)                                                         | `https://nexus.cloudint.afip.gob.ar/nexus/repository/padfed-bc-raw` |
| `ORDERER`                  | Endpoint del orderer.                                                                        | `orderer.afip.tribfed.gob.ar:7050`                                  |
| `ORGS_WITH_PEERS`          | Lista de MSPID de las orgs que corren nodos.                                                 | `"AFIP COMARB ARBA"`                                                |
| `ORGS_WITH_CAS`            | Lista de MSPID de las orgs que tienen su propia CA.                                          | `"AFIP COMARB ARBA MORGS"`                                          |
| PEERS                      | Lista de peers de cada org que corre nodos.                                                  | `"peer0 peer1"`                                                     |

## Configuración de organizaciones y peers

- Por default el proyecto desploya una red con 3 orgs.
- La org `AFIP` coore 2 peers y un orderer y las orgs `ARBA` y `COMARB` corren 2 peers cada una: `peer0` y `peer1`.
- Se pueden deshablitar las orgs `ARBA` y/o `COMARB` modificando el `docker-compose.yaml` y las variables `ORGS_WITH_PEERS`, `ORGS_WITH_CAS` y `ENDORSEMENT_POLICY` en el `.env`.
- Tambien se puede deshablitar el deploy del segundo peer (el peer1) de cada org modificando el `docker-compose.yaml` y la variable `PEERS` en el `.env`.
