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
--create-namespace \
--set ebpf.enabled=true \
--set driver.kind=ebpf \
--set falcosidekick.enabled=true \
--set falcosidekick.webui.enabled=true \
--set falcosidekick.config.gcp.cloudfunctions.name="${CLOUD_FUNCTION_NAME}"

# enable workload identity for cluster and add iam.workloadIdentityUser role for the given Service Account.
gcloud iam service-accounts add-iam-policy-binding $SA_ACCOUNT@$GOOGLE_PROJECT_ID.iam.gserviceaccount.com \
--role="roles/iam.workloadIdentityUser" \
--member="serviceAccount:${GOOGLE_PROJECT_ID}.svc.id.goog[${FALCO_NAMESPACE}/falco-falcosidekick]"

gcloud functions add-iam-policy-binding $FUNCTION_NAME \
--member="serviceAccount:${GOOGLE_PROJECT_ID}.svc.id.goog[${FALCO_NAMESPACE}/falco-falcosidekick]" \
--role='roles/cloudfunctions.invoker'

# annotate falco-falcosidekick serviceaccount to impersonate iam serviceaccount
kubectl annotate serviceaccount falco-falcosidekick --namespace $FALCO_NAMESPACE \
iam.gke.io/gcp-service-account="${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com"

# check if falco running
kubectl get pod -n falco
kubectl wait pods --for=condition=Ready --all -n falco

# patch falcosidekick to use gke metadata server
kubectl patch deployment/falco-falcosidekick -n falco \
--type json -p='[{"op":"add","path":"/spec/template/spec/nodeSelector","value":{"iam.gke.io/gke-metadata-server-enabled":"true"}}]'

# restart falcosidekick
kubectl rollout restart deployment falco-falcosidekick -n falco

# check logs to verify all working correctly
kubectl logs daemonset/falco -n falco
kubectl logs deployment/falco-falcosidekick -n falco