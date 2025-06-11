
Mta
===========

A Helm chart for MTA serverless workflow

> **🚨 Deprecation Notice: 🚨**  
> From Orchestrator release version 1.7, Workflow Types will be retired. All workflows will act as infrastructure workflows, and no workflow will act as an assesment workflow. <br>
> Any reference to assessment workflows will be obsolete.

Migration Toolkit for Application Analysis (MTA) v7.x workflow evaluates applications to determine potential risks and the associated costs of containerizing the applications. It uses the [MTA v7.x Operator](https://docs.redhat.com/en/documentation/migration_toolkit_for_applications/7.0/html/introduction_to_the_migration_toolkit_for_applications/index) to perform the analysis.
At the end of a successful assessment workflow, a link to the report will be available in Backstage, under the notifications plugin.

## Helm chart Configuration

The following table lists the configurable parameters of the Mta chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `mta.url` |  | `"http://mta-ui.openshift-mta.svc.cluster.local:8080"` |


**Note**: The *MTA* workflow type functions as an assessment tool, evaluating the provided code repository and suggesting the next workflow to execute for that repository. Currently, there is a correlation between the *MTA* and *Move2Kube* workflow, where *Move2Kube* is recommended by the *MTA*. Consequently, it is necessary to install both to leverage their benefits fully.

## Workflow application configuration
Please refer to [the workflow README](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/workflows/mta-v7.x/README.md#workflow-application-configuration)

## Persistence pre-requisites
If persistence is enabled, you must have a PostgreSQL instance running in the cluster, in the same `namespace` as the workflows.

A `secret` containing the instance credentials must exists as well. 

See https://www.rhdhorchestrator.io/orchestrator-helm-operator/postgresql on how to install a PostgreSQL instance. Please follow the section detailing how to install using helm. In this document, a `secret` holding the credentials is created.


## Automated installation
Run the [installation script](install-mta-v7.sh):
```console
TARGET_NS=sonataflow-infra ./install-mta-v7.sh
```
You can override the helm repo to use by setting `MTA_HELM_REPO`. By default `orchestrator-workflows/mta-v7` is used and the helm repository `orchestrator-workflows` is installed from `https://rhdhorchestrator.io/serverless-workflows-config`

To use the local file, set `MTA_HELM_REPO` to `.`:
```console
TARGET_NS=sonataflow-infra MTA_HELM_REPO=. ./install-mta-v7.sh
```
## Manual installation

### Prerequisites 
Set `TARGET_NS` to the target namespace:
```console
TARGET_NS=sonataflow-infra
```


### Installation
- Run 
```console
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
helm install mta orchestrator-workflows/mta-v7 -n ${TARGET_NS}
```

### Post-installation
#### Set up the MTA instance with a Jira Connection
Define a Jira instance in MTA and establish a connection to it, by following the [Creating and configuring a Jira connection](https://access.redhat.com/documentation/en-us/migration_toolkit_for_applications/7.0/html/user_interface_guide/creating-configuring-jira-connection#doc-wrapper) guide.

#### Edit the `${WORKFLOW_NAME}-creds` Secret
The token for sending notifications from the MTA-v7.x workflow to RHDH notifications service needs to be provided to the workflow.

Edit the secret `${WORKFLOW_NAME}-creds` and set the value of `NOTIFICATIONS_BEARER_TOKEN`:
```
WORKFLOW_NAME=mta-analysis-v7
oc -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'
```

This secret is used in the `sonataflow` CR to inject the token as an environment variable that will be used by the workflow.

Once the secret is updated, to have it applied, the pod shall be restarted. 
Note that the modification of the secret does not currently restart the pod, the action shall be performed manually or, if you are following the next section, any change to the sonataflow CR will restart the pod.

Note that if you run the `helm upgrade` command, the values of the secret are reseted.

#### Edit the `mta-analysis-v7` Sontaflow CR:

There is one variable required to be set in the `mta-analysis-v7-props` ConfigMap:
* **mta.url** - The URL to the MTA application
* **quarkus.rest-client.notifications.url** - The URL to the backstage application.

We will not set those values directly as quarkus will first try to expand the value of `MTA_URL` and `BACKSTAGE_NOTIFICATIONS_URL` to set the values. Instead, we will set the environment variable in the `mta-analysis-v7` Sontaflow CR:

The value for `BACKSTAGE_NOTIFICATIONS_URL` in the command below is using the current default value, if the name of the backstage deployment or its namespace does not match, please update the value with the correct value from your cluster.

**Please note** that it may take several minutes for the MTA Operator to become available and for the route to be reachable.
```console
while [[ $retry_count -lt 5 ]]; do
    oc -n openshift-mta get route mta && break || sleep 60
    retry_count=$((retry_count + 1))
done
BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator
MTA_ROUTE=$(oc -n openshift-mta get route mta -o yaml | yq -r .spec.host)
oc -n ${TARGET_NS} patch sonataflow mta-analysis-v7 --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"}, {"name": "MTA_URL", "value": "https://'${MTA_ROUTE}'"}]}}}}'
```

## Validate instalation

- Verify MTA resources and workflow are ready:
```console
sleep 120s # to wait until the MTA operator has created all requested resources
oc wait --for=jsonpath='{.status.phase}=Succeeded' -n openshift-mta csv/mta-operator.v7.0.3 --timeout=2m
oc wait --for=condition=Ready=true pods -l "app.kubernetes.io/name=mta-ui" -n openshift-mta --timeout=2m
oc wait -n ${TARGET_NS} sonataflow/mta-analysis-v7 --for=condition=Running --timeout=2m
```


---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

