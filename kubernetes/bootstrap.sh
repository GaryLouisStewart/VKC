#!/bin/bash
# bootstrap consul & vault

## global vars, functions ###
GOSSIP_ENCRYPTION_KEY=$(consul keygen)

function kubens {
    kubectl config set-context $(kubectl config current-context) --namespace="$@"; unset -f f;
}
#############

#### all of the heavy lifting happens below... #####

function consul_up {
    ### helpers ######
    NS=consul
    ##################

    echo "Creating $NS namespace...."
    kubectl create ns $NS

    echo "Changing namespace to $NS...."
    kubens $NS

    echo "Creating headless consul service.... in namespace $NS"
    kubectl create -f consul/consul-svc.yaml

    echo "Creating configmap consul service yaml.... in namespace $NS"
    kubectl create configmap consul-cfg --from-file=consul/config.json

    echo "Creating headless consul stateful set.... in namespace $NS"
    kubectl create -f consul/consul-statefulset.yaml

    echo "Creating individual services for communication with vault"
    kubectl create -f consul/consul-0-svc.yaml 
    kubectl create -f consul/consul-1-svc.yaml 
    kubectl create -f consul/consul-2-svc.yaml

    echo "Creating consul secret"
    kubectl create secret generic consul \
        --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY}" \
        --from-file=../certs/ca/ca.pem \
        --from-file=../certs/consul/consul.pem \
        --from-file=../certs/consul/consul-key.pem
}

function vault_up {

    #### helpers #####
    NS="vault"
    ###########################

    echo "Creating $NS namespace...."
    kubectl create ns $NS

    echo "Changing namespace to $NS...."
    kubens $NS

    echo "Creating headless vault service.... in namespace $NS"
    kubectl create -f vault/vault-svc.yaml

    echo "Creating configmap vault service yaml.... in namespace $NS"
    kubectl create configmap vault-cfg --from-file=vault/config.json

    echo "Creating configmap consul service yaml.... in namespace $NS"
    kubectl create configmap consul-cfg --from-file=consul/config.json

    echo "Creating vault deployment.... in namespace $NS"
    kubectl create -f vault/vault-deployment.yaml

    echo "Creating vault secret"
    kubectl create secret generic vault \
        --from-file=../certs/ca/ca.pem \
        --from-file=../certs/vault/vault.pem \
        --from-file=../certs/vault/vault-key.pem
    
    echo "Creating consul secret"
    kubectl create secret generic consul \
        --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY}" \
        --from-file=../certs/ca/ca.pem \
        --from-file=../certs/consul/consul.pem \
        --from-file=../certs/consul/consul-key.pem
}

consul_up
vault_up