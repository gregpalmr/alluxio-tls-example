# alluxio-tls-example

### An example of enabling TLS encryption with Alluxio Enterprise Edition

---

## INTRO

This git repo provides a complete environment for demonstrating how to configure Alluxio Enterprise Edition TLS encryption. 

This docker compose package deploys Alluxio Enterprise Edition, Trino, Hive metastore, Spark and Minio. It configures a Trino Hive catalog to use the Alluxio Transparent URI feature. See: 

     https://docs.alluxio.io/ee/user/stable/en/operation/Transparent-Uri.html

## USAGE

### Step 1. Install Docker desktop 

Install Docker desktop on your laptop, including the docker-compose command.

     See: https://www.docker.com/products/docker-desktop/

### Step 2. Clone this repo

Use the git command to clone this repo (or download the zip file from the github.com site).

     git clone https://github.com/gregpalmr/alluxio-tls-example

     cd alluxio-tls-example

### Step 3. Specify your Alluxio Enterprise Edition license key

Get a base64 formatted version of your Alluxio Enterprise Edition license key by running the following command:

     export ALLUXIO_LICENSE_BASE64=$(cat ./my-alluxio-license-file.json | base64)

### Step 4. Launch the docker containers.

Launch the containers defined in the docker-compose.yml file using the command:

     docker-compose up -d

The command will create the network object and the docker volumes, then it will take some time to pull the various docker images. When it is complete, you see this output:

     $ docker-compose up -d
     Creating network "alluxio-tls-example_custom" with driver "bridge"
     Creating volume "alluxio-tls-example_keystore" with local driver
     Creating volume "alluxio-tls-example_mariadb-data" with local driver
     Creating volume "alluxio-tls-example_minio-data" with local driver
     Creating volume "alluxio-tls-example_alluxio-data" with local driver
     Creating spark-worker      ... done
     Creating create-tls-certs ... done
     Creating spark-master         ... done
     Creating mariadb              ... done
     Creating minio             ... done
     Creating trino-coordinator    ... done
     Creating alluxio-worker-2     ... done
     Creating alluxio-worker-1     ... done
     Creating minio-create-buckets ... done
     Creating alluxio-master-1     ... done
     Creating alluxio-master-2     ... done
     Creating alluxio-master-3     ... done
     Creating alluxio-mount-minio-bucket ... done
     Creating hive-metastore             ... done

### Step 5. Access the Alluxio Master Nodes

Currently, this package deploys three Alluxio master node containers and two worker node containers, but it does NOT start the Alluxio master and worker daemons. This is so you can experiment with the TLS certificiates (stored in a shared volume and mounted on all containers at /alluxio/certs) and start and restart the master node and worker node daemons at will.

To access the Alluxio master node containers, use these commands:

     docker exec -it alluxio-master-1 bash
     docker exec -it alluxio-master-2 bash
     docker exec -it alluxio-master-3 bash

To access the Alluxio worker node containers, use these commands:

     docker exec -it alluxio-worker-1 bash
     docker exec -it alluxio-worker-2 bash

## Step 6. Inspect the TLS configuration

Open a bash shell to one of the master nodes and view the cert files and the Alluxio properties. Open the bash shell with this command:

     docker exec -it alluxio-master-1 bash

Inspect the TLS keystore and trustore files with these commands:

     ls -al /alluxio/certs/
     total 20
     drwxr-xr-x 2 root root 4096 Jul 18 22:03 .
     drwxr-xr-x 3 root root 4096 Jul 18 22:03 ..
     -r--r----- 1 root root 2862 Jul 18 22:03 all-alluxio-nodes-keystore.jks
     -r--r--r-- 1 root root 1366 Jul 18 22:03 all-alluxio-nodes-truststore.jks
     -r--r----- 1 root root 1387 Jul 18 22:03 all-alluxio-nodes.cert

These keystore and trustore files were created by the create-tls-certs service in the docker-compose.yaml file and it called the script located here:

     cat /scripts/create-tls-certs.sh

You can view the contents of the main keystore file (which contains the keys for each of the alluxio nodes) by using these commands:

     keytool -list -v -keystore /alluxio/certs/all-alluxio-nodes-keystore.jks -storepass changeme123 | more

or

     keytool -list -v -keystore /alluxio/certs/all-alluxio-nodes-keystore.jks -storepass changeme123 | grep 'Owner:'

You can view the Alluxio properties file that references these keystore and trustore files using this command:

     cat /opt/alluxio/conf/alluxio-site.properties | more

The key section that references the keystore and trustore files looks like this:

     # Master TLS properties
     alluxio.network.tls.enabled=true
     alluxio.network.tls.keystore.path=/etc/alluxio/certs/all-alluxio-nodes-keystore.jks
     alluxio.network.tls.keystore.password=changeme123
     alluxio.network.tls.keystore.key.password=changeme123
     alluxio.network.tls.keystore.alias=alluxio-master-1

     # Client TLS properties (worker to master, or master to master, client app to master/worker )
     alluxio.network.tls.enabled=true
     alluxio.network.tls.truststore.path=/etc/alluxio/certs/all-alluxio-nodes-truststore.jks
     alluxio.network.tls.truststore.password=changeme123
     alluxio.network.tls.truststore.alias=alluxio-master-1

### Step 7. Start the Alluxio master node daemons

You can start the Alluxio master node daemons using these commands:

     su - alluxio
     
     cd /opt/alluxio
     bin/alluxio-start.sh master
 
View the master log file using this command:

     tail -f logs/master.log

Do the same for the second master node and the third master node.

If they start successfully and the TLS certificates are configured correctly, you should be able to see a leading master with this command:

     bin/alluxio fs masterInfo

or

     bin/alluxio fsadmin report

### Step 8. Start the Alluxio worker node daemons

To access the Alluxio worker node containers, use these commands:

     docker exec -it alluxio-worker-1 bash

You can start the Alluxio worker node daemons using these commands:

     cd /opt/alluxio
     bin/alluxio-start.sh worker

View the worker log file using this command:

     tail -f logs/worker.log
 
Do the same for the second worker node.

### Step 9. Destroy the containers

When finished, destroy the docker containers and clean up the docker volumes using these commands:

     docker-compose down

     docker volume prune

---

Please direct questions or comments to greg.palme@alluxio.com
