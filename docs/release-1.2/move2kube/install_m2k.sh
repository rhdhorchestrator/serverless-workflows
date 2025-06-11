#!/bin/bash

if [[ -z "${PRIV_ID_RSA_PATH}" ]]; then
  echo 'PRIV_ID_RSA_PATH env variable must be set to the path of the private id_rsa file to use. I.e: ${HOME}/.ssh/id_rsa'
  exit -1
fi

if [[ -z "${PUB_ID_RSA_PATH}" ]]; then
  echo 'PUB_ID_RSA_PATH env variable must be set to the path of the public id_rsa file to use. I.e: ${HOME}/.ssh/id_rsa'
  exit -1
fi

if [[ -z "${M2K_HELM_REPO}" ]]; then
  M2K_HELM_REPO=orchestrator-workflows/move2kube
  echo "M2K_HELM_REPO not set, using default helm m2k helm repository ${M2K_HELM_REPO}"
  helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
fi

TARGET_NS=sonataflow-infra
M2K_INSTANCE_NS=move2kube
WORKFLOW_NAME=m2k
oc patch configmap/config-features \
    -n knative-serving \
    --type merge \
    -p '{"data":{"kubernetes.podspec-init-containers": "enabled", "kubernetes.podspec-securitycontext": "enabled"}}'
oc -n ${TARGET_NS} create secret generic sshkeys --from-file=id_rsa=${PRIV_ID_RSA_PATH} --from-file=id_rsa.pub=${PUB_ID_RSA_PATH}
helm install move2kube ${M2K_HELM_REPO} -n ${TARGET_NS} --set instance.namespace=${M2K_INSTANCE_NS}
if [ $? -ne 0 ]; then
  echo "move2kube chart already installed, run  helm delete move2kube -n ${TARGET_NS} to remove it"
  exit -1
fi
oc -n ${TARGET_NS} adm policy add-scc-to-user $(oc -n ${TARGET_NS} get deployments m2k-save-transformation-func-v1-deployment -oyaml | oc adm policy scc-subject-review --no-headers  -o yaml --filename - | yq -r .status.allowedBy.name) -z default
oc -n ${M2K_INSTANCE_NS} adm policy add-scc-to-user $(oc -n ${M2K_INSTANCE_NS} get deployments move2kube -oyaml | oc adm policy scc-subject-review --no-headers  -o yaml --filename - | yq -r .status.allowedBy.name) -z default
oc -n ${M2K_INSTANCE_NS} create secret generic sshkeys --from-file=id_rsa=${PRIV_ID_RSA_PATH} --from-file=id_rsa.pub=${PUB_ID_RSA_PATH}
oc -n ${M2K_INSTANCE_NS} scale deploy move2kube --replicas=0 && oc -n ${M2K_INSTANCE_NS} scale deploy move2kube --replicas=1
M2K_ROUTE=$(oc -n ${M2K_INSTANCE_NS} get routes move2kube-route -o yaml | yq -r .spec.host)
oc -n ${TARGET_NS} delete ksvc m2k-save-transformation-func 
helm upgrade move2kube ${M2K_HELM_REPO} -n ${TARGET_NS} --set workflow.move2kubeURL=https://${M2K_ROUTE}

oc -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'
BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator
BROKER_URL=$(oc -n ${TARGET_NS} get broker -o yaml | yq -r .items[0].status.address.url)
oc -n ${TARGET_NS} patch sonataflow m2k --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"},{"name": "K_SINK", "value": "'${BROKER_URL}'"}, {"name": "MOVE2KUBE_URL", "value": "https://'${M2K_ROUTE}'"}]}}}}'