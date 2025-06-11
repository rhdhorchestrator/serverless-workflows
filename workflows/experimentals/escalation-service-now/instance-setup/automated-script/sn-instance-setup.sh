#!/bin/bash

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

#   CREATE REQUESTER USER
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

export NEW_REQ_USER_SYS_ID=`curl -s \
--variable %SN_USER_URL \
--variable %CONTENT_TYPE \
--variable %AUTH_HEADER \
--variable %CREATE_REQ_USER_PAYLOAD \
--expand-url {{SN_USER_URL}} \
--expand-header {{CONTENT_TYPE}} \
--expand-header {{AUTH_HEADER}} \
--expand-data {{CREATE_REQ_USER_PAYLOAD}} | jq '.result.sys_id'`

echo "*** Requester User Sys Id: ${NEW_REQ_USER_SYS_ID}"

#   ASSIGN REQUESTER USER WITH ADMIN ROLE
export ASSIGN_USER_ROLE_PAYLOAD="{
    \"role\": ${ADMIN_ROLE_SYS_ID}, \
    \"user\": ${NEW_REQ_USER_SYS_ID} \
}"

export NEW_USER_ROLE_ASSOC_SYS_ID=`curl -s \
--variable %SN_ASSIGN_USER_ROLE_URL \
--variable %CONTENT_TYPE \
--variable %AUTH_HEADER \
--variable %ASSIGN_USER_ROLE_PAYLOAD \
--expand-url {{SN_ASSIGN_USER_ROLE_URL}} \
--expand-header {{CONTENT_TYPE}} \
--expand-header {{AUTH_HEADER}} \
--expand-data {{ASSIGN_USER_ROLE_PAYLOAD}} | jq '.result.sys_id'`

echo "*** Requester User associated to Admin role with Sys Id: ${NEW_USER_ROLE_ASSOC_SYS_ID}"

#   CREATE APPROVER USER
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
--variable %SN_USER_URL \
--variable %CONTENT_TYPE \
--variable %AUTH_HEADER \
--variable %CREATE_APPRV_USER_PAYLOAD \
--expand-url {{SN_USER_URL}} \
--expand-header {{CONTENT_TYPE}} \
--expand-header {{AUTH_HEADER}} \
--expand-data {{CREATE_APPRV_USER_PAYLOAD}} | jq '.result.sys_id')

echo "*** Approver User Sys Id: ${NEW_APPRV_USER_SYS_ID}"

#   CREATE APPROVER GROUP
export CREATE_GROUP_PAYLOAD="{
    \"name\": \"Approvers\",
    \"exclude_manager\": \"false\",
    \"manager\": ${NEW_APPRV_USER_SYS_ID},
    \"email\": \"chgapprovers@example.com\",
    \"include_members\": \"false\",
    \"roles\": \"itil,approver_user\"
}"

export NEW_APPRV_GRP_SYS_ID=$(curl -s \
--variable %SN_CREATE_GROUP_URL \
--variable %CONTENT_TYPE \
--variable %AUTH_HEADER \
--variable %CREATE_GROUP_PAYLOAD \
--expand-url {{SN_CREATE_GROUP_URL}} \
--expand-header {{CONTENT_TYPE}} \
--expand-header {{AUTH_HEADER}} \
--expand-data {{CREATE_GROUP_PAYLOAD}} | jq '.result.sys_id')

echo "*** Approver Group Sys Id: ${NEW_APPRV_GRP_SYS_ID}"

#   ADD approver_user ROLE TO APPROVER GROUP
export ASSIGN_GRP_ROLE_PAYLOAD="{
    \"role\": ${APPROVER_USER_ROLE_SYS_ID}, \
    \"group\": ${NEW_APPRV_GRP_SYS_ID} \
}"

export NEW_GRP_ROLE_ASSOC_SYS_ID=$(curl -s \
--variable %SN_ASSIGN_GROUP_ROLE_URL \
--variable %CONTENT_TYPE \
--variable %AUTH_HEADER \
--variable %ASSIGN_GRP_ROLE_PAYLOAD \
--expand-url {{SN_ASSIGN_GROUP_ROLE_URL}} \
--expand-header {{CONTENT_TYPE}} \
--expand-header {{AUTH_HEADER}} \
--expand-data {{ASSIGN_GRP_ROLE_PAYLOAD}} | jq '.result.sys_id')

echo "*** Associate approver_user role to approver user Sys Id: ${NEW_GRP_ROLE_ASSOC_SYS_ID}"

#   ASSOCIATE APPROVER USER AND APPROVER GROUP
export ASSIGN_APPRV_USR_TO_APPRV_GRP_PAYLOAD="{
    \"user\": ${NEW_APPRV_USER_SYS_ID}, \
    \"group\": ${NEW_APPRV_GRP_SYS_ID} \
}"

export NEW_ASSIGN_GRP_TO_USR_SYS_ID=$(curl -s \
--variable %SN_ASSIGN_USR_TO_GRP_URL \
--variable %CONTENT_TYPE \
--variable %AUTH_HEADER \
--variable %ASSIGN_APPRV_USR_TO_APPRV_GRP_PAYLOAD \
--expand-url {{SN_ASSIGN_USR_TO_GRP_URL}} \
--expand-header {{CONTENT_TYPE}} \
--expand-header {{AUTH_HEADER}} \
--expand-data {{ASSIGN_APPRV_USR_TO_APPRV_GRP_PAYLOAD}} | jq '.result.sys_id')

echo "*** Assigned approver user to approver group with Sys Id: ${NEW_ASSIGN_GRP_TO_USR_SYS_ID}"

#   CREATE A CHANGE REQUEST
export CREATE_CHG_REQ_PAYLOAD="{
    \"description\": \"Requester requesting an item\",
    \"short_description\": \"Requester requesting an item in short\",
    \"comments\": \"Requester requesting an item in comments\",
    \"state\": \"new\",
    \"assigned_to\": ${NEW_APPRV_USER_SYS_ID},
    \"additional_assignee_list\": ${NEW_APPRV_USER_SYS_ID},
    \"assignment_group\": ${NEW_APPRV_GRP_SYS_ID}
}"

export NEW_CHG_REQ_SYS_ID=$(curl -s \
--variable %SN_CHANGE_REQUEST_URL \
--variable %CONTENT_TYPE \
--variable %AUTH_HEADER \
--variable %CREATE_CHG_REQ_PAYLOAD \
--expand-url {{SN_CHANGE_REQUEST_URL}} \
--expand-header {{CONTENT_TYPE}} \
--expand-header {{AUTH_HEADER}} \
--expand-data {{CREATE_CHG_REQ_PAYLOAD}} | jq '.result.sys_id')

echo "*** New Change Request Sys Id: ${NEW_CHG_REQ_SYS_ID}"

#   TRIGGER THE CHANGE REQUEST FOR APPROVAL
export TEMP=`echo ${NEW_CHG_REQ_SYS_ID} |  tr -d "\""`
export TRIGGER_CHG_REQ_URL=${SN_CHANGE_REQUEST_URL}/${TEMP}

export TRIGGER_CHG_REQ_PAYLOAD="{
    \"state\": \"-4\",
    \"approval\": \"requested\"
}"

export TRIGGER_CHG_REQ_SYS_ID=$(curl -s -X PUT \
--variable %TRIGGER_CHG_REQ_URL \
--variable %CONTENT_TYPE \
--variable %AUTH_HEADER \
--variable %TRIGGER_CHG_REQ_PAYLOAD \
--expand-url {{TRIGGER_CHG_REQ_URL}} \
--expand-header {{CONTENT_TYPE}} \
--expand-header {{AUTH_HEADER}} \
--expand-data {{TRIGGER_CHG_REQ_PAYLOAD}} | jq '.result.sys_id')
echo "*** Triggered change request with Sys Id: ${TRIGGER_CHG_REQ_SYS_ID}"

#   OUTPUT DELETE DATA SCRIPT
export CLEAR_DATA=clear-data.sh
rm -f $CLEAR_DATA
echo "export SN_SERVER='${SN_SERVER}'" >> $CLEAR_DATA
echo "export AUTH_HEADER=\"${AUTH_HEADER}\"" >> $CLEAR_DATA
echo "export ACCEPT='Accept: application/json'" >> $CLEAR_DATA

export ACCEPT='Accept: application/json'

echo "# Delete Change Request" >> $CLEAR_DATA
export DELETE_SYS_ID=`echo ${NEW_CHG_REQ_SYS_ID} |  tr -d "\""`
echo "curl \"${SN_SERVER}/api/now/table/change_request/${DELETE_SYS_ID}\" \
--request DELETE \
--header '${ACCEPT}' \
--header '${AUTH_HEADER}' " >> $CLEAR_DATA

echo "# Delete approver_user role to approver group" >> $CLEAR_DATA
export DELETE_SYS_ID=`echo ${NEW_GRP_ROLE_ASSOC_SYS_ID} |  tr -d "\""`
echo "curl \"${SN_SERVER}/api/now/table/sys_group_has_role/${DELETE_SYS_ID}\" \
--request DELETE \
--header '${ACCEPT}' \
--header '${AUTH_HEADER}' " >> $CLEAR_DATA

echo "# Delete approver user association with approver group" >> $CLEAR_DATA
export DELETE_SYS_ID=`echo ${NEW_ASSIGN_GRP_TO_USR_SYS_ID} |  tr -d "\""`
echo "curl \"${SN_SERVER}/api/now/table/sys_user_grmember/${DELETE_SYS_ID}\" \
--request DELETE \
--header '${ACCEPT}' \
--header '${AUTH_HEADER}' " >> $CLEAR_DATA

echo "# Delete Approver Group" >> $CLEAR_DATA
export DELETE_SYS_ID=`echo ${NEW_APPRV_GRP_SYS_ID} |  tr -d "\""`
echo "curl \"${SN_SERVER}/api/now/table/sys_user_group/${DELETE_SYS_ID}\" \
--request DELETE \
--header '${ACCEPT}' \
--header '${AUTH_HEADER}' " >> $CLEAR_DATA

echo "# Delete Approver User" >> $CLEAR_DATA
export DELETE_SYS_ID=`echo ${NEW_APPRV_USER_SYS_ID} |  tr -d "\""`
echo "curl \"${SN_SERVER}/api/now/table/sys_user/${DELETE_SYS_ID}\" \
--request DELETE \
--header '${ACCEPT}' \
--header '${AUTH_HEADER}' " >> $CLEAR_DATA

echo "# Delete Requester User" >> $CLEAR_DATA
export DELETE_SYS_ID=`echo ${NEW_REQ_USER_SYS_ID} |  tr -d "\""`
echo "curl \"${SN_SERVER}/api/now/table/sys_user/${DELETE_SYS_ID}\" \
--request DELETE \
--header '${ACCEPT}' \
--header '${AUTH_HEADER}' " >> $CLEAR_DATA

