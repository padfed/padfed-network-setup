# PADFED migración a HLF 1.4.3

## Motivación

Actualizar los servicios HLF a la versión 1.4.3 y nivelar la versión utilizada en QA con la que se utilizará en PROD. Por otro lado este upgrade habilita metricas nuevas requeridas por Operaciones para pruebas de control

---

## Procedimiento de actualización

1. Conectarse por SSH al equipo **orderer0.orderer.blockchain-tributaria.testnet.afip.gob.ar**

      
    1.1 Posicionarse en el directorio en el cual se instalaron los scripts de arranque.
    
    1.2 Detener el nodo HLF con el siguiente comando

    ```
    $ docker-compose stop
    ```

    1.3 Editar el archivo .ENV modificando la siguiente línea
    
    ```    
    HLF_VERSION=1.4.0  
    ```

    por
    
    ```    
    HLF_VERSION=1.4.3
    ```


    1.4 iniciar el contenedor

    ```
     $ docker-compose up -d
    ```    

    **El arranque puede demorar dado que docker daemon descargará las imagenes de HLF actualizadas desde el repositorio público de Docker**


    1.5 Verificar que el contendor inició correctamente de la siguiente forma

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

    2.3 Editar el archivo .ENV modificando la siguiente línea
    
    ```    
    HLF_VERSION=1.4.0  
    ```

    por
    
    ```    
    HLF_VERSION=1.4.3
    ```


    2.4 iniciar el contenedor

    ```
     $ docker-compose up -d
    ```    

    **El arranque puede demorar dado que docker daemon descargará las imagenes de HLF actualizadas desde el repositorio público de Docker**


    2.5 Verificar que el contendor inició correctamente de la siguiente forma

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

    3.3 Editar el archivo .ENV modificando la siguiente línea
    
    ```    
    HLF_VERSION=1.4.0  
    ```

    por
    
    ```    
    HLF_VERSION=1.4.3
    ```


    3.4 iniciar el contenedor

    ```
     $ docker-compose up -d
    ```    

    **El arranque puede demorar dado que docker daemon descargará las imagenes de HLF actualizadas desde el repositorio público de Docker**


    3.5 Verificar que el contendor inició correctamente de la siguiente forma

    ```
    $ curl -v  http://localhost:9443/healthz
        
       
    obteniendo un resultado similar al siguiente:
        
    {"status":"OK","time":"2019-09-04T16:08:43.195052367Z"}

    ```