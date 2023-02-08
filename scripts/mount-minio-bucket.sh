#!/bin/bash
#
# SCRIPT: mount-minio-bucket.sh
#

# wait for Alluxio leading master to be online
while true
do
  alluxio fs masterInfo
  if [ $? -ne 0 ];
  then
    break
  else
    echo Waiting for Alluxio leader to become available.
    sleep 5
  fi
done
echo Mounting MinIO bucket s3a://hive
alluxio fs mount \
   --option alluxio.underfs.s3.endpoint=http://minio:9000 \
   --option alluxio.underfs.s3.disable.dns.buckets=true \
   --option alluxio.underfs.s3.inherit.acl=false \
   --option s3a.accessKeyId=minio \
   --option s3a.secretKey=minio123 \
   /hive s3a://hive/
sleep 5
alluxio fs loadMetadata /hive
alluxio fs chmod -R 777 /
alluxio fs chmod -R 777 /hive/
alluxio fs chmod -R 777 /hive/warehouse

# end of script
