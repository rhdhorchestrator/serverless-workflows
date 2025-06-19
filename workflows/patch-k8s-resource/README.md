# Path K8S resource - workflow for the Optimizations plugin and Optimizer app
This workflow is a component in the solution provided by the Optimizations plugin and the Optimizer app. It is not meant to be consumed by humans only by apps. However, it can be executed via the Orchestrator plugin just as any other workflow. The workflow patches workload resources such as deployments and statefulsets. The input for the workflow is taken from Red Hat Insights's OpenShift Optimizations Recommendations. Each recommendation specifies a certain container to be patched.

## Prerequisite
* Credentials for accessing the OCP clusters. Each cluster has a URL and a token.

## Workflow diagram
![Path K8S resource workflow diagram](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/workflows/patch-k8s-resource/patch-k8s-resource.svg?raw=true)

## Workflow application configuration
The workflow needs the URL and token for accessing the cluster that is being optimized. The input variable `clusterName` determines the set of properties that the workflow will use. The file `application.properties` contains an example for a cluster called `mycluster`. This set of properties will be used when the input variable `clusterName` contains the value `mycluster`.

## Deploying in OCP with OSL
If you have OSL (OpenShift Serverless Logic, a.k.a SonataFlow) operator installed, you can use the [manifests](./manifests) folder for deploying the workflow. Create the resources in the OSL namespace (usually sonataflow-infra). The application configuration is in the first file.
