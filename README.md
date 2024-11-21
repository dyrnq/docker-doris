# docker-doris

docker hub repo [dyrnq/doris](https://hub.docker.com/r/dyrnq/doris/tags)

features:

- TZ support e.g TZ=Asia/Shanghai
- base image: eclipse-temurin:17-jdk-noble or eclipse-temurin:8-jdk-noble
- doris user: doris(1000:1000)
- working dir: /opt/apache-doris

## support doris version

- 1.2.5~1.2.8
- 2.0.0~2.0.15
- 2.1.0~2.1.7
- 3.0.0~3.0.2

## support envs

| env            | default value | optional value                 | required |
|----------------|---------------|--------------------------------|----------|
| TZ             |               | Asia/Shanghai                  | no       |
| RUN_MODE       |               | STANDALONE/FE/BE               | yes      |
| FE_SERVERS     |               | ip or fqdn e.g. fe1:cfe-1:9010 | no       |
| FE_ID          |               | 1                              | no       |
| BE_ADDR        |               | ip or fqdn e.g. cbe-1:9050     | no       |
| BE_IP          |               | ip or fqdn                     | no       |
| BE_PORT        | 9050          |                                | no       |
| FE_MASTER_IP   |               | ip or fqdn                     | no       |
| FE_MASTER_PORT | 9030          |                                | no       |
| USER           | root          |                                | no       |
| PASSWORD       |               |                                | no       |

## usage demo

### docker run

| demo       | path                                                                                                                                             |
|------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| standalone | [usage-demo/docker/run-containers-standalone.sh](https://github.com/dyrnq/docker-doris/blob/main/usage-demo/docker/run-containers-standalone.sh) |
| 1fe-1be    | [usage-demo/docker/run-containers-1fe-1be.sh](https://github.com/dyrnq/docker-doris/blob/main/usage-demo/docker/run-containers-1fe-1be.sh)       |
| 3fe-3be    | [usage-demo/docker/run-containers-3fe-3be.sh](https://github.com/dyrnq/docker-doris/blob/main/usage-demo/docker/run-containers-3fe-3be.sh)       |

### docker compose
| demo       | path                                                                                                                                     |
|------------|------------------------------------------------------------------------------------------------------------------------------------------|
| standalone | [usage-demo/compose/standalone/compose.yaml](https://github.com/dyrnq/docker-doris/blob/main/usage-demo/compose/standalone/compose.yaml) |
| 1fe-1be    | [usage-demo/compose/1fe-1be/compose.yaml](https://github.com/dyrnq/docker-doris/blob/main/usage-demo/compose/1fe-1be/compose.yaml)       |
| 3fe-3be    | [usage-demo/compose/3fe-3be/compose.yaml](https://github.com/dyrnq/docker-doris/blob/main/usage-demo/compose/3fe-3be/compose.yaml)        |

### k8s

| demo       | path                                                                                                                                 |
|------------|--------------------------------------------------------------------------------------------------------------------------------------|
| standalone | [usage-demo/k8s/standalone/sts-nopvc.yaml](https://github.com/dyrnq/docker-doris/blob/main/usage-demo/k8s/standalone/sts-nopvc.yaml) |
| 3fe-3be    | [usage-demo/k8s/3fe-3be/sts-nopvc.yaml](https://github.com/dyrnq/docker-doris/blob/main/usage-demo/k8s/3fe-3be/sts-nopvc.yaml)    |


## ref

- [github.com/apache/doris](https://github.com/apache/doris)
- [doris.apache.org](https://doris.apache.org)
