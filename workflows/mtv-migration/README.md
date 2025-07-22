# MTV migration workflow - MTV Migration execution workflow
This workflow creates an MTV Plan and an MTV Migration. It waits for the final condition of each resource. Final condition is either success or failure. It is important to note that we rely on MTV to reach a final state. We do not impose our own timeout.
[MTV Migration Plan documentation](https://docs.redhat.com/en/documentation/migration_toolkit_for_virtualization/2.6/html/installing_and_using_the_migration_toolkit_for_virtualization/migrating-vms-web-console_mtv#creating-migration-plans-ui)  
It is possible to execute just one of the stages: Plan or Migrate. The input variable `operation` determines whether to perform just one of the stages or perform both (sequentially).

## Prerequisite
* Access to an OCP cluster with MTV operator (Openshift Migration Toolkit for Virtualization) installed. The cluster credentials must allow creating the resources listed above.

## Workflow diagram
![MTV Migration workflow diagram](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/mtv-migration/mtv.svg?raw=true)

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `BACKSTAGE_NOTIFICATIONS_URL`      | The backstage server URL for notifications | ✅ | |
| `NOTIFICATIONS_BEARER_TOKEN`      | The authorization bearer token to use to send notifications | ✅ | |
| `OCP_API_SERVER_URL`  | The OpensShift API Server URL | ✅ | |
| `OCP_API_SERVER_TOKEN`| The OpensShift API Server Token | ✅ | |

## Installation

See [official installation guide](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/deploy/docs/main/mtv-migration)

## How to run
Example of POST to trigger Plan and Migrate (see input schema [mtv-input.json](./schema/mtv-input.json)):
```bash
curl -X POST -H "Content-Type: application/json" http://localhost:8080/mtv-plan -d '{
    "migrationName": "my-vms",
    "migrationNamespace": "openshift-mtv",
    "operation": "PLAN_AND_MIGRATE",
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
Example of POST to trigger just Migrate (see input schema [mtv-input.json](./schema/mtv-input.json)):
```bash
curl -X POST -H "Content-Type: application/json" http://localhost:8080/mtv-migration -d '{
    "migrationName": "my-vms",
    "migrationNamespace": "openshift-mtv",
    "operation": "MIGRATE"
}'
```
Example of POST to trigger just Plan (see input schema [mtv-input.json](./schema/mtv-input.json)):
```bash
curl -X POST -H "Content-Type: application/json" http://localhost:8080/mtv-plan -d '{
    "migrationName": "my-vms",
    "migrationNamespace": "openshift-mtv",
    "operation": "PLAN",
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