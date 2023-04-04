#!/bin/bash

export FALCO_NAMESPACE=falco
FUNCTION_NAME=KillIlegalPod

# Get cloud function name
CLOUD_FUNCTION_NAME=$(gcloud functions describe --format=json $FUNCTION_NAME | jq -r '.name')

# add the falcosecurity charts repository
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# Create new namespace for falco
kubectl create namespace $FALCO_NAMESPACE

# install falco using helm
helm upgrade --install falco falcosecurity/falco \
--namespace $FALCO_NAMESPACE \
--set ebpf.enabled=true \
--set falcosidekick.enabled=true \
--set falcosidekick.config.gcp.cloudfunctions.name=${CLOUD_FUNCTION_NAME} \
--set falcosidekick.webui.enabled=true

# annotate falco-falcosidekick resource
kubectl annotate serviceaccount --namespace $FALCO_NAMESPACE falco-falcosidekick \
iam.gke.io/gcp-service-account=${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com

# check if falco running
kubectl logs -n falco $(kubectl get pod -n falco -l app=falco -o=name) -f