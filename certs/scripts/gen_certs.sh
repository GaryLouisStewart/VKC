#!/bin/sh
# generate vault certificates for TLS communication

echo "Getting golang packages cfssl & cfssljson........."
go get -u github.com/cloudflare/cfssl/cmd/cfssl
go get -u github.com/cloudflare/cfssl/cmd/cfssljson

echo "Generating a certificate autority......."
cfssl gencert -initca ../config/ca-csr.json | cfssljson -bare ../../certs/ca

echo "Creating private key and TLS certificates for Consul......"

cfssl gencert \
    -ca=../../certs/ca.pem \
    -ca-key=../../certs/ca-key.pem \
    -config=../config/ca-config.json \
    -profile=default \
    ../config/consul-csr.json | cfssljson -bare ../../certs/consul

echo "Generating Private key and TLS certificates for Vault......"

mkdir -p vault

cfssl gencert \
    -ca=../../certs/ca.pem \
    -ca-key=../../certs/ca-key.pem \
    -config=../../certs/config/ca-config.json \
    -profile=default \
    ../../certs/config/vault-csr.json | cfssljson -bare ../../certs/vault
