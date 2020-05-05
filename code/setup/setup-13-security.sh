#!/bin/bash

CA_HOST="znw-linapp1027.statoil.no"
CA_NAME="equinor_kafka"
PASSWD="J#@Uv__@8DQ_Yn3hfhh9_XR_"
# CA HOST should be first in array:
declare -a BROKERS=('znw-linapp1027.statoil.no' 'znw-linapp1028.statoil.no' 'znw-linapp1029.statoil.no');
#declare -a BROKERS=('znw-linapp1027.statoil.no');
#location="$HOME/private"
location="/var/ssl/private"


# Check this script is runned on the CA host
HOST_NAME=$(/bin/hostname -f)
if [[ "$CA_HOST" != "$HOST_NAME" ]];
then
  echo "This script must be runned on the CA host $CA_HOST"
  exit 1
fi

# Cleanup files
#rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12

# Create the directory on $CA_HOST
if [[ -d $location ]]; then
  echo "Renaming $i:$location"
  sudo mv /var/ssl/private /var/ssl/private_$(date +%Y%m%d_%H%M%S)
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
fi
echo "Create the directory $i:$location"
sudo mkdir -p $location
if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
sudo chown f_etlbroker:f_etlbroker $location
if [[ $? != 0 ]]; then echo "Error"; exit 1; fi

# Seems openssl command need to output key file to current directory
cd $(echo $location | tr -d '\r')

# Generate CA key
echo "Generate CA key"
/bin/openssl req -new -x509 -keyout $CA_NAME-ca-1.key -out $CA_NAME-ca-1.crt -days 365 -subj '/CN=znw-linapp1027.statoil.no/OU=KAFKA/O=EQUINOR/L=Stavanger/S=Rogaland/C=NO' -passin pass:$PASSWD -passout pass:$PASSWD
if [[ $? != 0 ]]; then echo "Error"; exit 1; fi

for i in "${BROKERS[@]}"
do
  echo "--Start----------------------------- $i -------------------------------"

  # Find FQDN
  HOST_NAME=$(/bin/ssh $i "/bin/hostname -f")

  # Create the directory on $i
  if [[ "$i" != "${BROKERS[0]}" ]]; then
    if $(/bin/ssh $i "/bin/test -d $location"); then
      echo "Renaming $i:$location"
      ssh=$(/bin/ssh $i "sudo mv /var/ssl/private /var/ssl/private_$(date +%Y%m%d_%H%M%S)")
      if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
    fi
    echo "Create the directory $i:$location"
    ssh=$(/bin/ssh $i "sudo mkdir -p $location")
    if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
    ssh=$(/bin/ssh $i "sudo chown f_etlbroker:f_etlbroker $location")
    if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
  fi

  # Create host keystore
  echo "Create host keystore"
  ssh=$(/bin/ssh $i "mkdir -p $location; /bin/keytool -genkey -noprompt -alias $HOST_NAME -dname "\"CN=$HOST_NAME,OU=KAFKA,O=EQUINOR,L=Stavanger,S=Rogaland,C=NO"\" -ext san=dns:$HOST_NAME -keystore $location/$i.keystore.jks -ke
yalg RSA -storepass "\"$PASSWD"\" -keypass "\"$PASSWD"\"")
if [[ $? != 0 ]]; then echo "Error"; exit 1; fi


  # Create the certificate signing request (CSR)
  echo "Create the certificate signing request (CSR)"
  ssh=$(/bin/ssh $i "/bin/keytool -keystore $location/$i.keystore.jks -alias $HOST_NAME -certreq -file $location/$i.csr -storepass "\"$PASSWD"\" -keypass "\"$PASSWD"\"")
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi

  # Copy the certificate signing request (CSR) to local
  if [[ "$i" != "${BROKERS[0]}" ]]; then
    echo "Copy the certificate signing request (CSR) to local"
    scp=$(/bin/scp ${i}:$location/$i.csr $location/$i.csr)
    if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
  fi

  # Sign the host certificate with the certificate authority (CA)
  echo "Sign the host certificate with the certificate authority (CA)"
  /bin/openssl x509 -req -CA $CA_NAME-ca-1.crt -CAkey $CA_NAME-ca-1.key -in $i.csr -out $i-ca-1-signed.crt -days 9999 -CAcreateserial -passin pass:"$PASSWD"
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi

  # Copy the signed certificate to remote host
  if [[ "$i" != "${BROKERS[0]}" ]]; then
    echo "Copy the signed certificate to remote host"
    scp=$(/bin/scp $i-ca-1-signed.crt ${i}:$location/.)
    if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
  fi

  # Delete the certificate signing request (CSR) on local host
  if [[ "$i" != "${BROKERS[0]}" ]]; then
    echo "Delete the certificate signing request (CSR) on local host"
    if $(/bin/test -f $location/$i.csr); then
      /bin/rm $location/$i.csr
      if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
    fi
  fi

  # Delete the signed certificate on local host
  if [[ "$i" != "${BROKERS[0]}" ]]; then
    echo "Delete the signed certificate on local host"
    if $(/bin/test -f $location/$i-ca-1-signed.crt); then
      /bin/rm $location/$i-ca-1-signed.crt
      if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
    fi
  fi

  # Copy the CA cert to remote host
  if [[ "$i" != "${BROKERS[0]}" ]]; then
    echo "Copy the CA cert to remote host"
    scp=$(/bin/scp $CA_NAME-ca-1.crt ${i}:$location/.)
    if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
  fi

  # Sign and import the CA cert into the keystore
  echo "Sign and import the CA cert into the keystore"
  ssh=$(/bin/ssh $i "/bin/keytool -noprompt -keystore $location/$i.keystore.jks -alias CARoot -import -file $location/$CA_NAME-ca-1.crt -storepass "\"$PASSWD"\" -keypass "\"$PASSWD"\"")
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi

  # Sign and import the host certificate into the keystore
  echo "Sign and import the host certificate into the keystore"
  ssh=$(/bin/ssh $i "/bin/keytool -noprompt -keystore $location/$i.keystore.jks -alias $HOST_NAME -import -file $location/$i-ca-1-signed.crt -storepass "\"$PASSWD"\" -keypass "\"$PASSWD"\"")
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi

  # Delete the signed certificate on remote host
  if [[ "$i" != "${BROKERS[0]}" ]]; then
    echo "Delete the signed certificate on remote host"
    if $(/bin/ssh $i "/bin/test -f $location/$i-ca-1-signed.crt"); then
      ssh=$(/bin/ssh $i "/bin/rm $location/$i-ca-1-signed.crt")
      if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
    fi
  fi

  # Create truststore and import the CA cert
  echo "Create truststore and import the CA cert"
  ssh=$(/bin/ssh $i "/bin/keytool -noprompt -keystore $location/$i.truststore.jks -alias CARoot -import -file  $location/$CA_NAME-ca-1.crt -storepass "\"$PASSWD"\" -keypass "\"$PASSWD"\"")
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi

  # Delete the CA cert on remote host
  if [[ "$i" != "${BROKERS[0]}" ]]; then
    echo "Delete the CA cert on remote host"
    if $(/bin/ssh $i "/bin/test -f $location/$CA_NAME-ca-1.crt"); then
      ssh=$(/bin/ssh $i "/bin/rm $location/$CA_NAME-ca-1.crt")
      if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
    fi
  fi

  # Save creds
  if [[ "$i" == "${BROKERS[0]}" ]]; then
    echo "Save creds"
    echo $PASSWD > $location/sslkey_creds
    echo $PASSWD > $location/keystore_creds
    echo $PASSWD > $location/truststore_creds
  fi

  # Copy the creds files to remote host
  if [[ "$i" != "${BROKERS[0]}" ]]; then
    echo "Copy the creds files to remote host"
    scp=$(/bin/scp $location/*_creds ${i}:$location/.)
    if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
  fi

  # Create pem files and keys used for Schema Registry HTTPS testing
  #   openssl x509 -noout -modulus -in client.certificate.pem | openssl md5
  #   openssl rsa -noout -modulus -in client.key | openssl md5
  #   echo "GET /" | openssl s_client -connect localhost:8082/subjects -cert client.certificate.pem -key client.key -tls1
  echo "Create pem files and keys used for Schema Registry HTTPS testing"
  ssh=$(/bin/ssh $i "/bin/keytool -export -alias $HOST_NAME -file $location/$i.der -keystore $location/$i.keystore.jks -storepass "\"$PASSWD"\"")
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
  ssh=$(/bin/ssh $i "/bin/openssl x509 -inform der -in $location/$i.der -out $location/$i.certificate.pem")
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
  ssh=$(/bin/ssh $i "/bin/keytool -importkeystore -srckeystore $location/$i.keystore.jks -destkeystore $location/$i.keystore.p12 -deststoretype PKCS12 -deststorepass "\"$PASSWD"\" -srcstorepass "\"$PASSWD"\" -noprompt")
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi
  ssh=$(/bin/ssh $i "/bin/openssl pkcs12 -in $location/$i.keystore.p12 -nodes -nocerts -out $location/$i.key -passin pass:"\"$PASSWD"\"")
  if [[ $? != 0 ]]; then echo "Error"; exit 1; fi


  echo "--End------------------------------- $i -------------------------------"
done