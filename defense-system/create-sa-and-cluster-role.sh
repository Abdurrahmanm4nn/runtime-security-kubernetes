#!/bin/bash

# create and configure gcp service accounts for falco and falcosidekick
SA_ACCOUNT=falco-falcosk-sa
gcloud iam service-accounts create $SA_ACCOUNT

GOOGLE_PROJECT_ID=$(gcloud config get-value project)

gcloud projects add-iam-policy-binding $GOOGLE_PROJECT_ID \
--member="serviceAccount:${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/cloudfunctions.invoker"

gcloud iam service-accounts add-iam-policy-binding $GOOGLE_PROJECT_ID@appspot.gserviceaccount.com \
--member="serviceAccount:${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $GOOGLE_PROJECT_ID \
--member="serviceAccount:${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/cloudfunctions.developer"

gcloud projects add-iam-policy-binding $GOOGLE_PROJECT_ID \
--member="serviceAccount:${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/secretmanager.secretAccessor"

# modify cluster and node pool to use Workload Identity
gcloud container clusters update target-cluster --region=us-west1-a --workload-pool="${GOOGLE_PROJECT_ID}.svc.id.goog"
gcloud container node-pools update default-pool --cluster=target-cluster --region=us-west1-a --workload-metadata=GKE_METADATA

# create role binding for service account
kubectl create serviceaccount pod-destroyer
kubectl create clusterrole pod-destroyer --verb=delete --resource=pod  # give only pod resource access for delete op 
kubectl create clusterrolebinding pod-destroyer --clusterrole pod-destroyer --serviceaccount default:pod-destroyer

# get pod-destroyer service account
POD_DESTROYER_TOKEN=$(kubectl get secrets $(kubectl get serviceaccounts pod-destroyer -o json \
| jq -r '.secrets[0].name') -o json | jq -r '.data.token' | base64 -d)

# Generate your KUBECONFIG
kubectl config view  --minify --flatten > kubeconfig_pod-destroyer.yaml

# Set the token at the end of yaml
cat << EOF >> kubeconfig_pod-destroyer.yaml
- name: user.name
  user:     
    token: $POD_DESTROYER_TOKEN
