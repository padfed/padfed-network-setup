# PADFED reset de la Testnet

## Introducción

El siguiente procedimiento permite iniciar nuevamente la cadena de bloques de la Blockchain sin volver a generar los certificados utilizados.

Elementos que se eliminaran:

    • Ledger con la cadena de bloques generada hasta el momento
    • Transacciones de configuración para el alta de canales y sus actualizaciones
    • Chaincodes desplegados
    • Key-Value store 

---

## Procedimiento de reinicio

1. Conectarse por SSH al ORDERER

      
    1.1 Posicionarse en el directorio en el cual se instalaron los scripts de arranque.
    
    1.2 Detener el nodo HLF con el siguiente comando
        ```
        $ docker-compose stop
        ```

    1.2 Visualizar el contenido del archivo .env
        Identificar el valor de la siguiente propiedad
        
        FABRIC_LEDGER_STORE_PATH
                    
    1.3 Proceder a eliminar el siguiente directorio ${FABRIC_LEDGER_STORAGE_PATH}/orderer0.orderer.blockchain-tributaria.testnet.afip.gob.ar donde
        ${FABRIC_LEDGER_STORE_PATH} debe ser reemplazado por el valor obtenido de dicha propiedad en el achivo .env
        
        
    
2. Conectarse por SSH al AFIP PEER0

      
    1.1 Posicionarse en el directorio en el cual se instalaron los scripts de arranque.
    
    1.2 Detener el nodo HLF con el siguiente comando
        ```
        $ docker-compose stop
        ```

    1.2 Visualizar el contenido del archivo .env
        Identificar el valor de la siguiente propiedad
        
        FABRIC_LEDGER_STORE_PATH
                    
    1.3 Proceder a eliminar el siguiente directorio ${FABRIC_LEDGER_STORAGE_PATH}/peer0.blockchain-tributaria.testnet.afip.gob.ar donde
        ${FABRIC_LEDGER_STORE_PATH} debe ser reemplazado por el valor obtenido de dicha propiedad en el achivo .env
        
        
3. Conectarse por SSH al AFIP PEER1

      
    1.1 Posicionarse en el directorio en el cual se instalaron los scripts de arranque.
    
    1.2 Detener el nodo HLF con el siguiente comando
        ```
        $ docker-compose stop
        ```

    1.2 Visualizar el contenido del archivo .env
        Identificar el valor de la siguiente propiedad
        
        FABRIC_LEDGER_STORE_PATH
                    
    1.3 Proceder a eliminar el siguiente directorio ${FABRIC_LEDGER_STORAGE_PATH}/peer1.blockchain-tributaria.testnet.afip.gob.ar donde
        ${FABRIC_LEDGER_STORE_PATH} debe ser reemplazado por el valor obtenido de dicha propiedad en el achivo .env
        

## Setup

Una vez eliminados los directorios indicados en el procedimiento anterior la red se encuentra en un estado de pre-setup, es decir se requieren invocar
los scripts de creacion y actualizacion del canal como así también instalar nuevamente el Chaincode (SmartContract) con la lógica de negocio a utilizar por los
clientes.

Para proceder con dicho proceso se debe utilizar la guía de instalación utilizada para generar la red originalmente siguiendo los siguientes pasos:
    
    2.2
    2.3
    2.4
 
 En este link se encuentra disponible la guia de instalación -->  

[Guia de instalación](https://gitlab.cloudint.afip.gob.ar/blockchain-team/padfed-network-setup/blob/master/src/qa/INSTALLATIONGUIDE.md) 
            
