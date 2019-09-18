#!/bin/sh
# generate vault certificates for TLS communication

set -eo pipefail

echo "Getting golang packages cfssl & cfssljson........."
go get -u github.com/cloudflare/cfssl/cmd/cfssl
go get -u github.com/cloudflare/cfssl/cmd/cfssljson

echo "Generating a certificate autority......."
[[ -d ../../certs/ca ]] || mkdir -p ../../certs/ca
cfssl gencert -initca ../config/ca-csr.json | cfssljson -bare ../../certs/ca/ca

echo "Creating private key and TLS certificates for Consul......"
[[ -d ../consul ]] || mkdir -p ../consul

cfssl gencert \
    -ca=../../certs/ca/ca.pem \
    -ca-key=../../certs/ca/ca-key.pem \
    -config=../config/ca-config.json \
    -profile=default \
    ../config/consul-csr.json | cfssljson -bare ../../certs/consul/consul

echo "Generating Private key and TLS certificates for Vault......"

[[ -d ../vault ]] || mkdir -p ../vault

mkdir -p vault

cfssl gencert \
    -ca=../../certs/ca/ca.pem \
    -ca-key=../../certs/ca/ca-key.pem \
    -config=../../certs/config/ca-config.json \
    -profile=default \
    ../../certs/config/vault-csr.json | cfssljson -bare ../../certs/vault/vault
