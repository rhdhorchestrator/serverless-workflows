
Report Portal to Jira (RPJ)
===========

Helm chart to deploy the rpj workflow.



## Helm Configuration
The list of the overridable values can be found in our [git repository](https://github.com/rhdhorchestrator/serverless-workflows-config/blob/v1.4.x/charts/rpj/values.yaml)

The following table lists the configurable parameters of the RPJ chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |


## Workflow application configuration
Please refer to [the workflow README](https://github.com/rhdhorchestrator/serverless-workflows/blob/v1.4.x/workflows/rpj/README.md#workflow-application-configuration)

## Persistence pre-requisites
If persistence is enabled, you must have a PostgreSQL instance running in the cluster, in the same `namespace` as the workflows.

A `secret` containing the instance credentials must exists as well. 

See https://www.rhdhorchestrator.io/orchestrator-helm-operator/postgresql on how to install a PostgreSQL instance. Please follow the section detailing how to install using helm. In this document, a `secret` holding the credentials is created.


## Automated installation
Run the [installation script](install_rpj.sh):
```console
RPJ_TARGET_URL=<URL to RPJ or its proxy application> ./install_rpj.sh
```
You can override the helm repo to use by setting `RPJ_HELM_REPO`. By default `orchestrator-workflows/rpj` is used and the helm repository `orchestrator-workflows` is installed from `https://rhdhorchestrator.io/serverless-workflows-config`

To use the local file, set `RPJ_HELM_REPO` to `.`:
```console
RPJ_HELM_REPO=. RPJ_TARGET_URL=<URL to RPJ or its proxy application> ./install_rpj.sh
```
## Manual installation
### Prerequisites 
Set `TARGET_NS` to the target namespace:
```console
TARGET_NS=sonataflow-infra
```

### Installation
Run 
```console
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
helm install rpj orchestrator-workflows/rpj -n ${TARGET_NS}
```

### Post-installation
#### Configure RPJ proxy application

If the RPJ is configured with https and self-signed certificates, we need to configure its target URL, i.e: the RPJ URL:
```console
oc patch configmap/rpj-proxy-configmap \
    -n ${TARGET_NS}  \
    --type merge \
    -p '{"data":{"TARGET_URL": '"${RPJ_TARGET_URL}"'}}'
oc -n ${TARGET_NS} scale deploy rpj-proxy --replicas=0 && oc -n ${TARGET_NS} scale deploy rpj-proxy --replicas=1
```
With `${RPJ_TARGET_URL}` containing the RPJ URL.


If the RPJ is properly configured, you can skip this step.

#### Edit the `${WORKFLOW_NAME}-creds` Secret
The token for sending notifications from the rpj workflow to RHDH notifications service needs to be provided to the workflow.

Edit the secret `${WORKFLOW_NAME}-creds` and set the value of `NOTIFICATIONS_BEARER_TOKEN`:
```
WORKFLOW_NAME=rpj
oc -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'
```

This secret is used in the `sonataflow` CR to inject the token as an environment variable that will be used by the workflow.

Once the secret is updated, to have it applied, the pod shall be restarted. 
Note that the modification of the secret does not currently restart the pod, the action shall be performed manually or, if you are following the next section, any change to the sonataflow CR will restart the pod.

Note that when you run the `helm upgrade` command, the values of the secret are reseted.

#### Set `RPJ_URL` and `BACKSTAGE_NOTIFICATIONS_URL` for the Sonataflow CR

The value for `BACKSTAGE_NOTIFICATIONS_URL` in the command below is using the current default value, if the name of the backstage deployment or its namespace does not match, please update the value with the correct value from your cluster.

Run the following to set `RPJ_URL` and `BACKSTAGE_NOTIFICATIONS_URL`environment variable in the workflow:
```console
RPJ_URL=http://rpj-proxy-service
BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator
oc -n ${TARGET_NS} patch sonataflow rpj --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"},{"name": "RPJ_URL", "value": "'${RPJ_URL}'"}]}}}}'
```

Note that `RPJ_URL` is set to the proxy application, in case you do not use it, update its value to the RPJ URL.
