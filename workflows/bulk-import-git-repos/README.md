# Bulk Import Git Repos Workflow

This workflow creates pull requests (GitHub) or merge requests (GitLab) based on the `approvalTool` parameter.

## Overview

The workflow supports both GitHub and GitLab repositories and can create PRs/MRs with multiple files.

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

- For GitHub: Returns PR URL in `PR_URL` output
- For GitLab: Returns MR URL in `MR_URL` output

# Development

Java artifacts build(prerequisites: pre-installed java and maven): 

```
mvn clean install
```

Generate manifests, from the root of the repository:

```
make WORKFLOW_ID=bulk-import-git-repos WORKFLOW_SUBDIR=bulk-import-git-repos/src/main/resources gen-manifests
cp -rf /tmp/serverless-workflows/workflows/bulk-import-git-repos/src/main/resources/manifests ./workflows/bulk-import-git-repos 
```

Build image: 

```
make WORKFLOW_ID=bulk-import-git-repos build-image
```
