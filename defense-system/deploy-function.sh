#!/bin/bash
SA_ACCOUNT=falco-falcosk-sa
GOOGLE_PROJECT_ID=$(gcloud config get-value project)
FUNCTION_NAME=KillPwnedPod

# deploy function
cd ./pod-destroyer-function
gcloud functions deploy $FUNCTION_NAME \
--runtime go113 --trigger-http \
--service-account $SA_ACCOUNT@$GOOGLE_PROJECT_ID.iam.gserviceaccount.com

# check if function is created
gcloud functions describe --format=json $FUNCTION_NAME | jq -r '.name'