#!/bin/bash
CLUSTER_CLIENT=$(which oc >/dev/null 2>&1 && echo oc || echo kubectl)

if [[ "${CLUSTER_CLIENT}" == "oc" ]]; then
  echo "Deploying on OCP cluster"
else
  echo "Deploying on k8s cluster"
fi

if [[ -z "${PRIV_ID_RSA_PATH}" ]]; then
  echo 'PRIV_ID_RSA_PATH env variable must be set to the path of the private id_rsa file to use. I.e: ${HOME}/.ssh/id_rsa'
  exit -1
fi

if [[ -z "${PUB_ID_RSA_PATH}" ]]; then
  echo 'PUB_ID_RSA_PATH env variable must be set to the path of the public id_rsa file to use. I.e: ${HOME}/.ssh/id_rsa'
  exit -1
fi

if [[ -z "${TARGET_NS}" ]]; then
  echo 'TARGET_NS env variable must be set to the namespace in which the workflow must be installed'
  exit -1
fi

if [[ ! -z "${K8S_INSTALL}" ]]; then
  echo "Running on k8s, adapting the script"
fi

if [[ -z "${M2K_HELM_REPO}" ]]; then
  M2K_HELM_REPO=orchestrator-workflows/move2kube
  echo "M2K_HELM_REPO not set, using default helm m2k helm repository ${M2K_HELM_REPO}"
  helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
fi

M2K_INSTANCE_NS=move2kube
WORKFLOW_NAME=m2k

"${CLUSTER_CLIENT}" patch configmap/config-features \
    -n knative-serving \
    --type merge \
    -p '{"data":{"kubernetes.podspec-init-containers": "enabled", "kubernetes.podspec-securitycontext": "enabled"}}'
"${CLUSTER_CLIENT}" -n ${TARGET_NS} create secret generic sshkeys --from-file=id_rsa=${PRIV_ID_RSA_PATH} --from-file=id_rsa.pub=${PUB_ID_RSA_PATH}
helm install move2kube ${M2K_HELM_REPO} -n ${TARGET_NS} --set instance.namespace=${M2K_INSTANCE_NS}
if [ $? -ne 0 ]; then
  echo "move2kube chart already installed, run  helm delete move2kube -n ${TARGET_NS} to remove it"
  exit 1
fi

if [[ -z "${K8S_INSTALL}" ]]; then
  "${CLUSTER_CLIENT}" -n ${TARGET_NS} adm policy add-scc-to-user $("${CLUSTER_CLIENT}" -n ${TARGET_NS} get deployments m2k-save-transformation-func-v1-deployment -oyaml | "${CLUSTER_CLIENT}" adm policy scc-subject-review --no-headers  -o yaml --filename - | yq -r .status.allowedBy.name) -z default
  "${CLUSTER_CLIENT}" -n ${M2K_INSTANCE_NS} adm policy add-scc-to-user $("${CLUSTER_CLIENT}" -n ${M2K_INSTANCE_NS} get deployments move2kube -oyaml | "${CLUSTER_CLIENT}" adm policy scc-subject-review --no-headers  -o yaml --filename - | yq -r .status.allowedBy.name) -z default
fi

"${CLUSTER_CLIENT}" -n ${M2K_INSTANCE_NS} create secret generic sshkeys --from-file=id_rsa=${PRIV_ID_RSA_PATH} --from-file=id_rsa.pub=${PUB_ID_RSA_PATH}
"${CLUSTER_CLIENT}" -n ${M2K_INSTANCE_NS} scale deploy move2kube --replicas=0 && "${CLUSTER_CLIENT}" -n ${M2K_INSTANCE_NS} scale deploy move2kube --replicas=1
"${CLUSTER_CLIENT}" -n ${M2K_INSTANCE_NS} wait --for=condition=Ready=true --timeout=2m pod -l app=move2kube

if [[ -z "${K8S_INSTALL}" ]]; then
  M2K_ROUTE="https://"$("${CLUSTER_CLIENT}" -n ${M2K_INSTANCE_NS} get routes move2kube-route -o yaml | yq -r .spec.host)
else
  M2K_ROUTE="http://move2kube-svc.${M2K_INSTANCE_NS}.svc.cluster.local:8080"
fi

"${CLUSTER_CLIENT}" -n ${TARGET_NS} delete ksvc m2k-save-transformation-func 
helm upgrade move2kube ${M2K_HELM_REPO} -n ${TARGET_NS} --set workflow.move2kubeURL=${M2K_ROUTE}

if [[ ! -z "${K8S_INSTALL}" ]]; then
  "${CLUSTER_CLIENT}" -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$("${CLUSTER_CLIENT}" get secret orchestrator-auth -o jsonpath={.data.backend-secret})'"}}'
  BACKSTAGE_NOTIFICATIONS_URL=http://orchestrator-backstage.default.svc.cluster.local:7007
else
  "${CLUSTER_CLIENT}" -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$("${CLUSTER_CLIENT}" get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'
  BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator
fi
BROKER_URL=$("${CLUSTER_CLIENT}" -n ${TARGET_NS} get broker -o yaml | yq -r .items[0].status.address.url)
"${CLUSTER_CLIENT}" -n ${TARGET_NS} patch sonataflow m2k --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"},{"name": "K_SINK", "value": "'${BROKER_URL}'"}, {"name": "MOVE2KUBE_URL", "value": "'${M2K_ROUTE}'"}]}}}}'
"${CLUSTER_CLIENT}" -n ${TARGET_NS} scale deploy m2k --replicas=0
"${CLUSTER_CLIENT}" -n ${TARGET_NS} get pods
"${CLUSTER_CLIENT}" -n ${TARGET_NS} describe pods -l app="${WORKFLOW_NAME}"
"${CLUSTER_CLIENT}" -n ${TARGET_NS} wait --for=condition=Ready=true pods -l app="${WORKFLOW_NAME}" --timeout=2m
"${CLUSTER_CLIENT}" -n ${TARGET_NS} describe pods -l app="${WORKFLOW_NAME}"
