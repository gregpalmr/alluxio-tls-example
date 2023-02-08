#!/bin/bash
#
# SCRIPT: create-tls-certs.sh
#

certs_dir=/alluxio/certs
store_password="changeme123"

echo "Creating SSL keys for masters"

if [ -d $certs_dir ];
then
  \rm -rf $certs_dir
fi
mkdir -p $certs_dir

for fqdn in $(cat /opt/alluxio/conf/masters)
do
  echo "Creating keystore and truststore for all masters "

  # Generate the keystore and certificate
  keytool -genkeypair -keypass ${store_password} -storepass ${store_password}  \
       -keyalg RSA -keysize 2048 \
       -alias ${fqdn} \
       -dname "CN=${fqdn}, OU=Alluxio, L=San Mateo, ST=CA, C=US" \
       -keystore ${certs_dir}/all-masters-keystore.jks
done

for fqdn in $(cat /opt/alluxio/conf/masters)
do
  # Export the certificate's public key to a certificate file
  keytool -export -rfc -storepass ${store_password} \
       -alias ${fqdn} \
       -keystore ${certs_dir}/all-masters-keystore.jks \
       -file ${certs_dir}/${fqdn}.cert

  # Import the certificate's public key to a truststore file
  keytool -import -noprompt -storepass ${store_password} \
       -alias ${fqdn} \
       -file  ${certs_dir}/${fqdn}.cert \
       -keystore ${certs_dir}/${fqdn}-truststore.jks
done

chmod 440 ${certs_dir}/*.jks ${certs_dir}/*.cert
chmod 444 ${certs_dir}/alluxio-client-truststore.jks

# List the contents of the trustore file
echo; echo
echo "Contents of trust store file: ${certs_dir}/alluxio-client-truststore.jks"
echo "(this file will be used by Alluxio client applications to connect to Alluxio daemons)"
echo
keytool -list -v -keystore ${certs_dir}/all-masters-keystore.jks -storepass $store_password | grep 'Owner:'

# end of script
