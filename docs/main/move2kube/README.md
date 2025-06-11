
Move2kube
===========

Helm chart to deploy the move2kube workflow.



## Helm Configuration
The list of the overridable values can be found in our [git repository](https://github.com/rhdhorchestrator/serverless-workflows-config/blob/main/charts/move2kube/values.yaml)

The following table lists the configurable parameters of the Move2kube chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `sshSecretName` | name of the secret holding the ssh keys that will be used by move2kube resources | `"sshkeys"` |
| `brokerName` | name of the broker used by Knative eventing resources | `"default"` |
| `namespace` | name where install the resources | `"sonataflow-infra"` |
| `workflow.name` | name of the workflow | `"serverless-workflow-m2k"` |
| `workflow.image` | image containing the workflow | `"quay.io/orchestrator/serverless-workflow-move2kube:latest"` |
| `workflow.move2kubeURL` | URL for move2kube instance | `"https://move2kube-route-sonataflow-infra.apps.cluster-8xfw.redhatworkshops.io"` |
| `workflow.backstageNotificationURL` | URL for backstage notification plugin | `"http://orchestrator-backstage.orchestrator/api/notifications/"` |
| `kfunction.name` | name of the Knative function that save the transformation output to git | `"m2k-save-transformation-func"` |
| `kfunction.image` | image of the knative function | `"quay.io/orchestrator/serverless-workflow-m2k-kfunc:latest"` |
| `instance.name` | name of the move2kube instance deployment | `"move2kube"` |
| `instance.image` | image of the move2kube instance | `"quay.io/orchestrator/move2kube-ui:latest"` |

## Workflow application configuration
Please refer to [the workflow README](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/workflows/move2kube/README.md#workflow-application-configuration)

## Persistence pre-requisites
If persistence is enabled, you must have a PostgreSQL instance running in the cluster, in the same `namespace` as the workflows.

A `secret` containing the instance credentials must exists as well. 

See https://www.rhdhorchestrator.io/orchestrator-helm-operator/postgresql on how to install a PostgreSQL instance. Please follow the section detailing how to install using helm. In this document, a `secret` holding the credentials is created.

## General pre-requisites

Knative eventing communication must be enabled by setting the `eventing` spec in the SonataFlowPlatform by following https://github.com/rhdhorchestrator/orchestrator-helm-operator/tree/main/docs/main/eventing-communication.

> [!NOTE]
> In this guide a Kafka cluster is installed along with the broker but you could also use a in-memory broker. However, bear in mind that in-memory brokers are not resilient.

## Automated installation
Run the [installation script](install_m2k.sh):
```console
PRIV_ID_RSA_PATH=${HOME}/.ssh/id_rsa PUB_ID_RSA_PATH=${HOME}/.ssh/id_rsa.pub TARGET_NS=sonataflow-infra ./install_m2k.sh
```
You can override the helm repo to use by setting `M2K_HELM_REPO`. By default `orchestrator-workflows/move2kube` is used and the helm repository `orchestrator-workflows` is installed from `https://rhdhorchestrator.io/serverless-workflows-config`

To use the local file, set `M2K_HELM_REPO` to `.`:
```console
M2K_HELM_REPO=. PRIV_ID_RSA_PATH=${HOME}/.ssh/id_rsa PUB_ID_RSA_PATH=${HOME}/.ssh/id_rsa.pub TARGET_NS=sonataflow-infra ./install_m2k.sh
```
## Manual installation
### Prerequisites 
* Set `TARGET_NS` to the target namespace:
```console
TARGET_NS=sonataflow-infra
```

* Set `M2K_INSTANCE_NS` to the namespace hosting the move2kube instance:
```console
M2K_INSTANCE_NS=move2kube
```

* Set `BROKER_NAME` to the name of the broker and `BROKER_NAMESPACE` to its namespace, here it will be in `TARGET_NS`. 
```console
BROKER_NAME=kafka-broker
BROKER_NAMESPACE=${TARGET_NS}
```

* Create the secret that holds the ssh keys:
```console
oc -n ${TARGET_NS} create secret generic sshkeys --from-file=id_rsa=${HOME}/.ssh/id_rsa --from-file=id_rsa.pub=${HOME}/.ssh/id_rsa.pub
```
If you change the name of the secret, you will also have to provide the value of `sshSecretName` when installing the helm chart(`--set sshSecretName=<name of the secret>`)

If you want to use other ssh keys you should update the `from-file` parameter values to match your own.

If you do not have ssh keys, you can generate them with `ssh-keygen` command. You can for instance refer to https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent 

Note that those ssh keys need to be added to your git repository as well. For bitbucket, it should be on the [account level](https://bitbucket.org/account/settings/ssh-keys/)

View the [Move2Kube README](https://github.com/rhdhorchestrator/serverless-workflows-config/blob/main/charts/move2kube/README.md) on GitHub.


#### For Knative
We need to use `initContainers` and `securityContext` in our Knative services to allow SSH key exchange in move2kube workflow, we have to tell Knative to enable that feature:
```bash
  oc patch configmap/config-features \
    -n knative-serving \
    --type merge \
    -p '{"data":{"kubernetes.podspec-init-containers": "enabled", "kubernetes.podspec-securitycontext": "enabled"}}'

```

### Installation

Run 
```console
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
helm install move2kube orchestrator-workflows/move2kube -n ${TARGET_NS} --set instance.namespace=${M2K_INSTANCE_NS} --set brokerName=${BROKER_NAME} --set brokerNamespace=${BROKER_NAMESPACE}
```

### Post-installation

#### Configure Knative service m2k-save-transformation-func-v1
1. `m2k-save-transformation-func-v1` Knative service runs as root so we need to allow the `default` service account to use `runAsUser` by setting the right permissions:
To know which scc is to be set to the default service account and apply it, run:
```console
oc -n ${TARGET_NS} adm policy add-scc-to-user $(oc -n ${TARGET_NS} get deployments m2k-save-transformation-func-v1-deployment -oyaml | oc adm policy scc-subject-review --no-headers  -o yaml --filename - | yq -r .status.allowedBy.name) -z default
```

#### Configure move2kube instance
To create SSH Keys secret for move2kube instance and configure SCC, run:
```console
oc -n ${M2K_INSTANCE_NS} adm policy add-scc-to-user anyuid -z default
oc -n ${M2K_INSTANCE_NS} create secret generic sshkeys --from-file=id_rsa=${HOME}/.ssh/id_rsa --from-file=id_rsa.pub=${HOME}/.ssh/id_rsa.pub
```

Then force the pod to be recreated:
```console
oc -n ${M2K_INSTANCE_NS} rollout restart deploy move2kube
```

#### Set `M2K_ROUTE` and `BROKER_URL` for the Knative service
As the Knative service cannot be updated, we need to delete if first and then re-create it with the helm command.

Run the following command or follow the steps prompted at the end of the workflow installation to apply it to the `move2kubeURL` parameter:
```console
M2K_ROUTE=$(oc -n ${M2K_INSTANCE_NS} get routes move2kube-route -o yaml | yq -r .spec.host)
oc -n ${TARGET_NS} delete ksvc m2k-save-transformation-func &&
  helm upgrade move2kube orchestrator-workflows/move2kube -n ${TARGET_NS} --set workflow.move2kubeURL=https://${M2K_ROUTE} --set brokerName=${BROKER_NAME} --set brokerNamespace=${BROKER_NAMESPACE}
```

#### Edit the `${WORKFLOW_NAME}-creds` Secret
The token for sending notifications from the m2k workflow to RHDH notifications service needs to be provided to the workflow.

Edit the secret `${WORKFLOW_NAME}-creds` and set the value of `NOTIFICATIONS_BEARER_TOKEN`:
```
WORKFLOW_NAME=m2k
oc -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'
```

This secret is used in the `sonataflow` CR to inject the token as an environment variable that will be used by the workflow.

> [!WARNING]
> Once the secret is updated, to have it applied, the pod shall be restarted. 
> The modification of the secret does not currently restart the pod, the action shall be performed manually or, if you are following the next section, any change to the sonataflow CR will restart the pod.


> [!NOTE]
> When you run the `helm upgrade` command, the values of the secret are reset.

#### Set `M2K_ROUTE` and `BACKSTAGE_NOTIFICATIONS_URL` for the Sonataflow CR

The value for `BACKSTAGE_NOTIFICATIONS_URL` in the command below is using the current default value, if the name of the backstage deployment or its namespace does not match, please update the value with the correct value from your cluster.

Run the following to set `MOVE2KUBE_URL` and `BACKSTAGE_NOTIFICATIONS_URL`environment variable in the workflow:
```console
BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator
BROKER_URL=$(oc -n ${TARGET_NS} get broker -o yaml | yq -r .items[0].status.address.url)
oc -n ${TARGET_NS} patch sonataflow m2k --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"},{"name": "MOVE2KUBE_URL", "value": "https://'${M2K_ROUTE}'"}]}}}}'
```

