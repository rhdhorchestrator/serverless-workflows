#!/bin/bash
CLUSTER_CLIENT=$(which "${CLUSTER_CLIENT}" >/dev/null 2>&1 && echo oc || echo kubectl)

if [[ ! -z "${K8S_INSTALL}" ]]; then
  echo "Running on k8s, adapting the script"
fi

if [[ -z "${MTA_HELM_REPO}" ]]; then
  MTA_HELM_REPO=orchestrator-workflows/mta-v7
  echo "MTA_HELM_REPO not set, using default helm mta v7 helm repository ${MTA_HELM_REPO}"
  helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
fi

if [[ -z "${TARGET_NS}" ]]; then
  echo 'TARGET_NS env variable must be set to the namespace in which the workflow must be installed'
  exit -1
fi

helm install mta ${MTA_HELM_REPO} -n ${TARGET_NS}
WORKFLOW_NAME=mta-analysis-v7
if [[ -z "${K8S_INSTALL}" ]]; then
  "${CLUSTER_CLIENT}" -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$("${CLUSTER_CLIENT}" get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'
  BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator

  while [[ $retry_count -lt 5 ]]; do
      "${CLUSTER_CLIENT}" -n openshift-mta get route mta && break || sleep 60
      retry_count=$((retry_count + 1))
  done
  MTA_ROUTE="https://"$("${CLUSTER_CLIENT}" -n openshift-mta get route mta -o yaml | yq -r .spec.host)
else
  "${CLUSTER_CLIENT}" -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$("${CLUSTER_CLIENT}" get secret orchestrator-auth -o jsonpath={.data.backend-secret})'"}}'
  BACKSTAGE_NOTIFICATIONS_URL=http://orchestrator-backstage.default.svc.cluster.local:7007
  MTA_ROUTE="http://tackle-ui.my-konveyor-operator.svc.cluster.local:8080"
fi
"${CLUSTER_CLIENT}" -n "${TARGET_NS}" patch sonataflow "${WORKFLOW_NAME}" --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"}, {"name": "MTA_URL", "value": "'${MTA_ROUTE}'"}]}}}}'
"${CLUSTER_CLIENT}" -n ${TARGET_NS} scale deploy "${WORKFLOW_NAME}" --replicas=0
"${CLUSTER_CLIENT}" -n ${TARGET_NS} get pods
"${CLUSTER_CLIENT}" -n ${TARGET_NS} describe pods -l app="${WORKFLOW_NAME}"
"${CLUSTER_CLIENT}" -n "${TARGET_NS}" wait --for=condition=Ready=true pods -l app="${WORKFLOW_NAME}" --timeout=2m
"${CLUSTER_CLIENT}" -n ${TARGET_NS} describe pods -l app="${WORKFLOW_NAME}"
