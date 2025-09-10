# Reproducer Workflow - Subflow error not getting propagated to parent workflow

This Reproducer workflow will demonstrate a parent workflow getting stuck on "Running", and not failing / erroring, even after a Subflow of it's has completed with error. 

to run this workflow, apply the manifests on the cluster configured with Sonataflow and Orchestrator.

You can use the [RHDH chart](https://github.com/redhat-developer/rhdh-chart) to install Orchestrator with all necessary pre-requisites easily.

The manifests and workflow image were build with the [build.sh script](https://github.com/elai-shalev/orchestrator-demo/blob/main/scripts/build.sh) in the Orchestrator Demo repository.