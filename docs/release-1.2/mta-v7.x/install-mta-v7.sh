#!/bin/bash
TARGET_NS=sonataflow-infra

if [[ -z "${MTA_HELM_REPO}" ]]; then
  MTA_HELM_REPO=orchestrator-workflows/mta-v7
  echo "MTA_HELM_REPO not set, using default helm mta v7 helm repository ${MTA_HELM_REPO}"
  helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
fi

helm install mta ${MTA_HELM_REPO} -n ${TARGET_NS}
WORKFLOW_NAME=mta-analysis-v7
oc -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'
while [[ $retry_count -lt 5 ]]; do
    oc -n openshift-mta get route mta && break || sleep 60
    retry_count=$((retry_count + 1))
done
MTA_ROUTE=$(oc -n openshift-mta get route mta -o yaml | yq -r .spec.host)
BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator
oc -n ${TARGET_NS} patch sonataflow mta-analysis-v7 --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"}, {"name": "MTA_URL", "value": "https://'${MTA_ROUTE}'"}]}}}}'