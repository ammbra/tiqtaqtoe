#!/bin/bash

set -e

PASSWORD="changeit"

CA_ALIAS="ca"
SERVER_ALIAS="server"
CLIENT_ALIAS="client"
TRUSTSTORE="truststore.p12"
CLIENT_CSR="client.csr"

rm -f *.csr *.crt *.key *.srl *.p12 *.jks

echo "🔐 [1/9] Creating CA keypair and self-signed certificate..."
keytool -genkeypair \
  -alias $CA_ALIAS \
  -keyalg ec \
  -dname "CN=MyCA, OU=Test, O=MyOrg, L=City, ST=State, C=US" \
  -ext bc=ca:true \
  -validity 3650 \
  -keystore ca.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -keypass $PASSWORD

echo "🔐 [2/9] Creating SERVER keypair and CSR..."
keytool -genkeypair \
  -alias $SERVER_ALIAS \
  -keyalg ec \
  -dname "CN=localhost, OU=Dev, O=MyOrg, L=City, ST=State, C=US" \
  -validity 365 \
  -keystore server.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -keypass $PASSWORD

keytool -keystore server.p12 \
    -storepass $PASSWORD \
    -genkeypair -alias server-mlkem \
    -keyalg ML-KEM-768 \
    -dname "CN=localhost, OU=Dev, O=MyOrg, L=City, ST=State, C=US" \
    -validity 365 \
    -signer $SERVER_ALIAS

keytool -certreq \
  -alias $SERVER_ALIAS \
  -keystore server.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -file server.csr

echo "📤 [3/9] Exporting CA certificate..."
keytool -exportcert \
  -alias $CA_ALIAS \
  -keystore ca.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -rfc \
  -file ca.crt

echo "🔓 [4/9] Extracting CA private key for signing..."
openssl pkcs12 -in ca.p12 -provider default -nocerts -nodes -passin pass:$PASSWORD -out ca.key

echo "✍️ [5/9] Signing SERVER CSR with CA..."
keytool -gencert -infile server.csr \
  -outfile server-signed.crt \
  -alias $CA_ALIAS \
  -keystore ca.p12 \
  -storepass $PASSWORD \
  -validity 365 \
  -sigalg SHA256withECDSA

echo "📥 [6/9] Importing CA and signed server certificate into server.p12..."
keytool -importcert \
  -alias $CA_ALIAS \
  -file ca.crt \
  -keystore server.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -noprompt

keytool -importcert \
  -alias $SERVER_ALIAS \
  -file server-signed.crt \
  -keystore server.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD

echo "🙋 [7/9] Creating CLIENT keypair and CSR (CN=Ana)..."
keytool -genkeypair \
  -alias $CLIENT_ALIAS \
  -keyalg ec \
  -dname "CN=Ana, OU=Client, O=MyOrg, L=City, ST=State, C=US" \
  -validity 365 \
  -keystore client.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -keypass $PASSWORD

keytool -keystore client.p12 \
    -storepass $PASSWORD \
    -genkeypair -alias client-mlkem \
    -keyalg ML-KEM-768 \
    -dname "CN=Ana, OU=Client, O=MyOrg, L=City, ST=State, C=US" \
    -signer $CLIENT_ALIAS

keytool -certreq \
  -alias $CLIENT_ALIAS \
  -keystore client.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -file $CLIENT_CSR

echo "✍️ [8/9] Signing CLIENT CSR with CA..."

keytool -gencert -infile client.csr \
  -outfile client-signed.crt \
  -alias $CA_ALIAS \
  -keystore ca.p12 \
  -storepass $PASSWORD \
  -validity 365 \
  -sigalg SHA256withECDSA

echo "📥 [9/9] Importing CA and signed client certificate into client.p12..."
keytool -importcert \
  -alias $CA_ALIAS \
  -file ca.crt \
  -keystore client.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -noprompt

keytool -importcert \
  -alias $CLIENT_ALIAS \
  -file client-signed.crt \
  -keystore client.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD

echo "✅ The following files were created:"
echo "  - ca.p12: CA keystore"
echo "  - server.p12: Server keystore (signed by CA)"
echo "  - client.p12: Client keystore (CN=Ana, signed by CA)"