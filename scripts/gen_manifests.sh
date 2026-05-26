#!/bin/bash

# always exit if a command fails
set -o errexit

WORKFLOW_FOLDER=$1
WORKFLOW_ID=$2
WORKFLOW_IMAGE_REGISTRY="${WORKFLOW_IMAGE_REGISTRY:-quay.io}"
WORKFLOW_IMAGE_NAMESPACE="${WORKFLOW_IMAGE_NAMESPACE:-orchestrator}"
WORKFLOW_IMAGE_REPO="${WORKFLOW_IMAGE_REPO:-serverless-workflow-${WORKFLOW_ID}}"
WORKFLOW_IMAGE_TAG="${WORKFLOW_IMAGE_TAG:-latest}"

# Red Hat Developer Hub (RHDH) orchestrator e2e persistence — backstage Postgres from installOrchestrator()
RHDH_PG_SECRET_NAME="${RHDH_PG_SECRET_NAME:-backstage-psql-secret}"
RHDH_PG_USER_KEY="${RHDH_PG_USER_KEY:-POSTGRES_USER}"
RHDH_PG_PASSWORD_KEY="${RHDH_PG_PASSWORD_KEY:-POSTGRES_PASSWORD}"
RHDH_PG_SERVICE_NAME="${RHDH_PG_SERVICE_NAME:-backstage-psql}"
RHDH_PG_DATABASE="${RHDH_PG_DATABASE:-backstage_plugin_orchestrator}"
RHDH_PG_NAMESPACE="${RHDH_PG_NAMESPACE:-orchestrator}"

# helper binaries should be either on the developer machine or in the helper
# image quay.io/orchestrator/ubi9-pipeline from setup/Dockerfile, which we use
# to exeute this script. See the Makefile gen-manifests target.
command -v kn-workflow
command -v kubectl
command -v yq

cd "${WORKFLOW_FOLDER}"

echo -e "\nkie.flyway.enabled=true" >> application.properties

kn-workflow gen-manifest --profile='gitops' \
        --image="${WORKFLOW_IMAGE_REGISTRY}/${WORKFLOW_IMAGE_NAMESPACE}/${WORKFLOW_IMAGE_REPO}:${WORKFLOW_IMAGE_TAG}" \
        --namespace=""

# Enable bash's extended blobing for better pattern matching
shopt -s extglob
# Find the workflow file with .sw.yaml suffix since kn-cli uses the ID to generate resource names
workflow_file=$(printf '%s\n' ./*.sw.y?(a)ml 2>/dev/null | head -n 1)
# Disable bash's extended globing
shopt -u extglob

# Check if the workflow_file was found
if [ -z "$workflow_file" ]; then
  echo "No workflow file with .sw.yaml or .sw.yml suffix found."
  exit 1
fi

# Extract the 'id' property from the YAML file and convert to lowercase
workflow_id=$(grep '^id:' "$workflow_file" | awk '{print $2}' | tr -d "\"'" | tr '[:upper:]' '[:lower:]')

# Check if the 'id' property was found
if [ -z "$workflow_id" ]; then
  echo "No 'id' property found in the workflow file."
  exit 1
fi

# the main sonataflow file will have a prefix of variable number, 01 or 02 and so on, because manifests created by
# gen-manifests are now sorted by name. We need to take *-sonataflow-$workflow_id.yaml to resolve that.
SONATAFLOW_CR=$(printf '%s' manifests/*-sonataflow_"${workflow_id}".yaml)

cleanup_generated_manifests() {
    for manifest in manifests/*.yaml; do
        [ -f "${manifest}" ] || continue
        yq --inplace 'del(.metadata.creationTimestamp) | del(.status)' "${manifest}"
    done
}

apply_rhdh_manifest_cleanup() {
    echo "Applying RHDH manifest cleanup (token propagation only, no GHTOKEN secret)..."
    yq --inplace '
      .spec.podTemplate.container.env |= (
        (. // []) | map(select(.name != "GHTOKEN"))
      )
      | (if .spec.podTemplate.container.env == [] then del(.spec.podTemplate.container.env) else . end)
    ' "${SONATAFLOW_CR}"
    rm -f manifests/*secret*.yaml
    cleanup_generated_manifests
}

# The following properties are set in the Sonataflow CR, for each workflow to enable persistence.
# TODO: It should be replaced with a single definition in the SonataflowPlatform CR
if [ "${RHDH_PERSISTENCE}" = true ]; then
    yq --inplace ".spec |= (
      . + {
        \"persistence\": {
          \"postgresql\": {
            \"secretRef\": {
              \"name\": \"${RHDH_PG_SECRET_NAME}\",
              \"userKey\": \"${RHDH_PG_USER_KEY}\",
              \"passwordKey\": \"${RHDH_PG_PASSWORD_KEY}\"
            },
            \"serviceRef\": {
              \"name\": \"${RHDH_PG_SERVICE_NAME}\",
              \"port\": 5432,
              \"databaseName\": \"${RHDH_PG_DATABASE}\",
              \"databaseSchema\": \"${WORKFLOW_ID}\",
              \"namespace\": \"${RHDH_PG_NAMESPACE}\"
            }
          }
        }
      }
    )" "${SONATAFLOW_CR}"
    apply_rhdh_manifest_cleanup
elif [ "${ENABLE_PERSISTENCE}" = true ]; then
    yq --inplace ".spec |= (
      . + {
        \"persistence\": {
          \"postgresql\": {
            \"secretRef\": {
              \"name\": \"sonataflow-psql-postgresql\",
              \"userKey\": \"postgres-username\",
              \"passwordKey\": \"postgres-password\"
            },
            \"serviceRef\": {
              \"name\": \"sonataflow-psql-postgresql\",
              \"port\": 5432,
              \"databaseName\": \"sonataflow\",
              \"databaseSchema\": \"${WORKFLOW_ID}\"
            }
          }
        }
      }
    )" "${SONATAFLOW_CR}"
fi
