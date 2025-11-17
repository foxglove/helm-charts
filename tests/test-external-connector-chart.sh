#!/usr/bin/env bash

# Install the external connector helm chart into a fresh minikube instance and validate that all the pods were created correctly.
#
# The host also needs to have minio with cache bucket created. It can be started with the following:
#
# ```
# docker compose up -d
# ```
#
# When everything is ready, run the tests with `./test-external-connector-chart.sh ./charts/external-connector`.

set -euo pipefail

chart="${1:-""}"

if [ -z "$chart" ]; then
	echo "usage: ./test-external-connector-chart.sh <path to external connector chart>"
	exit 1
fi

context="$(kubectl config current-context)";

if [ "$context" != "minikube" ]; then
	echo "Tests can only be run against minikube. Tried to run against: $context."
	exit 1
fi

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

kubectl apply -f "$cloud_credentials_file" --namespace foxglove

helm upgrade --install foxglove-external-connector "$chart" \
	--namespace foxglove \
	--set globals.cache.storageProvider="s3_compatible"

log_and_exit() {
	kubectl get pods -n foxglove
	kubectl get events -n foxglove
	kubectl logs -n foxglove deployment/external-connector
	exit 1
}

wait_for_deployment() {
	kubectl wait --for=condition=available deployment "$1" --namespace foxglove --timeout=90s || log_and_exit
}

wait_for_pod() {
	kubectl wait --for=condition=ready pod -l "app=$1" --namespace foxglove --timeout=90s || log_and_exit
}

# Wait for each of the deployments to complete to make sure pods are created
wait_for_deployment external-connector

# Wait for each of the pods to complete to make sure they didn't fail
wait_for_pod external-connector
