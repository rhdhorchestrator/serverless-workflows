# Path K8S resource - workflow for the Optimizations plugin and Optimizer app
This workflow is a component in the solution provided by the Optimizations plugin and the Optimizer app. It is not meant to be consumed by humans only by apps. However, it can be executed via the Orchestrator plugin just as any other workflow. The workflow patches workload resources such as deployments and statefulsets. The input for the workflow is taken from Red Hat Insights's OpenShift Optimizations Recommendations. Each recommendation specifies a certain container to be patched.

## Prerequisite
* Credentials for accessing the OCP cluster.

## Workflow diagram
![Path K8S resource workflow diagram](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/patch-k8s-resource/patch-k8s-resource.svg?raw=true)

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `OCP_URL`  | The OpensShift API Server URL | ✅ | |
| `OCP_TOKEN`| The OpensShift API Server Token | ✅ | |
