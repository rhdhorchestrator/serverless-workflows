
Create OCP project
===========

A Helm chart for the create OCP project serverless workflow


## Helm Chart Configuration

The following table lists the configurable parameters of the Create OCP project chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
|                          |                         |                |

## Workflow application configuration

Please refer to [the workflow README](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/workflows/create-ocp-project/README.md#workflow-application-configuration)

## Pre-requisites

If persistence is enabled, you must have a PostgreSQL instance running in the same `namespace` as the workflows. Typically this is the `sonataflow-infra` namespace.

A Secret containing the PostgreSQL credentials must exist as well. See https://www.rhdhorchestrator.io/orchestrator-helm-operator/postgresql on how to install a PostgreSQL instance. Please follow the section detailing how to install it using Helm - this will create the necessary secret and credentials.

## Installation Steps

### Install the Helm Chart 

From the `charts` folder in this repository run:

```bash
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
export TARGET_NS=sonataflow-infra
helm install create-ocp-project orchestrator-workflows/create-ocp-project --namespace=$TARGET_NS
```
After the workflow is installed, you must configure environment variables for it to function.

### Prepare Environment Variables

Gather the following values for environment variables before moving on to the next section.

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `BACKSTAGE_NOTIFICATIONS_URL`      | The Backstage server URL for notifications, e.g `https://backstage.myhost.com` | ✅ | |
| `NOTIFICATIONS_BEARER_TOKEN`      | The authorization bearer token to use to send notifications. This can be found in the Backstage configuration under `app.backend.auth.externalAccess` ([example](https://github.com/rhdhorchestrator/orchestrator-helm-operator/blob/main/docs/release-1.2/existing-rhdh.md#app-config-configmap)) | ✅ | |
| `JIRA_URL`      | The Jira server URL, e.g `https://your-instance.atlassian.net` | ✅ | |
| `JIRA_USERNAME`      | The Jira username, e.g `you@company.com` | ✅ | |
| `JIRA_API_TOKEN`      | The Jira API token associated with the username. If you're using Jira cloud, you can obtain a token [at this link](https://id.atlassian.com/manage-profile/security/api-tokens). | ✅ | |
| `OCP_API_SERVER_URL`      | The OpenShift API server url, e.g `https://api.cluster.hostname.com:6443` | ✅ | |
| `OCP_API_SERVER_TOKEN`      | The authorization bearer token to use when sending request to OpenShift | ✅ | |

To obtain an OpenShift API token, create a Service Account, assign permissions to it, and request a token:

```bash
oc create sa orchestrator-ocp-api
oc adm policy add-cluster-role-to-user admin -z orchestrator-ocp-api

# Get the token for use in the next section
export OCP_API_SERVER_TOKEN=$(oc create token orchestrator-ocp-api)
```

### Add the Environment Variables to a Secret

The Helm Chart installation creates a `create-ocp-project-creds` Secret in the
namespace where it's installed. You'll update this Secret with your environment
variable values.

> [!NOTE]
> Updating the Secret does not automatically restart the workflow Pod, nor update the associated Sonataflow CR. If you update the keys in the secret you must update the Sonataflow CR - as shown below - to reference them. If you update the values in the Secret you must delete the existing `create-ocp-project` workflow Pod to create a new Pod that uses the new values.

> [!WARNING]
> If you run the `helm upgrade` command, the values of the Secret are reset.

Run the following command to update the Secret. Replace the example values with
the correct values for your environment:

```bash
export TARGET_NS='sonataflow-infra'
export WORKFLOW_NAME='create-ocp-project'

export NOTIFICATIONS_BEARER_TOKEN='token_from_backstage_appconfig'
export BACKSTAGE_NOTIFICATIONS_URL='https://backstage.replace-me.com'

export JIRA_API_TOKEN='token_for_jira_api'
export JIRA_URL='https://replace-me.atlassian.net/'
export JIRA_USERNAME='foo@bar.com'

export OCP_API_SERVER_URL='https://api.cluster.replace-me.com:6443'
export OCP_API_SERVER_TOKEN=$(oc create token orchestrator-ocp-api)
export OCP_CONSOLE_URL='replaceme'
```

If you've installed RHDH using the Orchestrator Operator you can obtain the
`NOTIFICATIONS_BEARER_TOKEN` using the following command:

```bash
export NOTIFICATIONS_BEARER_TOKEN=$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}' | base64 -d)
```

Now, patch the Secret with these values:

```bash
oc -n $TARGET_NS patch secret "$WORKFLOW_NAME-creds" \
  --type merge -p "{ \
    \"stringData\": { \
      \"NOTIFICATIONS_BEARER_TOKEN\": \"$NOTIFICATIONS_BEARER_TOKEN\",
      \"JIRA_API_TOKEN\": \"$JIRA_API_TOKEN\",
      \"OCP_API_SERVER_TOKEN\": \"$OCP_API_SERVER_TOKEN\",
      \"BACKSTAGE_NOTIFICATIONS_URL\": \"$BACKSTAGE_NOTIFICATIONS_URL\",
      \"JIRA_URL\": \"$JIRA_URL\",
      \"JIRA_USERNAME\": \"$JIRA_USERNAME\",
      \"OCP_API_SERVER_URL\": \"$OCP_API_SERVER_URL\",
      \"OCP_CONSOLE_URL\": \"$OCP_CONSOLE_URL\"
    }
  }"
```

### Update the Sonataflow CR to use Environment Variables

Once the Secret is updated, the Sonataflow CR for the workflow must be updated
to use the values. Use the following patch command to update the CR. This will
restart the Pod:

```bash
export TARGET_NS='sonataflow-infra'
export WORKFLOW_NAME='create-ocp-project'

oc -n $TARGET_NS patch sonataflow $WORKFLOW_NAME --type merge -p '{
  "spec": {
    "podTemplate": {
      "container": {
        "env": [
          {
            "name": "BACKSTAGE_NOTIFICATIONS_URL",
            "valueFrom": {
              "secretKeyRef": {
                "name": "create-ocp-project-creds",
                "key": "BACKSTAGE_NOTIFICATIONS_URL"
              }
            }
          },
          {
            "name": "NOTIFICATIONS_BEARER_TOKEN",
            "valueFrom": {
              "secretKeyRef": {
                "name": "create-ocp-project-creds",
                "key": "NOTIFICATIONS_BEARER_TOKEN"
              }
            }
          },
          {
            "name": "JIRA_URL",
            "valueFrom": {
              "secretKeyRef": {
                "name": "create-ocp-project-creds",
                "key": "JIRA_URL"
              }
            }
          },
          {
            "name": "JIRA_USERNAME",
            "valueFrom": {
              "secretKeyRef": {
                "name": "create-ocp-project-creds",
                "key": "JIRA_USERNAME"
              }
            }
          },
          {
            "name": "JIRA_API_TOKEN",
            "valueFrom": {
              "secretKeyRef": {
                "name": "create-ocp-project-creds",
                "key": "JIRA_API_TOKEN"
              }
            }
          },
          {
            "name": "OCP_API_SERVER_URL",
            "valueFrom": {
              "secretKeyRef": {
                "name": "create-ocp-project-creds",
                "key": "OCP_API_SERVER_URL"
              }
            }
          },
          {
            "name": "OCP_CONSOLE_URL",
            "valueFrom": {
              "secretKeyRef": {
                "name": "create-ocp-project-creds",
                "key": "OCP_CONSOLE_URL"
              }
            }
          }
        ]
      }
    }
  }
}'
```
