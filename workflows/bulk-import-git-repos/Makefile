# Makefile for bulk-import-git-repos workflow
# Generates Kubernetes manifests locally

WORKFLOW_ID := bulk-import-git-repos
WORKFLOW_IMAGE_REGISTRY ?= quay.io
WORKFLOW_IMAGE_NAMESPACE ?= orchestrator
WORKFLOW_IMAGE_REPO ?= serverless-workflow-$(WORKFLOW_ID)
WORKFLOW_IMAGE_TAG ?= latest
CONTAINER_ENGINE ?= $(shell which podman >/dev/null 2>&1 && echo podman || echo docker)
LINUX_IMAGE ?= quay.io/orchestrator/ubi9-pipeline:latest

.PHONY: gen-manifests clean help

help:
	@echo "Available targets:"
	@echo "  gen-manifests - Generate Kubernetes manifests"
	@echo "  clean         - Remove generated manifests"
	@echo ""
	@echo "Variables:"
	@echo "  WORKFLOW_IMAGE_TAG - Image tag (default: latest)"
	@echo "  CONTAINER_ENGINE   - docker or podman (default: auto-detect)"

gen-manifests:
	@echo "🛠️  Generating manifests for $(WORKFLOW_ID)..."
	@$(CONTAINER_ENGINE) run --rm \
		-v $(PWD):/workdir:Z \
		-w /workdir \
		$(LINUX_IMAGE) \
		/bin/bash -c "echo -e '\nkie.flyway.enabled=false' >> application.properties && kn-workflow gen-manifest --profile=gitops --namespace='' --image=$(WORKFLOW_IMAGE_REGISTRY)/$(WORKFLOW_IMAGE_NAMESPACE)/$(WORKFLOW_IMAGE_REPO):$(WORKFLOW_IMAGE_TAG)"
	@echo "✅ Manifests generated in ./manifests/"

clean:
	@echo "🧹 Cleaning generated manifests..."
	@rm -rf manifests/
	@echo "✅ Cleaned"
