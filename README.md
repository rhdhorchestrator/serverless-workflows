# Serverless-Workflows

This repository contains multiple workflows. Each workflow is represented by a directory in the project. Below is a table listing all available workflows:

| Workflow Name                    | Description                                       |
|----------------------------------|---------------------------------------------------|
| `create-ocp-project`             | Sets up an OpenShift Container Platform (OCP) project. |
| `escalation`                     | Demos workflow ticket escalation.          |
| `greeting`                       | Sample greeting workflow.                         |
| `modify-vm-resources`            | Modifies resources allocated to virtual machines. |
| `move2kube`                      | Workflow for Move2Kube tasks and transformation.  |
| `mta-v7.x`                       | Migration toolkit for applications, version 7.x.  |
| `mtv-migration`                  | Migration tasks using Migration Toolkit for Virtualization (MTV). |
| `request-vm-cnv`                 | Requests and provisions VMs using Container Native Virtualization (CNV). |

Each workflow is organized in its own directory, containing the following components:
* `application.properties` — Contains configuration properties specific to the workflow application.
* `${workflow}.sw.yaml` — The [Serverless Workflow definition][1], authored according to recommended [best practices][4].
* `specs/ (optional)` — Directory for OpenAPI specifications used by the workflow, if applicable.
* `schemas/ (optional)` — Directory containing input and output data schemas relevant to the workflow execution.

Each workflow is built into a container image and published to `Quay.io` via GitHub Actions. The image naming convention follows:
```
quay.io/orchestrator/serverless-workflow-${workflow}
```

## Current image statuses:

- https://quay.io/repository/orchestrator/serverless-workflow-mta-v7.x
- https://quay.io/repository/orchestrator/serverless-workflow-m2k
- https://quay.io/repository/orchestrator/serverless-workflow-greeting
- https://quay.io/repository/orchestrator/serverless-workflow-escalation

After the container image is published, a GitHub Action automatically generates the corresponding Kubernetes manifests and submits a pull request to this repository.
The manifests are placed under the deploy/charts directory, in a subdirectory named after the workflow.
This Helm chart structure is intended for deploying the workflow to environments where the [SonataFlow Operator][2] is installed and running.
The resulting Helm charts are then published to the configured Helm repository for consumption at https://rhdhorchestrator.io/serverless-workflows

## How to introduce a new workflow

Follow these steps to successfully add a new workflow:

1. Create a folder under the root with the name of the workflow, e.x `/onboarding`
2. Copy `application.properties`, `onboarding.sw.yaml` into that folder
3. Create a GitHub workflow file `.github/workflows/${workflow}.yaml` that will call `main` workflow (e.g. `greeting.yaml`)
4. Create a pull request but don't merge yet.
5. Send a pull request to add a sub-chart under the path `deploy/charts/<WORKFLOW_ID>`, e.g. `deploy/charts/onboarding`.
6. Now the PR from 4 can be merged and an automatic PR will be created with the generated manifests. Review and merge.

See [Continuous Integration with make](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/make.md) for implementation details of the CI pipeline.

### Builder image
[workflow-builder-dev.Dockerfile](./pipeline/workflow-builder.Dockerfile) - references OpenShift Serverless Logic builder image from `registry.redhat.io` which requires authorization.
  - To use this Dockerfile locally, you must be logged to `registry.redhat.io`. To get access to that registry, follow:
    1. Get tokens [here](https://access.redhat.com/terms-based-registry/accounts). Once logged in to Podman, you should be able to pull the image.
    2. Verify pulling the image [here](https://catalog.redhat.com/software/containers/openshift-serverless-1-tech-preview/logic-swf-builder-rhel8/6483079349c48023fc262858?architecture=amd64&image=65e1a56104e00058ecdd52eb&container-tabs=gti)

Note on CI:
For every PR merged in the workflow directory, a GitHub Action runs an image build to generate manifests, and a new PR is automatically generated in this repository.
The credentials used by the build process are defined as organization level secret, and the content is from a token on the helm repo with an expiry period of 60 days.

[1]: https://github.com/serverlessworkflow/specification/tree/main?tab=readme-ov-file#documentation
[2]: https://github.com/apache/incubator-kie-tools/tree/main/packages/sonataflow-operator
[4]: https://github.com/rhdhorchestrator/serverless-workflows/blob/main/best-practices.md

## Using Helm Charts
Some of the workflows in this repository are released as Helm charts.
To view available workflows in dev mode or prod mode use:
```bash
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows
helm search repo orchestrator-workflows --devel
```

The instructions for installing each workflows can be found in the [docs](./deploy/docs/main/)