#!/bin/bash
#
# SCRIPT: init-alluxio-node.sh
#

     # Copy the Alluxio conf files from tmp dir
     cp /tmp/alluxio-files/conf/alluxio-site.properties /opt/alluxio/conf/alluxio-site.properties
     cp /tmp/alluxio-files/conf/log4j.properties /opt/alluxio/conf/log4j.properties
     cp /tmp/alluxio-files/conf/masters /opt/alluxio/conf/masters
     cp /tmp/alluxio-files/conf/workers /opt/alluxio/conf/workers
     chmod 744 /opt/alluxio/conf/*

     # Copy the license key to a file
     if [[ -n "${ALLUXIO_LICENSE_BASE64}" ]]; then
       echo "${ALLUXIO_LICENSE_BASE64}" | base64 -d > /opt/alluxio/license.json
     fi

     # Replace the template variable in alluxio-site.properties file with this hostname
     myhostname=$(hostname)
     sed -i "s/THIS_HOSTNAME/${myhostname}/g" /opt/alluxio/conf/alluxio-site.properties

     # Wait for the TLS certificates to be generated
     echo "Waiting for TLS certificates to be generated in /etc/alluxio/certs dir"
     while true
     do
       if [ -f /etc/alluxio/certs/all-alluxio-nodes-truststore.jks ]; then
         break
       else
         echo "."
         sleep 2
       fi
     done

# end of script
