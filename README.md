# padfed-network-setup

- **Roadmap** https://redmine-blockchain.afip.gob.ar/projects/padfed-network-setup/roadmap
- **Redmine** https://redmine-blockchain.afip.gob.ar/projects/padfed-network-setup
- **GitLab** https://gitlab.cloudint.afip.gob.ar/blockchain-team/padfed-network-setup
- **Nexus** https://nexus.cloudint.afip.gob.ar/nexus/service/rest/repository/browse/padfed-bc-maven/afip/padfed/network-setup
- **Hyperledger Fabric 1.4** https://hyperledger-fabric.readthedocs.io/en/release-1.4/whatis.html

## Objetivo

Mantener los shell scripts linux que permiten crear y actualizar una red de Blockchain Hyperledger Fabric para Padron Federal para los distintos ambientes (por ahora DEV y QA).

## Tipos de deploy

| Deploy | Descripcion | Doc 
| --- | --- | --- | 
| dev | Deploy corriendo todos los nodos en un solo equipo | [README](qa/dev/README.md) 
| qa | Deploy con nodos distribuidos en distintos equipos. Utilizado para la Testnet.  | [README disponible en Github](https://github.com/padfed/padfed-doc/tree/master/testnet-network-setup) 
| [localize.sh](src/qa/localize.sh) | Deploy pseudodistribuido de la topología de la Testnet corriendo en un solo equipo | [README](qa/dev/README.md) 

### Instructivo de reset (sin regenerar certificados)

[$INSTALL_HOME/src/qa/RESETGUIDE.MD](https://gitlab.cloudint.afip.gob.ar/blockchain-team/padfed-network-setup/blob/master/src/qa/RESETGUIDE.md)
