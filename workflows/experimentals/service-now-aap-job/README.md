# service-now-aap-job
This workflow creates a task in the provided Service Now instance. Once approved, it then launches an Ansible Automation Platform (AAP) job.
Notifications are sent to notify:
* for success or failure upon completion
* for any change of state of the AAP Job
* for task approval/completion

The following inputs are required:
- for AAP Job
    - Job template Id
    - Inventory group
- for Service Now
    - description of the task
    - short description of the task
    - assignee
    - assignment group

## Workflow diagram
![service-now-aap-job workflow diagram](https://github.com/rhdhorchestrator/serverless-workflows/blob/feat/service-now-aap-job/service-now-aap-job/service-now-aap-job.svg?raw=true)

## Prerequisites
* A running instance of AAP with admin credentials.
* A running instance of Backstage with notification plugin configured
* An available ServiceNow instance with admin credentials.

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory |
|-----------------------|-------------|-----------|
| `AAP_URL`       | The AAP server URL | ✅ |
| `AAP_USERNAME`      | The AAP server password | ✅ |
| `AAP_PASSWORD`      | The AAP server password | ✅ |
| `SN_SERVER`      | The Service Now API URL | ✅ |
| `SERVICENOW_USERNAME`      | The Service Now username | ✅ |
| `SERVICENOW_PASSWORD`      | The Service Now password | ✅ |


## Installation
### Service Now instance setup
* In a shell terminal set the following environment variables.
```shell
export SN_SERVER='https://dev222031.service-now.com'
export AUTH_HEADER="Authorization: Basic XXXXX"
export DEFAULT_PWD='DEFAULT_PWD'
export CONTENT_TYPE='Content-Type: application/json'


#   DOUBLE CHECK FOLLOWING VALUES WITH YOUR OWN INSTANCE
# Go to ${SN_SERVER}/api/now/table/sys_user_role and ctrl+F approver_user
export APPROVER_USER_ROLE_SYS_ID="\"debab85bff02110053ccffffffffffb6\""

#   SERVICE NOW URLs
export SN_USER_URL="${SN_SERVER}/api/now/table/sys_user?sysparm_input_display_value=true&sysparm_display_value=true"
export SN_ASSIGN_USER_ROLE_URL="${SN_SERVER}/api/now/table/sys_user_has_role"
export SN_CREATE_GROUP_URL="${SN_SERVER}/api/now/table/sys_user_group"
export SN_ASSIGN_GROUP_ROLE_URL="${SN_SERVER}/api/now/table/sys_group_has_role"
export SN_ASSIGN_USR_TO_GRP_URL="${SN_SERVER}/api/now/table/sys_user_grmember"
export SN_CHANGE_REQUEST_URL="${SN_SERVER}/api/now/table/change_request"

export SN_APPROVER_USER="manager"
export SN_APPROVER_GROUP="Approvers"
```

### Setup ServiceNow Instance

#### Configure Approver user

We will need an user capable of approving change requests created (mainly for demo puposes).
First creating the user:
```shell
export CREATE_APPRV_USER_PAYLOAD="{ \
    \"user_name\": \"${SN_APPROVER_USER}\", \
    \"first_name\": \"${SN_APPROVER_USER}\", \
    \"last_name\": \"user\", \
    \"email\": \"${SN_APPROVER_USER}@example.com\", \
    \"user_password\": \"${DEFAULT_PWD}\", \
    \"password_needs_reset\": \"false\", \
    \"active\": \"true\", \
    \"locked_out\": \"false\", \
    \"web_service_access_only\": \"false\", \
    \"internal_integration_user\": \"false\"
}"

export NEW_APPRV_USER_SYS_ID=$(curl -v \
--location "${SN_USER_URL}" \
--header "${CONTENT_TYPE}" \
--header "${AUTH_HEADER}" \
--data-raw "${CREATE_APPRV_USER_PAYLOAD}" | jq '.result.sys_id')

echo "*** APPROVER USER ${SN_APPROVER_USER} Sys Id: ${NEW_APPRV_USER_SYS_ID}"
```

Now we will create a new group that will later be associated with the approver user:
```shell
export CREATE_GROUP_PAYLOAD="{
    \"name\": \"${SN_APPROVER_GROUP}\",
    \"exclude_manager\": \"false\",
    \"manager\": ${NEW_APPRV_USER_SYS_ID},
    \"email\": \"chgapprovers@example.com\",
    \"include_members\": \"false\",
    \"roles\": \"itil,approver_user\"
}"

export NEW_APPRV_GRP_SYS_ID=$(curl -s \
--location "${SN_CREATE_GROUP_URL}" \
--header "${CONTENT_TYPE}" \
--header "${AUTH_HEADER}" \
--data-raw "${CREATE_GROUP_PAYLOAD}" | jq '.result.sys_id')

echo "*** APPROVER GROUP ${SN_APPROVER_GROUP} Sys Id: ${NEW_APPRV_GRP_SYS_ID}"
```

The created group needs to have the approver role added to it:

```shell
export ASSIGN_GRP_ROLE_PAYLOAD="{
    \"role\": ${APPROVER_USER_ROLE_SYS_ID}, \
    \"group\": ${NEW_APPRV_GRP_SYS_ID} \
}"

export NEW_GRP_ROLE_ASSOC_SYS_ID=$(curl -s \
--location "${SN_ASSIGN_GROUP_ROLE_URL}" \
--header "${CONTENT_TYPE}" \
--header "${AUTH_HEADER}" \
--data-raw "${ASSIGN_GRP_ROLE_PAYLOAD}" | jq '.result.sys_id')

echo "*** Associated approver_user role to approver group ${SN_APPROVER_GROUP} Sys Id: ${NEW_GRP_ROLE_ASSOC_SYS_ID}"
```

And finally, add the approver user to the group:
```shell
export ASSIGN_APPRV_USR_TO_APPRV_GRP_PAYLOAD="{
    \"user\": ${NEW_APPRV_USER_SYS_ID}, \
    \"group\": ${NEW_APPRV_GRP_SYS_ID} \
}"

export NEW_ASSIGN_GRP_TO_USR_SYS_ID=$(curl -s \
--location "${SN_ASSIGN_USR_TO_GRP_URL}" \
--header "${CONTENT_TYPE}" \
--header "${AUTH_HEADER}" \
--data-raw "${ASSIGN_APPRV_USR_TO_APPRV_GRP_PAYLOAD}" | jq '.result.sys_id')

echo "*** Assigned approver user ${SN_APPROVER_USER} to APPROVER GROUP ${SN_APPROVER_GROUP} with Sys Id: ${NEW_ASSIGN_GRP_TO_USR_SYS_ID}"
```

### Validating / testing
Let's create a change request using the requester user previsouly created:
```shell
export CREATE_CHG_REQ_PAYLOAD="{
    \"description\": \"REQUESTER requesting an item\",
    \"short_description\": \"REQUESTER requesting an item in short\",
    \"comments\": \"REQUESTER requesting an item in comments\",
    \"state\": \"new\",
    \"assigned_to\": ${NEW_APPRV_USER_SYS_ID},
    \"additional_assignee_list\": ${NEW_APPRV_USER_SYS_ID},
    \"assignment_group\": ${NEW_APPRV_GRP_SYS_ID}
}"

export NEW_CHG_REQ=$(curl -s \
--location "${SN_CHANGE_REQUEST_URL}" \
--header "${CONTENT_TYPE}" \
--header "${AUTH_HEADER}" \
--data-raw "${CREATE_CHG_REQ_PAYLOAD}")
export NEW_CHG_REQ_SYS_ID=$(echo "${NEW_CHG_REQ}" | jq '.result.sys_id')
export NEW_CHG_REQ_NUMBER=$(echo "${NEW_CHG_REQ}" | jq '.result.number')
echo "*** New Change Request ${NEW_CHG_REQ_NUMBER} Sys Id: ${NEW_CHG_REQ_SYS_ID}"
```

Let's request an approval for it:
```shell
export TEMP=`echo ${NEW_CHG_REQ_SYS_ID} |  tr -d "\""`
export TRIGGER_CHG_REQ_URL=${SN_CHANGE_REQUEST_URL}/${TEMP}

export TRIGGER_CHG_REQ_PAYLOAD="{
    \"state\": \"-4\",
    \"approval\": \"requested\"
}"

export TRIGGER_CHG_REQ_SYS_ID=$(curl -s -X PUT \
--location "${TRIGGER_CHG_REQ_URL}" \
--header "${CONTENT_TYPE}" \
--header "${AUTH_HEADER}" \
--data-raw "${TRIGGER_CHG_REQ_PAYLOAD}" | jq '.result.sys_id')
echo "*** Triggered change request with Sys Id: ${TRIGGER_CHG_REQ_SYS_ID}"
```

Now, login to the ServiceNow instance and verify approver user has a notification requesting its approval of a change request.

To see all changes requests: ${SN_SERVER}/now/sow/list/params/list-id/

## Cleaning up
```shell
NEW_CHG_REQ_SYS_ID=<sys id of the create change request>
NEW_GRP_ROLE_ASSOC_SYS_ID=<sys id of the group - role table>
NEW_APPRV_GRP_SYS_ID=<sys id of the approver group>
NEW_APPRV_USER_SYS_ID=<sys id of the approver user>
```
### DELETE CHANGE REQUEST
```shell
export DELETE_SYS_ID=`echo ${NEW_CHG_REQ_SYS_ID} |  tr -d "\""`

curl "${SN_SERVER}/api/now/table/change_request/${DELETE_SYS_ID}" \
--request DELETE \
--header ${ACCEPT} \
--header ${AUTH_HEADER}
```

### DELETE approver_user ROLE TO APPROVER GROUP
```shell
export DELETE_SYS_ID=`echo ${NEW_GRP_ROLE_ASSOC_SYS_ID} |  tr -d "\""`
curl "${SN_SERVER}/api/now/table/sys_group_has_role/${DELETE_SYS_ID}" \
--request DELETE \
--header ${ACCEPT} \
--header ${AUTH_HEADER}
```

### DELETE APPROVER USER ASSOCIATION WITH APPROVER GROUP
```shell
export DELETE_SYS_ID=`echo ${NEW_GRP_ROLE_ASSOC_SYS_ID} |  tr -d "\""`
curl "${SN_SERVER}/api/now/table/sys_user_grmember/${DELETE_SYS_ID}" \
--request DELETE \
--header ${ACCEPT} \
--header ${AUTH_HEADER}
```

### DELETE APPROVER GROUP
```shell
export DELETE_SYS_ID=`echo ${NEW_APPRV_GRP_SYS_ID} |  tr -d "\""`
curl "${SN_SERVER}/api/now/table/sys_user_group/${DELETE_SYS_ID}" \
--request DELETE \
--header ${ACCEPT} \
--header ${AUTH_HEADER}
```

### DELETE APPROVER USER
```shell
export DELETE_SYS_ID=`echo ${NEW_APPRV_USER_SYS_ID} |  tr -d "\""`
curl "${SN_SERVER}/api/now/table/sys_user/${DELETE_SYS_ID}" \
--request DELETE \
--header ${ACCEPT} \
--header ${AUTH_HEADER}
```