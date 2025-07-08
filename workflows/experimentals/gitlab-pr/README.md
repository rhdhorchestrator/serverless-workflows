# GitLab PR Workflow

This workflow automates the creation of merge requests in GitLab. It's based on the GitHub PR workflow but adapted for GitLab's API.

## Features

- Creates a new branch in a GitLab project
- Adds/updates files in the branch
- Creates a commit with the changes
- Opens a merge request from the new branch to the base branch

## Input Parameters

- `project_id`: The GitLab project ID
- `baseBranch`: The base branch for the merge request (e.g., "main")
- `targetBranch`: The target branch that will be created for the merge request

## Authentication

The workflow requires GitLab API authentication. Configure your GitLab token in the application properties or environment variables.

## Usage

1. Deploy the workflow to your Kogito/Quarkus environment
2. Configure the GitLab token authentication
3. Call the workflow with the required parameters

## Output

The workflow returns the URL of the created merge request for easy access. 