#!/usr/bin/env bash


docker network create --driver bridge --subnet=172.20.80.0/24 doris-network >/dev/null 2>&1 || true

docker pull foundationdb/foundationdb:7.1.67
docker pull dyrnq/doris:3.0.6.2


docker rm -f fdb-coord-1 >/dev/null 2>&1 || true

mkdir -p $(pwd)/fdb/fdb-coord-1/{data,logs}

docker run \
-d \
--restart always \
--name fdb-coord-1 \
--network doris-network \
--env FDB_CLUSTER_FILE_CONTENTS=docker:docker@fdb-coord-1:4500 \
-v $(pwd)/fdb/fdb-coord-1/data:/var/fdb/data \
-v $(pwd)/fdb/fdb-coord-1/logs:/var/fdb/logs \
foundationdb/foundationdb:7.1.67


sleep 5s;
docker exec -it fdb-coord-1 bash -c "fdbcli --exec \"configure new single ssd\""
docker exec -it fdb-coord-1 bash -c "fdbcli --exec \"status\""
sleep 5s;

docker rm -f doris-ms >/dev/null 2>&1 || true
docker run \
-d \
--restart always \
--name doris-ms \
--env RUN_MODE=ms \
--network doris-network \
-e DORIS_MS_PROPERTIES="\
fdb_cluster:docker\:docker@fdb-coord-1\:4500

" \
dyrnq/doris:3.0.6.2

# echo $(($((RANDOM << 15)) | $RANDOM))
# 170924324
# file_cache
# file_cache_path
# 描述：用于文件缓存的磁盘路径和其他参数，以数组形式表示，每个磁盘一项。path 指定磁盘路径，total_size 限制缓存的大小；-1 或 0 将使用整个磁盘空间。
# 格式： [{"path":"/path/to/file_cache"，"total_size":21474836480}，{"path":"/path/to/file_cache2"，"total_size":21474836480}]
# 示例： [{"path":"/path/to/file_cache"，"total_size":21474836480}，{"path":"/path/to/file_cache2"，"total_size":21474836480}]
# 默认： [{"path":"${DORIS_HOME}/file_cache"}]

name="doris-stand"
docker rm -f $name >/dev/null 2>&1 || true
mkdir -p $(pwd)/doris/${name}/be/file_cache
docker run \
-d \
--restart always \
--name "${name}" \
--hostname "${name}" \
--env RUN_MODE=standalone \
--network doris-network \
--env TZ=Asia/Shanghai \
--env DORIS_FE_PROPERTIES="\
meta_service_endpoint:doris-ms\:5000
deploy_mode:cloud
cluster_id:170924324
sys_log_level: INFO
log_roll_size_mb: 32" \
--env DORIS_BE_PROPERTIES="
enable_file_cache:true
deploy_mode:cloud
sys_log_level: WARNING
mem_limit: 95%" \
--privileged=true \
-v $(pwd)/doris/${name}/be/file_cache:/opt/doris/be/file_cache \
dyrnq/doris:3.0.6.2

docker rm -f doris-minio >/dev/null 2>&1 || true
mkdir -p $(pwd)/minio/doris-minio/data;
docker run -d \
--name doris-minio \
--network doris-network \
--restart always \
-e MINIO_ROOT_USER=minioadmin \
-e MINIO_ROOT_PASSWORD=minioadmin \
-v $(pwd)/minio/doris-minio/data:/data \
minio/minio server /data --console-address ":9001"

sleep 10s;
docker rm -f doris-mc >/dev/null 2>&1 || true
docker run -d \
--name doris-mc \
--network doris-network \
--entrypoint= \
minio/mc \
/bin/sh -c "
/usr/bin/mc alias set doris-minio http://doris-minio:9000 minioadmin minioadmin;
/usr/bin/mc admin user svcacct add --access-key \"vUR3oLMF5ds8gWCP\" --secret-key \"odWFIZukYrw9dY0G5ezDKMZWbhU0S4oD\" doris-minio minioadmin 2>/dev/null || true;
sleep 5s;
/usr/bin/mc mb doris-minio/doris 2>/dev/null || true;
tail -f /dev/null
"



# docker exec -it doris-stand bash -c "mysql -uroot -P9030 -h127.0.0.1 -e 'show frontends\G;show backends\G;' "

# https://doris.apache.org/zh-CN/docs/3.0/install/deploy-manually/separating-storage-compute-deploy-manually
# https://doris.apache.org/zh-CN/docs/3.0/sql-manual/sql-statements/cluster-management/storage-management/CREATE-STORAGE-VAULT#1-%E5%88%9B%E5%BB%BA-hdfs-storage-vault

cat<<'EOF'
docker exec -it doris-stand bash -c "mysql -uroot -P9030 -h127.0.0.1 -e 'show frontends\G;show backends\G;' "

CREATE STORAGE VAULT IF NOT EXISTS minio_demo_vault
PROPERTIES (
"type" = "S3",
"s3.endpoint" = "doris-minio:9000",
"s3.access_key" = "vUR3oLMF5ds8gWCP",
"s3.secret_key" = "odWFIZukYrw9dY0G5ezDKMZWbhU0S4oD",
"s3.region" = "us-east-1",
"s3.root.path" = "/",
"s3.bucket" = "doris",
"provider" = "S3",
"use_path_style" = "true"
);

SET minio_demo_vault AS DEFAULT STORAGE VAULT;

CREATE DATABASE IF NOT EXISTS testdb;
CREATE TABLE testdb.stuff(
    id                 VARCHAR(512)	        NOT NULL COMMENT "id",
    name               VARCHAR(512)	                 COMMENT "name"
)
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 10;
insert into testdb.stuff values ("1","tom");
insert into testdb.stuff values ("2","jerry");
select * from testdb.stuff;
EOF