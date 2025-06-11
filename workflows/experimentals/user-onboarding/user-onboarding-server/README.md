# User Onboarding Server

This project implements a simple Go server that exposes a REST API for simulating the onboarding of new users. It includes functionalities like onboarding a user and checking their status via the `/onboard` endpoint.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Building the Project](#building-the-project)
- [Running the Project Locally](#running-the-project-locally)
- [Testing the Server](#testing-the-server)
- [Kubernetes Deployment](#kubernetes-deployment)

## Prerequisites

Before you begin, ensure you have the following installed:
- Podman/Docker
- Go (if you plan to build the project manually)
- Kubernetes/OCP (if you want to deploy to a cluster)

## Building the Project
To build the Go project and the image, replace organization based on your needs:

```bash
podman build -t quay.io/orchestrator/user-onboarding-server:v1 .
```

and push the image to your target registry:
```bash
podman push quay.io/orchestrator/user-onboarding-server:v1
```

## Running the Project Locally

### With Podman
```bash
podman run -it -p 8080:8080 quay.io/orchestrator/user-onboarding-server:v1
```

### With Go Server Directly
```bash
go mod tidy
go run server.go
```

## Testing the Server

```bash
curl -s -X POST http://localhost:8080/onboard -H "Content-Type: application/json" -d '{"user_id": "user:default/test", "name": "Jane Smith"}' | jq
```

The expected output should be:
```json
{
  "user_id": "user:default/test",
  "status": "In Progress"
}
```
The third exact call (with the same user ID) will change the status to `Ready`.
```json
{
  "user_id": "user:default/test",
  "status": "Ready"
}
```

# Kubernetes Deployment
The [manifests folder](../manifests/) contains the required resources for deploying the server on a K8s cluster.
Simply create the resources on a cluster:
```bash
kubectl apply -f ../manifests/00-deployment.yaml
kubectl apply -f ../manifests/00-service.yaml
```

Once the deployment is ready, expose the service:
```bash
kubectl port-forward svc/user-onboarding 8080:8080
```

and test with:
```bash
curl -s -X POST http://localhost:8080/onboard -H "Content-Type: application/json" -d '{"user_id": "user:default/test", "name": "Jane Smith"}' | jq
```
{
  "user_id": "user:default/test",
  "status": "Ready"
}
