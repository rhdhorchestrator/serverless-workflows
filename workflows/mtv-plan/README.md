> **🚨 Deprecation Notice: 🚨**  
> From Orchestrator release version 1.7, Workflow Types will be retired. All workflows will act as infrastructure workflows, and no workflow will act as an assesment workflow. <br>
> This workflow, being an assessment workflow, will be obsolete and irrelevant. 

# MTV assessment - MTV Plan assessment workflow
This workflow is an assessment workflow type, that creates an MTV Plan resource and waits for its final condition. Final condition is either success or failure. It is important to note that we rely on MTV to reach a final state. We do not impose our own timeout.
[MTV Migration Plan documentation](https://docs.redhat.com/en/documentation/migration_toolkit_for_virtualization/2.6/html/installing_and_using_the_migration_toolkit_for_virtualization/migrating-vms-web-console_mtv#creating-migration-plans-ui)

## Prerequisite
* Access to an OCP cluster with MTV operator (Openshift Migration Toolkit for Virtualization) installed. The cluster credentials must allow creating the resources listed above.

## Workflow diagram
![MTV Plan workflow diagram](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/mtv-plan/mtv.svg?raw=true)

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `BACKSTAGE_NOTIFICATIONS_URL`      | The backstage server URL for notifications | ✅ | |
| `NOTIFICATIONS_BEARER_TOKEN`      | The authorization bearer token to use to send notifications | ✅ | |
| `OCP_API_SERVER_URL`  | The OpensShift API Server URL | ✅ | |
| `OCP_API_SERVER_TOKEN`| The OpensShift API Server Token | ✅ | |

## Installation

See [official installation guide](https://github.com/rhdhorchestrator/serverless-workflows-config/blob/main/docs/main/mtv-plan)


## How to run
Example of POST to trigger the flow (see input schema [mtv-input.json](./schema/mtv-input.json)):
```bash
curl -X POST -H "Content-Type: application/json" http://localhost:8080/mtv-plan -d '{
    "migrationName": "my-vms",
    "migrationNamespace": "openshift-mtv",
    "sourceProvider": "vmware",
    "destinationProvider": "host",
    "storageMap": "vmware-z976z",
    "networkMap": "vmware-zqpl7",
    "vms": [
        {
            "name": "haproxy",
            "id": "vm-5932"
        }
    ]
}'
```
