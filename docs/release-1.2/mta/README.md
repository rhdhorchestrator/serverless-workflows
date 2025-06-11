MTA Workflow
===========

Migration Toolkit for Application Analysis (MTA) workflow evaluates applications to determine potential risks and the associated costs of containerizing the applications. It uses the [MTA Operator](https://access.redhat.com/documentation/en-us/migration_toolkit_for_applications/6.2/html/introduction_to_the_migration_toolkit_for_applications/index) to perform the analysis.
At the end of a successful assessment workflow, a link to the report will be available in Backstage, under the notifications plugin.

**Note**: The *MTA* workflow type functions as an assessment tool, evaluating the provided code repository and suggesting the next workflow to execute for that repository. Currently, there is a correlation between the *MTA* and *Move2Kube* workflow, where *Move2Kube* is recommended by the *MTA*. Consequently, it is necessary to install both to leverage their benefits fully.

## Helm chart Configuration

The following table lists the configurable parameters of the Mta chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `mta.url` |  | `"http://mta-ui.openshift-mta.svc.cluster.local:8080"` |

## Workflow application configuration
Please refer to [the workflow README](https://github.com/rhdhorchestrator/serverless-workflows/blob/v1.2.x/mta/README.md#workflow-application-configuration)

# Installation
# Pre-installation Configuration
Set `TARGET_NS` to the target namespace:
```console
TARGET_NS=sonataflow-infra
```

## Persistence pre-requisites
The MTA workflow has persistence enabled, you must have a PostgreSQL instance running in the cluster, in the same `namespace` as the workflows.
A `secret` containing the instance credentials must exist as well. 

See [this](https://www.rhdhorchestrator.io/orchestrator-helm-operator/postgresql) on how to install a PostgreSQL instance. Please follow the section detailing how to install using Helm. In this document, a `secret` holding the credentials is created.

## Installing helm chart 
From `charts` folder run 
```console
helm install mta workflows/mta -n sonataflow-infra
```

## Configuration
View the [MTA README on GitHub](https://github.com/rhdhorchestrator/serverless-workflows-config/blob/main/charts/mta/README.md)

## Installation
- Run 
```console
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
helm install mta orchestrator-workflows/mta -n sonataflow-infra
```

## Post-installation
### Edit the `mtaanalysis-props` ConfigMap:

There is one variable required to be set in the `mta-analysis-props` ConfigMap:
* **mta.url** - The URL to the MTA application
* **quarkus.rest-client.notifications.url** - The URL to the backstage application.

We will not set those values directly as quarkus will first try to expand the value of `MTA_URL` and `BACKSTAGE_NOTIFICATIONS_URL` to set the values. Instead, we will set the environment variable in the `mta-analysis` Sontaflow CR:

The value for `BACKSTAGE_NOTIFICATIONS_URL` in the command below is using the current default value, if the name of the backstage deployment or its namespace does not match, please update the value with the correct value from your cluster.

**Please note** that it may take several minutes for the MTA Operator to become available and for the route to be reachable.
```console
while [[ $retry_count -lt 5 ]]; do
    oc -n openshift-mta get route mta && break || sleep 60
    retry_count=$((retry_count + 1))
done
BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator
MTA_ROUTE=$(oc -n openshift-mta get route mta -o yaml | yq -r .spec.host)
oc -n ${TARGET_NS} patch sonataflow mta-analysis --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"}, {"name": "MTA_URL", "value": "https://'${MTA_ROUTE}'"}]}}}}'
```

### Edit the `${WORKFLOW_NAME}-creds` Secret
The token for sending notifications from the MTA workflow to RHDH notifications service needs to be provided to the workflow.

Edit the secret `${WORKFLOW_NAME}-creds` and set the value of `NOTIFICATIONS_BEARER_TOKEN`:
```
WORKFLOW_NAME=mtaanalysis
oc -n sonataflow-infra patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'
```

This secret is used in the `sonataflow` CR to inject the token as an environment variable that will be used by the workflow.

### Validate instalation

- Verify MTA resources and workflow are ready:
```console
sleep 120s # to wait until the MTA operator has created all requested resources
oc wait --for=jsonpath='{.status.phase}=Succeeded' -n openshift-mta csv/mta-operator.v6.2.3 --timeout=2m
oc wait --for=condition=Ready=true pods -l "app.kubernetes.io/name=mta-ui" -n openshift-mta --timeout=2m
oc wait -n sonataflow-infra sonataflow/mtaanalysis --for=condition=Running --timeout=2m
```