#!/bin/bash
#
# SCRIPT: create-tls-certs.sh
#

  certs_dir=/etc/alluxio/certs
  store_password="changeme123"

  echo "Creating SSL keys for masters"
  if [ -d $certs_dir ];
  then
    \rm -rf $certs_dir/*
  fi

  # Set the domain to use with the keystore and trustore
  domain_name="mycompany.com"

  # Generate the keystore and certificate - use a wildcard in the SAN spec
  echo Generating the keystore and certificate
  keytool -genkeypair -keypass ${store_password} -storepass ${store_password}  \
       -keyalg RSA -keysize 2048 \
       -alias all-alluxio-nodes \
       -dname "CN=*.${domain_name}, OU=My Dept, O=My Company, L=Foster City, ST=CA, C=US" -ext san="DNS:*.${domain_name}" \
       -keystore ${certs_dir}/all-alluxio-nodes-keystore.jks

  # Export the certificate’s public key to a certificate file
  echo  Exporting the certificate’s public key to a certificate file
  keytool -export -rfc -storepass ${store_password} \
       -alias all-alluxio-nodes \
       -keystore ${certs_dir}/all-alluxio-nodes-keystore.jks \
       -file ${certs_dir}/all-alluxio-nodes.cert

  # Import the certificate’s public key to a truststore file
  echo Importing the certificate’s public key to a truststore file
  keytool -import -noprompt -storepass ${store_password} \
       -alias all-alluxio-nodes \
       -file  ${certs_dir}/all-alluxio-nodes.cert \
       -keystore ${certs_dir}/all-alluxio-nodes-truststore.jks

chmod 440 ${certs_dir}/*.jks ${certs_dir}/*.cert
chmod 444 ${certs_dir}/all-alluxio-nodes-truststore.jks

# List the contents of the trustore file
echo; echo
echo "Contents of trust store file: ${certs_dir}/all-alluxio-nodes-truststore.jks"
echo "(this file will be used by Alluxio client applications to connect to Alluxio daemons)"
echo
keytool -list -v -keystore ${certs_dir}/all-alluxio-nodes-keystore.jks -storepass $store_password 

# end of script 

