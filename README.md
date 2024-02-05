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

### Step 5. Access the Alluxio Master nodes and Worker nodes

Currently, this package deploys three Alluxio master node containers and two worker node containers, and it starts the Alluxio master node processes and the worker node processes.

To access the Alluxio master node containers, use these commands:

     docker exec -it alluxio-master-1 bash
     docker exec -it alluxio-master-2 bash
     docker exec -it alluxio-master-3 bash

To access the Alluxio worker node containers, use these commands:

     docker exec -it alluxio-worker-1 bash
     docker exec -it alluxio-worker-2 bash

## Step 6. Review the TLS configuration

Open a bash shell to one of the master nodes and view the cert files and the Alluxio properties. Open the bash shell with this command:

     docker exec -it alluxio-master-1 bash

The TLS certificate used in the keystore file was generated with the Java keytool utility and includes a wildcard for the host names. Normally the cert would have each Alluxio master node and worker node hostname in the SAN specification like this:

     -ext SAN="DNS:host1.mycompany.com,DNS:host2.mycompany.com,DNS:host3.mycompany.com"

But, in this implementation a wild card is used like this:

     -etc SAN="DNS:*.mycompany.com"

Inspect the TLS keystore and truststore files with these commands:

     ls -al /alluxio/certs/
     total 20
     drwxr-xr-x 2 root root 4096 Jul 18 22:03 .
     drwxr-xr-x 3 root root 4096 Jul 18 22:03 ..
     -r--r----- 1 root root 2862 Jul 18 22:03 all-alluxio-nodes-keystore.jks
     -r--r--r-- 1 root root 1366 Jul 18 22:03 all-alluxio-nodes-truststore.jks
     -r--r----- 1 root root 1387 Jul 18 22:03 all-alluxio-nodes.cert

These keystore and truststore files were created by the create-tls-certs service in the docker-compose.yaml file and it called the script located here:

     cat /scripts/create-tls-certs.sh

You can view the contents of the main keystore file (which contains the keys for each of the alluxio nodes) by using these commands:

     keytool -list -v -keystore /alluxio/certs/all-alluxio-nodes-keystore.jks -storepass changeme123 

You can view the Alluxio properties file that references these keystore and truststore files using this command:

     cat /opt/alluxio/conf/alluxio-site.properties | more

The key section that references the keystore and truststore files looks like this:

     # TLS keystore properties for the server side of connections
     alluxio.network.tls.enabled=true
     alluxio.network.tls.keystore.path=/etc/alluxio/certs/all-alluxio-nodes-keystore.jks
     alluxio.network.tls.keystore.password=changeme123
     alluxio.network.tls.keystore.key.password=changeme123
     
     # TLS truststore properties for the client side of connections (worker to master, or master to master for embedded journal)
     alluxio.network.tls.enabled=true
     alluxio.network.tls.truststore.path=/etc/alluxio/certs/all-alluxio-nodes-truststore.jks
     alluxio.network.tls.truststore.password=changeme123
     #alluxio.network.tls.truststore.alias=MY_ALIAS # Use this if you have multiple aliases in your truststore
     
View the Alluxio master nodes status using the following two commands:

     bin/alluxio fs masterInfo
and

     bin/alluxio fsadmin report

These commands should show the leading master node and the standby master nodes as well as the "live" worker nodes.

### Step 7. Review the Trino client TLS configuration

To enable a client side workload, such as Trino, to connect to the Alluxio master nodes and worker nodes using an SSL connection, the Alluxio client jar file that is in the Trino classpath will need access to the TLS configuration for Alluxio clients. This can be done by placing a copy of the alluxio-site.properties file in the default location:

     /opt/alluxio/conf/alluxio-site.properties

Or the core-site.xml file that is referenced in the Trino catalog properties file can be updated to include the Alluxio TLS properties. Like this:

     <!-- Configure Alluxio Trustore to access Alluxio master and worker nodes -->
     <property>
       <name>alluxio.network.tls.enabled</name>
       <value>true</value>
     </property>
     <property>
       <name>alluxio.network.tls.truststore.path</name>
       <value>/etc/alluxio/certs/all-alluxio-nodes-truststore.jks</value>
     </property>
     <property>
       <name>alluxio.network.tls.truststore.password</name>
       <value>changeme123</value>
     </property>

### Step 9. Test the Trino access using TLS configuration

a. Open a shell session into the trino-coordinator Docker container using the command:

     docker exec -it trino-coordinator bash

b. In the trino-coordinator shell session window, start a Trino command line session:

     trino --catalog hive --debug

The TPC/H Trino catalog has been pre-configured for this Trino instance and there is a table named "tpch.sf100.customer" that contains about 15 million rows. We will use that table to create a new table in the local MinIO storage environment. Run the following Trino CREATE TABLE command:

     -- Create a 1.5M row table in MinIO storage
     USE default;
     
     CREATE TABLE default.customer
     WITH (
      format = 'ORC',
      external_location = 's3a://minio-bucket-1/user/hive/warehouse/customer/'
     ) 
     AS SELECT * FROM tpch.sf10.customer;

c. Query the new Hive table using Alluxio

In the same Trino cli session, run the following Trino query which will use the Alluxio client jar file to access the MinIO understore. Run the command:

     SELECT custkey, name, mktsegment, phone, acctbal, comment 
     FROM  default.customer
     WHERE acctbal > 3500.00 AND acctbal < 4000.00 
     ORDER BY name;

d. View the Alluxio cache

Since Trino has configured Alluxio to cache on read, you should see data being cached by Alluxio. Open a new shell session into one of the Alluxio master nodes, using the command:

      docker exec -it alluxio-master-1 bash

Then run the Alluxio CLI command to view the Alluxio cache status:

      alluxio fsadmin report 

You should see some cache space being used by the Alluxio worker nodes, like this:

      $ alluxio fsadmin report 

     Alluxio cluster summary:
         Master Address: alluxio-master-3.mycompany.com:19998
         Web Port: 19999
         Rpc Port: 19998
         Started: 02-05-2024 22:55:22:740
         Uptime: 0 day(s), 0 hour(s), 3 minute(s), and 17 second(s)

         ...

         Live Workers: 2
         Lost Workers: 0
         Total Capacity: 2048.00MB
             Tier: MEM  Size: 2048.00MB
         Used Capacity: 647.4MB
             Tier: MEM  Size: 647.4MB
         Free Capacity: 1363.00MB

### Step 10. Destroy the containers

When finished, destroy the docker containers and clean up the docker volumes using these commands:

     docker-compose down

     docker volume prune

---

Please direct questions or comments to greg.palme@alluxio.com
