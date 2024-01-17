#!/bin/bash
#
# SCRIPT: mount-minio-bucket.sh
#

# wait for Alluxio leading master to be online
echo Waiting for Alluxio leader to become available
while true
do
  result=$(alluxio fs masterInfo)
  if [[ "$result" == *"Current leader master: alluxio-master-"* ]]; then
    break
  else
    echo "."
    sleep 5
  fi
done

echo Mounting MinIO bucket s3a://hive
alluxio fs chmod -R 777 /
alluxio fs mount \
   --option alluxio.underfs.s3.endpoint=http://minio:9000 \
   --option alluxio.underfs.s3.disable.dns.buckets=true \
   --option alluxio.underfs.s3.inherit.acl=false \
   --option s3a.accessKeyId=minio \
   --option s3a.secretKey=minio123 \
   /hive s3a://hive/

sleep 5
alluxio fs loadMetadata /hive
alluxio fs chmod -R 777 /hive/
alluxio fs chmod -R 777 /hive/warehouse

# end of script
