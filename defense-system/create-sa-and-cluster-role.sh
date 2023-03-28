#!/bin/bash

# create and configure gcp service accounts for falco and falcosidekick
SA_ACCOUNT=falco-falcosk-sa
gcloud iam service-accounts create $SA_ACCOUNT

GOOGLE_PROJECT_ID=$(gcloud config get-value project)
gcloud projects add-iam-policy-binding $GOOGLE_PROJECT_ID \
--member="serviceAccount:${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/cloudfunctions.developer"

gcloud projects add-iam-policy-binding $GOOGLE_PROJECT_ID \
--member="serviceAccount:${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/cloudfunctions.invoker"

gcloud container clusters update target-cluster --region=us-west1-a --workload-pool="${GOOGLE_PROJECT_ID}.svc.id.goog"

# enable workload identity for cluster and add iam.workloadIdentityUser role for the given Service Account.
FALCO_NAMESPACE=falco
gcloud iam service-accounts add-iam-policy-binding \
--role roles/iam.workloadIdentityUser \
--member "serviceAccount:${GOOGLE_PROJECT_ID}.svc.id.goog[${FALCO_NAMESPACE}/falco-falcosidekick]" \
  ${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com

# annotate falco-falcosidekick resource
kubectl annotate serviceaccount --namespace $FALCO_NAMESPACE falco-falcosidekick \
iam.gke.io/gcp-service-account=${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com

# create role binding for service account
kubectl create serviceaccount pod-destroyer
kubectl create clusterrole pod-destroyer --verb=delete --resource=pod  # give only pod resource access for delete op 
kubectl create clusterrolebinding pod-destroyer --clusterrole pod-destroyer --serviceaccount default:pod-destroyer

# get pod-deleter service account
POD_DESTROYER_TOKEN=$(kubectl get secrets $(kubectl get serviceaccounts pod-deleter -o json \
| jq -r '.secrets[0].name') -o json | jq -r '.data.token' | base64 -D)

# Generate your KUBECONFIG
kubectl config view  --minify --flatten > kubeconfig_pod-destroyer.yaml

# Set the token at the end of yaml
cat << EOF >> kubeconfig_pod-destroyer.yaml
users:
- name: user.name
  user:
    token: $POD_DESTROYER_TOKEN