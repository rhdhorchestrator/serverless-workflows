# Ansible automation platform job workflow
This workflow launches an Ansible Automation Platform (AAP) job and send out a notification for success or failure upon completion.
The following two (2) inputs are required:
- Job template Id
- Inventory group

## Workflow diagram
![AAP job workflow diagram](https://github.com/rhdhorchestrator/serverless-workflow-examples/blob/main/aap-job/aap-job.svg?raw=true)

## Prerequisites
* A running instance of AAP with admin credentials.
* A running instance of Backstage notification plugin.

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory |
|-----------------------|-------------|-----------|
| `AAP_URL`       | The AAP server URL - protocol and hostname. E.g. https://myhost.org | ✅ |
| `AAP_USERNAME`      | The AAP server password | ✅ |
| `AAP_PASSWORD`      | The AAP server password | ✅ |

## How to run

```bash
mvn clean quarkus:dev
```

Example of POST to trigger the workflow:
```bash
curl -XPOST -H "Content-Type: application/json" http://localhost:8080/aap-job -d '{"jobTemplateId": _JOB_TEMPLATE_ID_, "inventoryGroup": "_INVENTORY_GROUP_", "limit": "_LIMIT_"}'
```

Response:
```
{
    "id": "832685aa-0df0-4cf9-9e91-820b013efda6",
    "workflowdata": {
        "jobTemplateId": _JOB_TEMPLATE_ID_,
        "inventoryGroup": "_INVENTORY_GROUP_",
        "limit": "_LIMIT_",
        "launchedJob": {
            "id": 29,
            "failed": false,
            "status": "pending",
            "outputUrl": "https://your-app-platform.io/#/jobs/playbook/29/output"
        }
    }
}
```

