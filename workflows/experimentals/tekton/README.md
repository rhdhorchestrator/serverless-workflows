# Tekton workflow example
This workflow demonstrates creating Tekton resources in a Kubernetes cluster.

We create the following Kubernetes resources (in order as they appear):
 - a namespace called tekton-example
 - 2 Tasks, task-1 and task-2, that echo the message:

        Hi I am task #X

 - a Pipeline that executes the tasks one after the other
 - a PipelineRun for executing the Pipeline

## Workflow diagram
![Tekton workflow diagram](https://github.com/rhdhorchestrator/serverless-workflow-examples/blob/main/tekton/tekton.svg?raw=true)

## Prerequisite
* Access to an OCP cluster with Tekton operator (Openshift pipelines) installed. The cluster credentials must allow creating the resources listed above.
* The namespace "tekton-example" must not exist within the cluster before executing the workflow

## Application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `OCP_API_SERVER_URL`  | The OpensShift API Server URL | ✅ | |
| `OCP_API_SERVER_TOKEN`| The OpensShift API Server Token | ✅ | |

## How to run

```bash
mvn clean quarkus:dev
```

Example of POST to trigger the flow:
```bash
curl -X POST -H "Content-Type: application/json" http://localhost:8080/tekton
```

The response will include the created resources (IDs, statuses and such)
