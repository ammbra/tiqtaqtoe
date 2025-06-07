#!/bin/bash
set -e

PASSWORD="changeit"

rm -f *.csr *.crt *.key *.srl *.p12 *.jks

echo "🔐 Creating CA-EC keypair..."
keytool -genkeypair \
  -alias ca-ecdsa \
  -keyalg EC \
  -dname "CN=CA-EC, OU=HybridOrg, O=MyOrg, C=US" \
  -validity 3650 \
  -keystore ca-ecdsa.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -keypass $PASSWORD

keytool -exportcert \
  -alias ca-ecdsa \
  -keystore ca-ecdsa.p12 \
  -storepass $PASSWORD \
  -rfc -file ca-ecdsa.crt

openssl pkcs12 -provider default -nomacver -in ca-ecdsa.p12 -nocerts -nodes -out ca-ecdsa.key -passin pass:$PASSWORD

echo "🔐 Creating CA-MLDSA keypair..."
keytool -genkeypair \
  -alias ca-mldsa \
  -keyalg ML-DSA-44 \
  -dname "CN=CA-MLDSA, OU=HybridOrg, O=MyOrg, C=US" \
  -validity 3650 \
  -keystore ca-mldsa.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -keypass $PASSWORD

keytool -exportcert \
  -alias ca-mldsa \
  -keystore ca-mldsa.p12 \
  -storepass $PASSWORD \
  -rfc -file ca-mldsa.crt

openssl pkcs12 -provider default -in ca-mldsa.p12 -nocerts -nodes -out ca-mldsa.key -passin pass:$PASSWORD

echo "🔐 Creating server keypairs..."

keytool -genkeypair \
  -alias server-ecdsa \
  -keyalg EC \
  -dname "CN=localhost, OU=Server, O=MyOrg, C=US" \
  -validity 365 \
  -keystore server.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -keypass $PASSWORD

keytool -certreq \
  -alias server-ecdsa \
  -keystore server.p12 \
  -storepass $PASSWORD \
  -file server-ecdsa.csr

keytool -genkeypair \
  -alias server-mldsa \
  -keyalg ML-DSA-44 \
  -dname "CN=localhost, OU=Server, O=MyOrg, C=US" \
  -validity 365 \
  -keystore server.p12 \
  -storetype PKCS12 \
  -storepass $PASSWORD \
  -keypass $PASSWORD \

keytool -certreq \
  -alias server-mldsa \
  -keystore server.p12 \
  -storepass $PASSWORD \
  -file server-mldsa.csr

echo "✍️ Signing server certs..."

openssl x509 -provider default -req -in server-ecdsa.csr -CA ca-ecdsa.crt -CAkey ca-ecdsa.key \
  -CAcreateserial -out server-ecdsa.crt -days 365 -sha256

openssl x509 -provider default -req -in server-mldsa.csr -CA ca-mldsa.crt -CAkey ca-mldsa.key \
  -CAcreateserial -out server-mldsa.crt -days 365

echo "📥 Importing server certs into server.p12..."

keytool -importcert \
  -alias ca-ecdsa \
  -file ca-ecdsa.crt \
  -keystore server.p12 \
  -storepass $PASSWORD \
  -noprompt

keytool -importcert \
  -alias server-ecdsa \
  -file server-ecdsa.crt \
  -keystore server.p12 \
  -storepass $PASSWORD

keytool -importcert \
  -alias ca-mldsa \
  -file ca-mldsa.crt \
  -keystore server.p12 \
  -storepass $PASSWORD \
  -noprompt

keytool -importcert \
  -alias server-mldsa \
  -file server-mldsa.crt \
  -keystore server.p12 \
  -storepass $PASSWORD

echo "✅ Hybrid keystores created:"
echo "  - server.p12 (EC + ML-dsa)"
