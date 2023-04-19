#!/bin/bash
SA_ACCOUNT=falco-falcosk-sa
GOOGLE_PROJECT_ID=$(gcloud config get-value project)
FUNCTION_NAME=KillIlegalPod

# deploy function
cd ./pod-destroyer-function
gcloud functions deploy $FUNCTION_NAME \
--runtime go120 --trigger-http \
--project $GOOGLE_PROJECT_ID \
--service-account $SA_ACCOUNT@$GOOGLE_PROJECT_ID.iam.gserviceaccount.com \
--set-env-vars "SECRET_ENV_VAR=projects/${GOOGLE_PROJECT_ID}/secrets/pod-destroyer-secret/versions/latest"

gcloud functions add-iam-policy-binding $FUNCTION_NAME \
--member="serviceAccount:${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" \
--role='roles/cloudfunctions.invoker'

gcloud functions add-iam-policy-binding $FUNCTION_NAME \
--member="serviceAccount:${SA_ACCOUNT}@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/cloudfunctions.developer"

# check if function is created
gcloud functions describe --format=json $FUNCTION_NAME | jq -r '.name'