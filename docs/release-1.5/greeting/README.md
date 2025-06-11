
Greeting
===========

A Helm chart for the greeting serverless workflow

The greeting workflow is a basic workflow without any external dependencies.
Its purpose is to demonstrate functionality of the workflows system.

# Helm Configuration

The following table lists the configurable parameters of the Greeting chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
|                          |                         |                |


# Installation
## Persistence pre-requisites
If persistence is enabled, you must have a PostgreSQL instance running in the cluster, in the same `namespace` as the workflows.

A `secret` containing the instance credentials must exists as well. 

See https://www.rhdhorchestrator.io/orchestrator-helm-operator/postgresql on how to install a PostgreSQL instance. Please follow the section detailing how to install using helm. In this document, a `secret` holding the credentials is created.

## Prerequisites 
Set `TARGET_NS` to the target namespace:
```console
TARGET_NS=sonataflow-infra
```
## Installing helm chart 

```console
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows-config
helm install greeting orchestrator-workflows/greeting -n ${TARGET_NS}
```

Verify the greeting workflow is ready:
```console
oc wait sonataflow greeting -n -n ${TARGET_NS} --for=condition=Running=True --timeout=5m
sonataflow.sonataflow.org/greeting condition met
```
