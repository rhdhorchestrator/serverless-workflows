An escalation workflow integrated with ServiceNow using [SonataFlow](https://sonataflow.org/serverlessworkflow/latest/index.html).

## Workflow diagram
![Escalation with serviceNow workflow diagram](https://github.com/rhdhorchestrator/serverless-workflow-examples/blob/main/escalation-service-now/serviceNowEscalation.svg?raw=true)

## Prerequisite
* An available ServiceNow instance with admin credentials.
* Prerequisite data being available on ServiceNow instance with setup instructions [found here](instance-setup/readme.md)
* Janus-idp notifications service is deployed and functionally running with instructions [found here](https://github.com/janus-idp/backstage-plugins/tree/main/plugins/notifications-backend).

### Specifics about Notifications service
* Add the `manager` user in `notifications-backend/users.yaml` and your file could look something like this
```yaml
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: guest
spec:
  profile:
    displayName: Guest User
  memberOf: []
---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: manager
spec:
  profile:
    displayName: Manager Approver User
  memberOf: []
```
* Restart the notifications service
```shell
yarn start:backstage
```

* Be sure the create notification call from the command line works successfully.
```shell
curl -X POST http://localhost:7007/api/notifications/notifications -H "Content-Type: application/json" -d '{"title": "My message title", "message": "I have nothing to say", "origin": "my-origin", "targetUsers": ["default/manager"]}' | jq '.'
```

* An example response could look like this
```yaml
{
    "messageId": "942b0aa0-79d4-46a7-a973-47573fa19543"
}
```

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory |
|-----------------------|-------------|-----------|
| `SN_SERVER`            | The ServiceNow server URL | ✅ |
| `SERVICENOW_USERNAME`       | The ServiceNow server username | ✅ |
| `SERVICENOW_PASSWORD`      | The ServiceNow server password | ✅ |

## How to run

### Start the workflow application
```bash
mvn clean quarkus:dev
```

### Trigger/start the workflow
* Example of POST to trigger the flow (see input schema in [servicenow-escalation-schema.json](./src/main/resources/servicenow-escalation-schema.json)):
```bash
# This is a request sent to the workflow instance
CREATE_CR_RESP=$(curl -XPOST -H "Content-Type: application/json" http://localhost:8080/servicenow-escalation -d '{
    "description": "<ServiceNow change request description>",
    "short_description": "<ServiceNow change request short_description>",
    "comments": "<ServiceNow change request comments>",
    "state": "new",
    "assigned_to": "<ServiceNow Approver user sys_id> e.g. 950597b6973002102425b39fe153af41",
    "additional_assignee_list": "<ServiceNow Approver user sys_id> e.g. 950597b6973002102425b39fe153af41",
    "assignment_group": "<ServiceNow Approver group sys_id> e.g. e50597b6973002102425b39fe153afb2",
    "sn_url": "https://<ServiceNow URL>"
}');
echo $CREATE_CR_RESP |  jq '.';
```
* You should see a response similar to the following, which provides newly create change request information.
```json
{
  "id": "99203918-3e8c-46a6-ba43-9a025172f8c2",
  "workflowdata": {
    "description": "Requester requesting an item",
    "short_description": "Requester requesting an item in short",
    "comments": "Requester requesting an item in comments",
    "state": "new",
    "assigned_to": "950597b6973002102425b39fe153af41",
    "additional_assignee_list": "950597b6973002102425b39fe153af41",
    "assignment_group": "e50597b6973002102425b39fe153afb2",
    "createdChangeRequest": {
      "result": {
        "sys_id": "6dfa4ff7973002102425b39fe153afed",
        "state": "-5",
        "number": "CHG0030045"
      }
    }
  }
}
```

* From the response above extract the sys_id of the newly created change request.
```shell
CREATED_CR_SYS_ID=$( jq -r  '.workflowdata.createdChangeRequest.result.sys_id' <<< "${CREATE_CR_RESP}" );
echo "${CREATED_CR_SYS_ID}";
```

* Trigger the newly created change request for approval by changing its state to `assessment` state.
```shell
TRIGGER_CR_CMD="curl --location --request PUT 'https://dev143716.service-now.com/api/now/table/change_request/${CREATED_CR_SYS_ID}' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic <your auth header value>' \
--data '{
    \"state\": \"-4\",
    \"approval\": \"requested\"
}'";

eval $TRIGGER_CR_CMD | jq '.';
```

* Wait for a minute or two before proceeding to the next step, to view notifications created by the workflow, to remind the approver to approve the created change request.
    * In the current implementation this reminder is generated every `30s` by the workflow.

* After this wait, login to notifications service's postgres database console.

* You will see `reminder` notification(s) created by `Notifications service` as shown in the following example.
```text
                  id                  |                               message
--------------------------------------+---------------------------------------------------------------------
 8a3c945d-9009-4188-a28e-17ceee853a99 | Manager, please approve the change request: CHG0030045
```

### End the workflow by approving the change request

* Login to the ServiceNow instance UI with `manager` user and credentials.
* Click All -> My Approvals menu item, in the resulting list, click the change request that was created.
* In the change request detail screen, set the `State` to `Approved` and click `Update`.
* As the change request is approved, you will see a `thank you` notification created by `Notifications service` as shown in the following example.
Note: this may appear after a few seconds, as the workflow needs to wait for completion of the timeout event of `30s`, before this notification is created.
```text
                  id                  |                               message
--------------------------------------+---------------------------------------------------------------------
 3e9cd0a6-c4c8-4ea1-973a-dbb063279397 | Manager, thanks a ton for approving the change request: CHG0030045
```

Tips:
* Visit [Workflow Instances](http://localhost:8080/q/dev/org.kie.kogito.kogito-quarkus-serverless-workflow-devui/workflowInstances)
* Visit (Data Index Query Service)[http://localhost:8080/q/graphql-ui/]