#!/usr/bin/env bash

# Install the primary site helm chart into a fresh minikube instance and validate that all the pods were created correctly.
#
# The host environment needs to have the following variables set:
# - FOXGLOVE_API_URL: the URL to the API version being used
# - FOXGLOVE_SITE_TOKEN: a site token for a primary site created with the above API
#
# The host also needs to have minio with lake and inbox buckets created. It can be started with the following:
# ```
# docker compose up -d
# ```
#
# When everything is ready, run the tests with `./test-primary-site-chart.sh ./charts/primary-site`.

set -euo pipefail

chart="${1:-""}"

if [ -z "$chart" ]; then
	echo "usage: ./test-primary-site-chart.sh <path to primary site chart>"
	exit 1
fi

context="$(kubectl config current-context)";

if [ "$context" != "minikube" ]; then
	echo "Tests can only be run against minikube. Tried to run against: $context."
	exit 1
fi

api_url="${FOXGLOVE_API_URL}"
site_token="${FOXGLOVE_SITE_TOKEN}"

cloud_credentials_file="$(mktemp --suffix .yaml)"

cat >>"$cloud_credentials_file" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloud-credentials
type: Opaque
stringData:
  S3_COMPATIBLE_ACCESS_KEY_ID: root
  S3_COMPATIBLE_SECRET_ACCESS_KEY: password
  S3_COMPATIBLE_SERVICE_REGION: default
  S3_COMPATIBLE_SERVICE_URL: http://host.minikube.internal:9000
EOF

trap "rm $cloud_credentials_file" EXIT

set -x

kubectl create namespace foxglove

kubectl create secret generic foxglove-site-token \
	--from-literal="FOXGLOVE_SITE_TOKEN=$site_token" \
	--namespace foxglove

kubectl apply -f "$cloud_credentials_file" --namespace foxglove

helm upgrade --install foxglove-primary-site "$chart" \
	--namespace foxglove \
	--set globals.foxgloveApiUrl="$api_url" \
	--set globals.lake.storageProvider="s3_compatible" \
	--set globals.inbox.storageProvider="s3_compatible" \
	--set garbageCollector.schedule="*/1 * * * *"

log_and_exit() {
	kubectl get pods -n foxglove
	kubectl get events -n foxglove
	kubectl logs -n foxglove deployment/inbox-listener
	kubectl logs -n foxglove deployment/query-service
	kubectl logs -n foxglove deployment/site-controller
	exit 1
}

wait_for_deployment() {
	kubectl wait --for=condition=available deployment "$1" --namespace foxglove --timeout=90s || log_and_exit
}

wait_for_pod() {
	kubectl wait --for=condition=ready pod -l "app=$1" --namespace foxglove --timeout=90s || log_and_exit
}

# Wait for each of the deployments to complete to make sure pods are created
wait_for_deployment site-controller
wait_for_deployment inbox-listener
wait_for_deployment query-service

# Wait for each of the pods to complete to make sure they didn't fail
wait_for_pod site-controller
wait_for_pod inbox-listener
wait_for_pod query-service

# Wait to make sure the garbage-collector job didn't fail
kubectl wait --for=condition=complete job -l app=garbage-collector -n foxglove --timeout=90s || log_and_exit
