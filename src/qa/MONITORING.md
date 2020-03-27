# PADFED Monitoring v1 de la Testnet


## Vision de red Padfed testnet v1

### Servicios Blockchain HLF 1.4.0

Nodos disponibles en ambiente de QA

</br>


#### Perfil del Software a monitorear

| Software | Observaciones | nodo |
| -------- | -------- | ------ |
| RHEL |   |todos|
| docker 18.09.x |   |todos|
| docker-compose 1.21.x |   |todos|
| Hyperledger Fabric 1.4.x |   |todos|
| Certificados x509 | auth,tls  |todos|
| Endpoints GRPCs | client-peer, peer-peer  |todos|
| LevelDB files | Ledger data  |todos|

<br/>


#### Vision Internet

200.1.116.221: orderer0.orderer.blockchain-tributaria.testnet.afip.gob.ar:7050

200.1.116.222: peer0.blockchain-tributaria.testnet.afip.gob.ar:7051

200.1.116.223: peer1.blockchain-tributaria.testnet.afip.gob.ar:7051

</br>
#### Vision Intranet

10.30.11.221: orderer0.orderer.blockchain-tributaria.testnet.afip.gob.ar:7050

10.30.11.222: peer0.blockchain-tributaria.testnet.afip.gob.ar:7051

10.30.11.222: peer1.blockchain-tributaria.testnet.afip.gob.ar:7051


</br>

#### Cliente HLF-Proxy

10.4.34.176: sr-blockchain.cloudhomo.afip.gob.ar

</br>

#### Requerimientos de monitoreo de HLF basicos


| Tipo | Observaciones | nodo |
| -------- | -------- | ------ |
| Resolucion DNS interna/externa |  | todos|
| Puertos activos | placa Interna/Externa | todos|
| Espacio en disco | definido via .env --> ${FABRIC_LEDGER_STORE_PATH} | todos |
| CPU, Memory, IO | Definir umbral de alerta | todos |



<br/>

#### Requerimientos de monitoreo de HLF intermedios


| Tipo | Observaciones | nodo |
| -------- | -------- | ------ |
| request ledgerHeight via CLI | Requiere certificados RO, acceso a nodos  |todos|
| request chaincodes instantiated via CLI | Requiere certificados RO, acceso a nodos  |peer0, peer1|
| request chaincode getStatus | Requiere certificados RO, nuevo metodo en CC | peer0, peer1 |
| Acceso a nodos externos | Validacion rutas y  puertos accesibles | nodos externos ARBA, COMARB |
| Expiración de certificados | Definir alerta | todos |
| Inspeccion de docker logs | Definir criterio de alerta | todos |


<br/>

#### Requerimientos de monitoreo de HLF avanzados


| Tipo | Observaciones | nodo |
| -------- | -------- | ------ |
| **GET /healtz** con respuesta JSON | Requiere TLS cliente, CA independiente, Requiere nueva version de network-setup, Requiere habilitar nuevo puerto  |todos|
| Consumo metricas **Prometheus** | Requiere TLS cliente, CA independiente, Requiere nueva version de network-setup | todos  |
| Envio de metricas **StatsD** | Requiere TLS cliente, CA independiente, Requiere nueva version de network-setup, requiere habilitar nuevo puerto, requiere servicio **StatsD** | todos  |
| request via HLF-proxy | Requiere instalación independiente con certificado RO, alta firewall acceso a nodos | peer0, peer1 |
| **docker inspect** ***<container>*** | Requiere acceso local a los nodos | todos|
| **docker healthcheck** | Requiere desarrollo de script/tool, nueva version de network-setup | todos |



<br/>

### Docker inspect <container>

#### Ejemplo

</br>

>docker inspect peer0.afip.tribfed.gob.ar | jq ."[0].State"


```json
{
  "Status": "running",
  "Running": true,
  "Paused": false,
  "Restarting": false,
  "OOMKilled": false,
  "Dead": false,
  "Pid": 23994,
  "ExitCode": 0,
  "Error": "",
  "StartedAt": "2019-05-07T13:36:11.371769466Z",
  "FinishedAt": "0001-01-01T00:00:00Z"
}

        
```

<br/> 

### Docker healthcheck

#### Ejemplo

</br>

> docker inspect peer0.afip.tribfed.gob.ar | jq ."[0].State.Health"

```json
{
  "Status": "healthy",
  "FailingStreak": 0,
  "Log": [
    {
      "Start": "2016-09-22T23:56:33.192710692Z",
      "End": "2016-09-22T23:56:33.294607324Z",
      "ExitCode": 0,
      "Output": "{\"cluster_name\":\"elasticsearch\",\"status\":\"green\",\"timed_out\":false,\"number_of_nodes\":1,\"number_of_data_nodes\":1,\"active_primary_shards\":0,\"active_shards\":0,\"relocating_shards\":0,\"initializing_shards\":0,\"unassigned_shards\":0,\"delayed_unassigned_shards\":0,\"number_of_pending_tasks\":0,\"number_of_in_flight_fetch\":0,\"task_max_waiting_in_queue_millis\":0,\"active_shards_percent_as_number\":100.0}"
    }
  ]
}

```

<br/> 


### Protocolo *GET /healtz*

#### Ok status

```json
{
  "status": "OK",
  "time": "2009-11-10T23:00:00Z"
}
```


#### Error status

```json
{
  "status": "Service Unavailable",
  "time": "2009-11-10T23:00:00Z",
  "failed_checks": [
    {
      "component": "docker",
      "reason": "failed to connect to Docker daemon: invalid endpoint"
    }
  ]
}
```

### Protocolo *GET /metrics* compatible Prometheus

#### Ejemplo

```javascript
http_response_size_bytes_count{handler="prometheus"} 0
# HELP ledger_blockchain_height Height of the chain in blocks.
# TYPE ledger_blockchain_height gauge
ledger_blockchain_height{channel="padfedchannel"} 206

# HELP grpc_server_unary_requests_completed The number of unary requests completed.
# TYPE grpc_server_unary_requests_completed counter
grpc_server_unary_requests_completed{code="OK",method="Ping",service="gossip_Gossip"} 2

# HELP ledger_transaction_count Number of transactions processed.
# TYPE ledger_transaction_count counter
ledger_transaction_count{chaincode="unknown",channel="padfedchannel",transaction_type="unknown",validation_code="ENDORSEMENT_POLICY_FAILURE"} 236

# HELP chaincode_shim_requests_completed The number of chaincode shim requests completed.
# TYPE chaincode_shim_requests_completed counter
chaincode_shim_requests_completed{chaincode="padfedcc:4:",channel="padfedchannel",success="true",type="GET_STATE"} 236
chaincode_shim_requests_completed{chaincode="padfedcc:4:",channel="padfedchannel",success="true",type="PUT_STATE"} 1921

```