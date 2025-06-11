Setup ServiceNow Instance with a self-guided manual approach. 

## Prerequisite
* An available ServiceNow instance with admin credentials. 
* The script has been developed against ServiceNow Washington DC version of the instance.

## Set General ServiceNow Data and URL Environment Variables
* In a shell terminal set the following environment variables.
```shell
export SN_SERVER='https://<your instance>.service-now.com'
export AUTH_HEADER="Authorization: Basic <your auth value>"
export DEFAULT_PWD='<your default password>'
export CONTENT_TYPE='Content-Type: application/json'

#   DOUBLE CHECK FOLLOWING VALUES WITH YOUR OWN INSTANCE
export ADMIN_ROLE_SYS_ID="\"2831a114c611228501d4ea6c309d626d\""
export APPROVER_USER_ROLE_SYS_ID="\"debab85bff02110053ccffffffffffb6\""

#   SERVICE NOW URLs
export SN_USER_URL="${SN_SERVER}/api/now/table/sys_user?sysparm_input_display_value=true&sysparm_display_value=true"
export SN_ASSIGN_USER_ROLE_URL="${SN_SERVER}/api/now/table/sys_user_has_role"
export SN_CREATE_GROUP_URL="${SN_SERVER}/api/now/table/sys_user_group"
export SN_ASSIGN_GROUP_ROLE_URL="${SN_SERVER}/api/now/table/sys_group_has_role"
export SN_ASSIGN_USR_TO_GRP_URL="${SN_SERVER}/api/now/table/sys_user_grmember"
export SN_CHANGE_REQUEST_URL="${SN_SERVER}/api/now/table/change_request"
```

## Setup ServiceNow Instance

###   CREATE REQUESTER USER
```shell
export CREATE_REQ_USER_PAYLOAD="{ \
    \"user_name\": \"requester\", \
    \"first_name\": \"requester\", \
    \"last_name\": \"user\", \
    \"email\": \"requester@example.com\", \
    \"user_password\": \"${DEFAULT_PWD}\", \
    \"password_needs_reset\": \"false\", \
    \"active\": \"true\", \
    \"locked_out\": \"false\", \
    \"web_service_access_only\": \"false\", \
    \"internal_integration_user\": \"false\", \
    \"roles\": \"admin\" \
}"

export NEW_REQ_USER_SYS_ID=$(curl -s \
--location ${SN_USER_URL} \
--header ${CONTENT_TYPE} \
--header ${AUTH_HEADER} \
--data-raw ${CREATE_REQ_USER_PAYLOAD} | jq '.result.sys_id')

echo "*** REQUESTER USER Sys Id: ${NEW_REQ_USER_SYS_ID}"
```

###   ASSIGN REQUESTER USER WITH ADMIN ROLE
```shell
export ASSIGN_USER_ROLE_PAYLOAD="{
    \"role\": ${ADMIN_ROLE_SYS_ID}, \
    \"user\": ${NEW_REQ_USER_SYS_ID} \
}"

export NEW_USER_ROLE_ASSOC_SYS_ID=$(curl -s \
--location ${SN_ASSIGN_USER_ROLE_URL} \
--header ${CONTENT_TYPE} \
--header ${AUTH_HEADER} \
--data-raw ${ASSIGN_USER_ROLE_PAYLOAD} | jq '.result.sys_id')

echo "*** REQUESTER USER associated to Admin role with Sys Id: ${NEW_USER_ROLE_ASSOC_SYS_ID}"
```

###   CREATE APPROVER USER
```shell
export CREATE_APPRV_USER_PAYLOAD="{ \
    \"user_name\": \"manager\", \
    \"first_name\": \"manager\", \
    \"last_name\": \"user\", \
    \"email\": \"manager@example.com\", \
    \"user_password\": \"${DEFAULT_PWD}\", \
    \"password_needs_reset\": \"false\", \
    \"active\": \"true\", \
    \"locked_out\": \"false\", \
    \"web_service_access_only\": \"false\", \
    \"internal_integration_user\": \"false\", \
    \"roles\": \"admin\" \
}"

export NEW_APPRV_USER_SYS_ID=$(curl -s \
--location ${SN_USER_URL} \
--header ${CONTENT_TYPE} \
--header ${AUTH_HEADER} \
--data-raw ${CREATE_APPRV_USER_PAYLOAD} | jq '.result.sys_id')

echo "*** APPROVER USER Sys Id: ${NEW_APPRV_USER_SYS_ID}"
```

###   CREATE APPROVER GROUP
```shell
export CREATE_GROUP_PAYLOAD="{
    \"name\": \"Approvers\",
    \"exclude_manager\": \"false\",
    \"manager\": ${NEW_APPRV_USER_SYS_ID},
    \"email\": \"chgapprovers@example.com\",
    \"include_members\": \"false\",
    \"roles\": \"itil,approver_user\"
}"

export NEW_APPRV_GRP_SYS_ID=$(curl -s \
--location ${SN_CREATE_GROUP_URL} \
--header ${CONTENT_TYPE} \
--header ${AUTH_HEADER} \
--data-raw ${CREATE_GROUP_PAYLOAD} | jq '.result.sys_id')

echo "*** APPROVER GROUP Sys Id: ${NEW_APPRV_GRP_SYS_ID}"
```

###   ADD approver_user ROLE TO APPROVER GROUP
```shell
export ASSIGN_GRP_ROLE_PAYLOAD="{
    \"role\": ${APPROVER_USER_ROLE_SYS_ID}, \
    \"group\": ${NEW_APPRV_GRP_SYS_ID} \
}"

export NEW_GRP_ROLE_ASSOC_SYS_ID=$(curl -s \
--location ${SN_ASSIGN_GROUP_ROLE_URL} \
--header ${CONTENT_TYPE} \
--header ${AUTH_HEADER} \
--data-raw ${ASSIGN_GRP_ROLE_PAYLOAD} | jq '.result.sys_id')

echo "*** Associate approver_user role to approver user Sys Id: ${NEW_GRP_ROLE_ASSOC_SYS_ID}"
```

###   ASSOCIATE APPROVER USER AND APPROVER GROUP
```shell
export ASSIGN_APPRV_USR_TO_APPRV_GRP_PAYLOAD="{
    \"user\": ${NEW_APPRV_USER_SYS_ID}, \
    \"group\": ${NEW_APPRV_GRP_SYS_ID} \
}"

export NEW_ASSIGN_GRP_TO_USR_SYS_ID=$(curl -s \
--location ${SN_ASSIGN_USR_TO_GRP_URL} \
--header ${CONTENT_TYPE} \
--header ${AUTH_HEADER} \
--data-raw ${ASSIGN_APPRV_USR_TO_APPRV_GRP_PAYLOAD} | jq '.result.sys_id')

echo "*** Assigned approver user to APPROVER GROUP with Sys Id: ${NEW_ASSIGN_GRP_TO_USR_SYS_ID}"
```

###   CREATE A CHANGE REQUEST
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

export NEW_CHG_REQ_SYS_ID=$(curl -s \
--location ${SN_CHANGE_REQUEST_URL} \
--header ${CONTENT_TYPE} \
--header ${AUTH_HEADER} \
--data-raw ${CREATE_CHG_REQ_PAYLOAD} | jq '.result.sys_id')

echo "*** New Change Request Sys Id: ${NEW_CHG_REQ_SYS_ID}"
```

###   TRIGGER THE CHANGE REQUEST FOR APPROVAL
```shell
export TEMP=`echo ${NEW_CHG_REQ_SYS_ID} |  tr -d "\""`
export TRIGGER_CHG_REQ_URL=${SN_CHANGE_REQUEST_URL}/${TEMP}

export TRIGGER_CHG_REQ_PAYLOAD="{
    \"state\": \"-4\",
    \"approval\": \"requested\"
}"

export TRIGGER_CHG_REQ_SYS_ID=$(curl -s -X PUT \
--location ${TRIGGER_CHG_REQ_URL} \
--header ${CONTENT_TYPE} \
--header ${AUTH_HEADER} \
--data-raw ${TRIGGER_CHG_REQ_PAYLOAD} | jq '.result.sys_id')
echo "*** Triggered change request with Sys Id: ${TRIGGER_CHG_REQ_SYS_ID}"
```

### Verify the script execution results on ServiceNow instance
Login to the ServiceNow instance and verify the `requester` user, `approver` user, `approver` group and a `change request` are created.

## Cleaning up

### SETUP ENVIRONMENT VARIABLES
```shell
export SN_SERVER='https://<your instance>.service-now.com'
export AUTH_HEADER="Authorization: Basic <your auth value>"
export ACCEPT='Accept: application/json'
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
export DELETE_SYS_ID=`echo ${NEW_ASSIGN_GRP_TO_USR_SYS_ID} |  tr -d "\""`
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

### DELETE REQUESTER USER
```shell
export DELETE_SYS_ID=`echo ${NEW_REQ_USER_SYS_ID} |  tr -d "\""`
curl "${SN_SERVER}/api/now/table/sys_user/${DELETE_SYS_ID}" \
--request DELETE \
--header ${ACCEPT} \
--header ${AUTH_HEADER} 
```