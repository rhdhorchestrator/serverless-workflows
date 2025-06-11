#!/bin/bash
if [[ -z "${RPJ_TARGET_URL}" ]]; then
  echo 'RPJ_TARGET_URL env variable must be set to the URL of the RPJ server. This target URL is used by the RPJ proxy in order to avoid self-signed certificates error.'
  exit -1
fi

if [[ -z "${RPJ_HELM_REPO}" ]]; then
  RPJ_HELM_REPO=orchestrator-workflows/rpj
  echo "M2K_HELM_REPO not set, using default helm rpj helm repository ${RPJ_HELM_REPO}"
  helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
fi

TARGET_NS=sonataflow-infra
WORKFLOW_NAME=rpj

helm install move2kube ${RPJ_HELM_REPO} -n ${TARGET_NS}
if [ $? -ne 0 ]; then
  echo "rpj chart already installed, run  helm delete rpj -n ${TARGET_NS} to remove it"
  exit -1
fi

oc patch configmap/rpj-proxy-configmap \
    -n ${TARGET_NS}  \
    --type merge \
    -p '{"data":{"TARGET_URL": '"${RPJ_TARGET_URL}"'}}'
oc -n ${TARGET_NS} scale deploy rpj-proxy --replicas=0 && oc -n ${TARGET_NS} scale deploy rpj-proxy --replicas=1

oc -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'

RPJ_URL=http://rpj-proxy-service
BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator
oc -n ${TARGET_NS} patch sonataflow "${WORKFLOW_NAME}" --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"},{"name": "RPJ_URL", "value": "'${RPJ_URL}'"}]}}}}'