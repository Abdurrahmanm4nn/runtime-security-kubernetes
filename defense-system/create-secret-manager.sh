#!/bin/bash

# create a new secrets IAM policy for service account member
SA_ACCOUNT=falco-falcosk-sa
GOOGLE_PROJECT_ID=$(gcloud config get-value project)
gcloud secrets add-iam-policy-binding pod-destroyer \
--role roles/secretmanager.secretAccessor \
--member serviceAccount:$SA_ACCOUNT@$GOOGLE_PROJECT_ID.iam.gserviceaccount.com

# create a new secret
gcloud secrets create pod-destroyer-secret --replication-policy="automatic"

# push kubeconfig as a new version to the created secret
gcloud secrets versions add pod-destroyer --data-file=kubeconfig_pod-destroyer.yaml