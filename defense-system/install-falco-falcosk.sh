#!/bin/bash

export FALCO_NAMESPACE=falco
SA_ACCOUNT=falco-falcosk-sa
FUNCTION_NAME=KillIlegalPod
GOOGLE_PROJECT_ID=$(gcloud config get-value project)

# Get cloud function name
CLOUD_FUNCTION_NAME=$(gcloud functions describe --format=json $FUNCTION_NAME | jq -r '.name')

# add the falcosecurity charts repository
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# install falco using helm
helm install falco falcosecurity/falco \
--namespace $FALCO_NAMESPACE \
--set ebpf.enabled=true \
--set driver.kind=ebpf \
--set falcosidekick.enabled=true \
--set falcosidekick.config.gcp.cloudfunctions.name="${CLOUD_FUNCTION_NAME}" \
--set falcosidekick.webui.enabled=true

# annotate falco-falcosidekick resource
kubectl annotate serviceaccount --namespace $FALCO_NAMESPACE falco-falcosidekick \
iam.gke.io/gcp-service-account="${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com"

# check if falco running
kubectl get pod -n falco
kubectl logs daemonset/falco -n falco
kubectl logs deployment/falco-falcosidekick -n falco