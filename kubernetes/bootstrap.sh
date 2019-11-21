#!/bin/bash
# bootstrap consul & vault

## global vars, functions ###
GOSSIP_ENCRYPTION_KEY=$(consul keygen)
alias k='kubectl'

function kubens {
    k config set-context $(k config current-context) --namespace="$@"; unset -f f;
}

prog() {
    local w=80 p=$1;  shift
    # create a string of spaces, then change them to dots
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /.};
    # print those dots on a fixed-width space plus the percentage etc. 
    printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*"; 
}

#############

#### all of the heavy lifting happens below... #####

function consul_up {
    ### helpers ######
    NS=consul
    POD=$(k get pods -o=name | grep consul | sed "s/^.\{4\}//")
    ##################

    echo "Creating $NS namespace...."
    k create ns $NS

    echo "Changing namespace to $NS...."
    k $NS

    echo "Creating headless consul service.... in namespace $NS"
    k create -f consul/consul-svc.yaml

    echo "Creating configmap consul service yaml.... in namespace $NS"
    k create configmap consul-cfg --from-file=consul/config.json

    echo "Creating headless consul stateful set.... in namespace $NS"
    k create -f consul/consul-statefulset.yaml

    echo "Creating individual services for communication with vault"
    k create -f consul/consul-0-svc.yaml 
    k create -f consul/consul-1-svc.yaml 
    k create -f consul/consul-2-svc.yaml

    echo "Creating consul secret"
    k create secret generic consul \
        --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY}" \
        --from-file=../certs/ca/ca.pem \
        --from-file=../certs/consul/consul.pem \
        --from-file=../certs/consul/consul-key.pem

    while true; do
      STATUS=$(k get pods ${POD} -o jsonpath="{.status.phase}")
       if [ "$STATUS" == "Running" ]; then
         break
       else
         echo "Pod status is: ${STATUS}"
         sleep 5
       fi
    done
}

function vault_up {

    #### helpers #####
    NS="vault"
    POD=$(k get pods -o=name | grep vault | sed "s/^.\{4\}//")
    ###########################

    echo "Creating $NS namespace...."
    k create ns $NS

    echo "Changing namespace to $NS...."
    k $NS

    echo "Creating headless vault service.... in namespace $NS"
    k create -f vault/vault-svc.yaml

    echo "Creating configmap vault service yaml.... in namespace $NS"
    k create configmap vault-cfg --from-file=vault/config.json

    echo "Creating configmap consul service yaml.... in namespace $NS"
    k create configmap consul-cfg --from-file=consul/config.json

    echo "Creating vault deployment.... in namespace $NS"
    k create -f vault/vault-deployment.yaml

    echo "Creating vault secret"
    k create secret generic vault \
        --from-file=../certs/ca/ca.pem \
        --from-file=../certs/vault/vault.pem \
        --from-file=../certs/vault/vault-key.pem
    
    echo "Creating consul secret"
    k create secret generic consul \
        --from-literal="gossip-encryption-key=${GOSSIP_ENCRYPTION_KEY}" \
        --from-file=../certs/ca/ca.pem \
        --from-file=../certs/consul/consul.pem \
        --from-file=../certs/consul/consul-key.pem
    
    while true; do
      STATUS=$(k get pods ${POD} -o jsonpath="{.status.phase}")
      if [ "$STATUS" == "Running" ]; then
         break
      else
         echo "Pod status is: ${STATUS}"
         sleep 5
      fi
    done
}

consul_up
vault_up
