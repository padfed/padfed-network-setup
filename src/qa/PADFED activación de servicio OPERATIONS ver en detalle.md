# PADFED activación de servicio OPERATIONS [ver en detalle](https://hyperledger-fabric.readthedocs.io/en/release-1.4/operations_service.html)

## Motivación

Permitir al área de monitoreo inspeccionar variables de control generadas por los servicios Hyperledger Fabric. Acceder a dichos servicios permitirá al area de monitoreo acceder con mayor precisión al funcionamiento de los componentes utilizados por HyperledgerFabric y el chaincode (smart contract) generado para Padrón Federal

---

## Procedimiento de actualización

1. Conectarse por SSH al equipo **orderer0.orderer.blockchain-tributaria.testnet.afip.gob.ar**

      
    1.1 Posicionarse en el directorio en el cual se instalaron los scripts de arranque.
    
    1.2 Detener el nodo HLF con el siguiente comando

    ```
        $ docker-compose stop
    ```

    1.3 Se debe insertar en el archivo **docker-compose.yaml** el siguiente conjunto de lineas con variables de ambiente en la sección:
    
    ```    
    services:
        orderer0.orderer.blockchain-tributaria.testnet.afip.gob.ar:
            environment:
                #MONITORING
                - ORDERER_METRICS_PROVIDER=prometheus
                - ORDERER_OPERATIONS_LISTENADDRESS=:9443
                - ORDERER_OPERATIONS_TLS_ENABLED=false
                - ORDERER_OPERATIONS_TLS_CLIENTAUTHREQUIRED=false
    ```
    
    1.4 Se debe exponer un nuevo puerto para que sea accesible desde fuera de la red virtualizada docker solamente para su uso local desde el Agente utilizado por monitoreo

    ```
    services:
        orderer0.orderer.blockchain-tributaria.testnet.afip.gob.ar:
          ports:
              - 127.0.0.1:9443:9443
            
    ```
    
    1.5 iniciar el contenedor

    ```
     $ docker-compose up -d
    ```    

    1.6 Verificar que el contendor inicio correctamente con el nuevo servicio OPERATIONS, de la siguiente forma

    ```
     $ curl -v  http://localhost:9443/healthz

     obteniendo un resultado similar al siguiente:
        
     {"status":"OK","time":"2019-09-04T16:08:43.195052367Z"}

    ```

2. Conectarse por SSH al equipo **peer0.blockchain-tributaria.testnet.afip.gob.ar**

      
    2.1 Posicionarse en el directorio en el cual se instalaron los scripts de arranque.
    
    2.2 Detener el nodo HLF con el siguiente comando
    
    ```
     $ docker-compose stop
    ```

    2.3 Se debe insertar en el archivo **docker-compose.yaml** el siguiente conjunto de lineas con variables de ambiente en la sección:
        
    ```
    services:
        peer0.blockchain-tributaria.testnet.afip.gob.ar:
            environment:
                #MONITORING
                 - CORE_METRICS_PROVIDER=prometheus
                 - CORE_OPERATIONS_LISTENADDRESS=:9443
                 - CORE_OPERATIONS_TLS_ENABLED=false
                 - CORE_OPERATIONS_TLS_CLIENTAUTHREQUIRED=false
    ```
    
    2.4 Se debe exponer un nuevo puerto para que sea accesible desde fuera de la red virtualizada docker solamente para su uso local desde el Agente utilizado por monitoreo

    ```
    services:
        peer0.blockchain-tributaria.testnet.afip.gob.ar:
          ports:
              - 127.0.0.1:9443:9443
            
    ```

    2.5 iniciar el contenedor

    ```
     $ docker-compose up -d
    ```
    
    2.6 Verificar que el contendor inicio correctamente con el nuevo servicio OPERATIONS, de la siguiente forma

    ```
    $ curl -v  http://localhost:9443/healthz
        
       
    obteniendo un resultado similar al siguiente:
        
    {"status":"OK","time":"2019-09-04T16:08:43.195052367Z"}

    ```
    
3. Conectarse por SSH al equipo **peer1.blockchain-tributaria.testnet.afip.gob.ar**

      
    3.1 Posicionarse en el directorio en el cual se instalaron los scripts de arranque.
    
    3.2 Detener el nodo HLF con el siguiente comando

    ```
     $ docker-compose stop
    ```

    3.3 Se debe insertar en el archivo **docker-compose.yaml** el siguiente conjunto de lineas con variables de ambiente en la sección:
    
    ```    
    services:
        peer1.blockchain-tributaria.testnet.afip.gob.ar:
            environment:
                #MONITORING
                 - CORE_METRICS_PROVIDER=prometheus
                 - CORE_OPERATIONS_LISTENADDRESS=:9443
                 - CORE_OPERATIONS_TLS_ENABLED=false
                 - CORE_OPERATIONS_TLS_CLIENTAUTHREQUIRED=false
    ```
    
    3.4 Se debe exponer un nuevo puerto para que sea accesible desde fuera de la red virtualizada docker solamente para su uso local desde el Agente utilizado por monitoreo

    ```
    services:
        peer1.blockchain-tributaria.testnet.afip.gob.ar:
          ports:
              - 127.0.0.1:9443:9443
    ```            
    
    3.5 iniciar el contenedor

    ```
    $ docker-compose up -d
    ```
    
    3.6 Verificar que el contendor inicio correctamente con el nuevo servicio OPERATIONS, de la siguiente forma

    ```
     $ curl -v  http://localhost:9443/healthz
       
    obteniendo un resultado similar al siguiente:
        
   {"status":"OK","time":"2019-09-04T16:08:43.195052367Z"}
    ```   
