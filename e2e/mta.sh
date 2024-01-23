#!/bin/bash

set -e

# holds the pid of the port forward process for cleanups
export port_forward_pid=""

function cleanup() {
    echo "cleanup $?"
    kill "$port_forward_pid" || true
}

function workflowDone() {
    if [[ -n "${1}" ]]; then 
        id=$1
        curl -s -H "Content-Type: application/json" localhost:9080/api/orchestrator/instances/${id} | jq -e '.state == "COMPLETED"'
    fi
}

trap 'cleanup' EXIT SIGTERM

echo "Proxy Janus-idp port ⏳"
kubectl port-forward $(oc get svc -l app.kubernetes.io/component=backstage -o name) 9080:7007 &
port_forward_pid="$!"
sleep 3
echo "Proxy Janus-idp port ✅"

echo "End to end tests start ⏳"

out=$(curl -XPOST -H "Content-Type: application/json"  http://localhost:9080/api/orchestrator/workflows/MTAAnalysis/execute \ -d '{"repositoryURL": "https://github.com/spring-projects/spring-petclinic"}')
id=$(echo "$out" | jq -e .id)

if [ -z "$id" ] || [ "$id" == "null" ]; then
    echo "workflow instance id is null... exiting "
    exit 1
fi

retries=20
until eval "test ${retries} -eq 0 || workflowDone $id"; do
  echo "checking workflow ${id} completed successfully"
  sleep 5
  retries=$((retries-1))
done

echo "End to end tests passed ✅"
exit 0

