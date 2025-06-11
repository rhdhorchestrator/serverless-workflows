# User Onboarding workflow
The workflow is an example workflow for testing purposes, for testing access to external systems, loops and sleep.
The workflow registers a new user into a system, and after 3 checks it marks the user onboarding as completed.
The workflow sleeps for few seconds between cycles.

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `BACKSTAGE_NOTIFICATIONS_URL`      | The backstage server URL for notifications | ✅ | |
| `NOTIFICATIONS_BEARER_TOKEN`      | The authorization bearer token to use to send notifications | ✅ | |
| `ONBOARDING_SERVER_URL`      | The Onboarding server URL | ✅ | |

## Installation on OCP
For installing on OCP, there is a need to deploy all of the manifests from [manifests folder](./manifests/), but
prior to that, to set the values [in the secret file](./manifests/00-secret_user-onboarding.yaml) according to the installation of the user onboarding cluster and the target RHDH instance.