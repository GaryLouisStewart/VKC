#!/bin/sh
# bootstraps consul & vault

echo "Installing Consul......"

mkdir -p $GOPATH/src/github.com/hashicorp && cd !$
git clone https://github.com/hashicorp/consul.git
cd consul
make tools
make dev

echo "Installing vault......"

mkdir -p $GOPATH/src/github.com/hashicorp && cd $_
git clone https://github.com/hashicorp/vault.git
cd vault
make bootstrap
make dev --debug