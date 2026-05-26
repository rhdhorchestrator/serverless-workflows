# Bulk Import Git Repos Workflow

This workflow creates pull requests (GitHub) or merge requests (GitLab) based on the `approvalTool` parameter.

Workflow id: **`universal-pr`** (do not rename without bulk-import plugin changes).

## Overview

The workflow supports both GitHub and GitLab repositories and can create PRs/MRs with multiple files.

GitHub authentication uses **token propagation** (`X-Authorization-Github`) from Red Hat Developer Hub — no `GHTOKEN` secret in manifests.

## Input Schema

The workflow expects the following input parameters:

- `approvalTool`: Either "GIT" for GitHub or "GITLAB" for GitLab
- `owner`: The owner/namespace of the repository
- `repo`: The repository name
- `baseBranch`: The base branch to create the PR/MR from
- `targetBranch`: The target branch name for the PR/MR

## Workflow Steps

1. **GetScafolderData**: Retrieves mock data with files to be added
2. **RouteToProvider**: Routes to either GitHub or GitLab workflow based on `approvalTool`
3. **GitHub Flow**: Creates branch, commits files, and creates a pull request
4. **GitLab Flow**: Searches for project, creates branch, commits files, and creates a merge request

## Output

- For GitHub: Returns PR URL in **`PR_URL`** output (link format)
- For GitLab: Returns MR URL in `MR_URL` output

## Deploy on Red Hat Developer Hub (RHDH)

After [e2e-test-utils `installOrchestrator`](https://github.com/redhat-developer/rhdh-plugin-export-overlays) in namespace **`orchestrator`**:

```bash
oc apply -n orchestrator -f workflows/bulk-import-git-repos/manifests/
oc rollout status deployment/universal-pr -n orchestrator --timeout=600s
```

Manifests use **backstage Postgres** (`backstage-psql-secret`, `backstage-psql`, database `backstage_plugin_orchestrator`) created by `installOrchestrator`. Workflow image: `quay.io/orchestrator/serverless-workflow-bulk-import-git-repos`.

Verify data-index lists the workflow:

```bash
oc exec -n orchestrator deploy/sonataflow-platform-data-index-service -- \
  curl -sf -X POST -H 'Content-Type: application/json' \
  -d '{"query":"{ ProcessDefinitions { id } }"}' \
  http://localhost:8080/graphql | grep universal-pr
```

**Context:** [RHIDP-9350](https://issues.redhat.com/browse/RHIDP-9350), [serverless-workflows PR #774](https://github.com/rhdhorchestrator/serverless-workflows/pull/774).

## Development

Java artifacts build (prerequisites: pre-installed java and maven):

```bash
mvn clean install
```

Generate manifests (RHDH persistence profile is enabled automatically for this workflow):

```bash
make WORKFLOW_ID=bulk-import-git-repos gen-manifests
cp -rf /tmp/serverless-workflows/workflows/bulk-import-git-repos/src/main/resources/manifests/* \
  ./workflows/bulk-import-git-repos/manifests/
```

Build and push image:

```bash
make WORKFLOW_ID=bulk-import-git-repos build-image push-image
```

For non-RHDH clusters, use `RHDH_PERSISTENCE=false` and the default `sonataflow-psql-*` persistence from `ENABLE_PERSISTENCE=true`.
