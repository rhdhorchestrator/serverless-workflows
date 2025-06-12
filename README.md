## Orchestrator Workflows Helm Repository

This repository serves as a Helm chart repository for deploying serverless workflows with the Sonataflow Operator. It encompasses a collection of pre-defined workflows, each tailored to specific use cases. These workflows have undergone thorough testing and validation through Continuous Integration (CI) processes and are organized according to their chart versions.

The repository includes a variety of serverless workflows, such as:

* Greeting: A basic example workflow to demonstrate functionality.
* Migration Toolkit for Application Analysis (MTA): This workflow evaluates applications to determine potential risks and the associated costs of containerizing the applications.
* Move2Kube: Designed to facilitate the transition of an application to Kubernetes (K8s) environments.
* ...
## Usage

### Prerequisites
To utilize the workflows contained in this repository, the Orchestrator Deployment must be installed on your OpenShift Container Platform (OCP) cluster. For detailed instructions on installing the Orchestrator, please visit the [Orchestrator Helm Based Operator Repository](https://www.rhdhorchestrator.io/orchestrator-go-operator/)

## Installation
```bash
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows
```

View available workflows on the Helm repository:
```
helm search repo orchestrator-workflows
```

The expected result should look like (with different versions):
```
NAME                            	CHART VERSION	APP VERSION	DESCRIPTION                                      
orchestrator-workflows/greeting 	0.4.2        	1.16.0     	A Helm chart for the greeting serverless workflow
orchestrator-workflows/move2kube	0.2.16       	1.16.0     	A Helm chart to deploy the move2kube workflow.   
orchestrator-workflows/mta      	0.2.16       	1.16.0     	A Helm chart for MTA serverless workflow         
orchestrator-workflows/workflows	0.2.24       	1.16.0     	A Helm chart for serverless workflows
...
```

You can [install the workflows following their respective README](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/docs/main/)

## Installing workflows in additional namespaces
When deploying a workflow in a namespace different from where Sonataflow services are running (e.g. sonataflow-infra), there are essential steps to follow. For detailed instructions, see the [Additional Workflow Namespaces section](https://github.com/rhdhorchestrator/orchestrator-go-operator/tree/main/docs/release-1.5?tab=readme-ov-file#additional-workflow-namespaces).

## Version Compatibility
The workflows rely on components included in the [Orchestrator Operator](https://www.rhdhorchestrator.io/orchestrator-go-operator/). Therefore, it is crucial to match the workflow version with the corresponding Orchestrator version that supports it. 
The list below outlines the compatibility between the workflows and Orchestrator versions:
| Workflows          | Chart Version | Orchestrator Operator Version |
|--------------------|---------------|----------------------|
| move2kube          | 1.5.x         | 1.5.x                |
| create-ocp-project | 1.5.x         | 1.5.x                |
| request-vm-cnv     | 1.5.x         | 1.5.x                |
| modify-vm-resources| 1.5.x         | 1.5.x                |
| mta-v7             | 1.5.x         | 1.5.x                |
| mtv-migration      | 1.5.x         | 1.5.x                |
| mtv-plan           | 1.5.x         | 1.5.x                |


## Helm index
[https://www.rhdhorchestrator.io/serverless-workflows/index.yaml](https://www.rhdhorchestrator.io/serverless-workflows/index.yaml)
