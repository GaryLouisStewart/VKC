#!/bin/bash
# setup gossip encryption keys and bring up consul cluster using helm

chkns='kubectl config view  | grep namespace:'
kubens='f(){ kubectl config set-context $(kubectl config current-context) --namespace="$@";  unset -f f; }; f'

NS=consul
NAMESPACE=$(chkns | awk '{split($0,a, ":"); print a[2]}')
GOSSIP_ENCRYPTION_KEY=$(consul keygen)
NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RELEASE_NAME=consul-$NEW_UUID
CHART_NAME=vkc

echo "Creating Kubernetes Namespace $NS ........%"

kubectl create ns $NS
kubens $NS

echo "Creating generic consul secret ......%"

kubectl create secret generic consul \
  --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY}" \
  --from-file=../../certs/ca/ca.pem \
  --from-file=../../certs/consul/consul.pem \
  --from-file=../../certs/consul/consul-key.pem

echo "Creating configmap from config.json ......%"

kubectl -n $NS create configmap consul --from-file=config.json

"Provision consul cluster.......%"

helm install --name $CHART_NAME --namespace $NAMESPACE $CHART_NAME -f vkc/values.yaml
