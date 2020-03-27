# Test de cambio de CA certs

El test agrega certificados de MSP y TLS a una BC.

Requiere que la BC haya sido creada con el test `src/test/setup-orderer-peer-invoke-cc`.

Los certificados de las nuevas CAs residen en `src/test/change-cacerts/new-crypto-stage/XXX-orderer0` y tienen CNs distintos a los certificados existentes, lo cual es un requisito para que puedan convivar con los existentes en la BC.

cert | existente | nuevo
--- | --- | ---
root | `XXX Root CA` | `XXX Root CA-2`
intermediate MSP | `mspica.blockchain-tributaria.homo.afip.gob.ar` | `mspica.blockchain-tributaria.homo.afip.gob.ar-2`
intermediate TLS | `mspica.blockchain-tributaria.homo.afip.gob.ar` | `mspica.blockchain-tributaria.homo.afip.gob.ar-2`

Para correr el test debe posicionarse en `src/test` y ejecutar

    $ ./change-cacerts/run.sh

Para correr un end2end debe posicionarse en `src/test` y ejecutar

    $ ./setup-orderer-peer-invoke-cc/run.sh && ./change-cacerts/run.sh
