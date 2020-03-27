# PADFED Testnet

## Scripts de gestión

Todos los scripts de gestión pueden ser ejecutados en modo debug. En este modo los mismos muestran por consola todos los comandos que ejecutan.

Para activar este modo se debe pasarles cualquier valor no vacío en la variable de entorno `DEBUG`. Por ejemplo:

```sh
env DEBUG=1 ch.create.sh
```

O, para toda la sesión de shell:

```sh
export DEBUG=1
ch.create.sh
```

### Scripts generales

|      script       |                                función                                 |
| ----------------- | ---------------------------------------------------------------------- |
| create.network.sh | genera artefactos necesarios para arrancar todos los nodos de la red   |
| clean.network.sh  | elimina artefactos generados por el script anterior                    |
| localize.sh       | permite ejecutar localmente la topología de la testnet                 |
| test.sh           | permite realizar tests de integración transaccionando con el chaincode |

### Scripts de nodos

|      script       |             función              |
| ----------------- | -------------------------------- |
| ch.create.sh      | crear canal y unir peer al mismo |
| ch.join.sh        | unir peer a canal                |
| cc.download.sh    | descargar cc desde repositorio   |
| cc.install.sh     | instalar cc en peer              |
| cc.instantiate.sh | instanciar cc en peer            |
| cc.upgrade.sh     | actualizar cc en peer            |
| cc.call.sh        | invocar transacción de cc        |

## Scripts de desarrollo

### localize.sh

Luego de realizar `create.network.sh` se puede ejecutar:

```sh
localize.sh
```
Para realizar de manera automatizada los siguientes pasos:

1. Reconfigurar los puertos de todos los peers para que funcionen en conjunto en un único host
2. Iniciar los contenedores de todos los peers y orderer
3. Crear el canal
4. Unir todos los peers al canal
5. Descargar e instalar el chaincode versión 0.99.5 en peer0 de cada organización
6. Instanciar el chaincode versión 0.99.5
7. Descargar e instalar el chaincode versión 0.99.6 en peer0 de cada organización
8. Actualizar el chaincode a la versión 0.99.6
9. Invocar putPersona
10. Invocar queryPersona
11. Invocar delPersona

**Atención:** localize.sh intenta ser **idempotente**, esto significa que puede volver a ejecutarse de manera repetida sin problemas ya que detectará que paso ya está realizado y lo omitirá de la ejecución. Es decir que si por cualquier motivo se interrumpiera la ejecución del mismo y se lo vuelve a ejecutar más tarde, este funcionará correctamente realizando únicamente los pasos que aún no se han realizado.

Si luego de esto se ejecuta:

```sh
localize.sh --reset
```

Se eliminan todos los contenedores, se vuelve a generar la configuración de la red y se vuelven a realizar todos los pasos anteriores.

Si se ejecuta:

```sh
localize.sh --reset --reset-only
```

Solo se eliminarán todos los contenedores y configuración de la red dejando el proyecto en estado prístino.

Opcionalmente se le puede suministrar el argumento `--debug` para que muestre (abundante) información sobre la ejecución de sí mismo y de los scripts que invoca.

### test.sh

Este script puede utilizarse para realizar prueba de transacciones.

Al invocarse como:

```sh
test.sh
```

Realizará estos pasos:

1. Invocar putPersona
2. Invocar queryPersona
3. Invocar delPersona

Opcionalmente se le puede suministrar el argumento `--debug` (o la variable de ambiente `DEBUG` con cualquier valor no vacío) para que muestre (abundante) información sobre la ejecución de sí mismo y de los scripts que invoca.
