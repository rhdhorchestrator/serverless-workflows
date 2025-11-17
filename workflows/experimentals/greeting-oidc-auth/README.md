# Greeting OIDC Auth workflow
The workflow is an example workflow demonstrating OIDC (OpenID Connect) authentication with JWT token propagation to external APIs. It authenticates users via Keycloak/RHSSO from Backstage UI, captures JWT tokens, and propagates them to external API calls to demonstrate token flow through the workflow execution.

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `KEYCLOAK_AUTH_SERVER_URL`      | The Keycloak/RHSSO authentication server URL (e.g., https://keycloak-rhsso-operator.apps.cluster.com/auth/realms/basic) | ✅ | |
| `KEYCLOAK_CLIENT_ID`      | The OIDC client ID configured in Keycloak | ✅ | |
| `KEYCLOAK_CLIENT_SECRET`      | The OIDC client secret from Keycloak | ✅ | |
| `POSTGRES_USER`      | PostgreSQL database username | ✅ | |
| `POSTGRES_PASSWORD`      | PostgreSQL database password | ✅ | |
| `K_SINK`      | Data Index Service URL for workflow events | ❌ | `http://sonataflow-platform-data-index-service.rhdh-operator.svc.cluster.local` |

## Building the container image

Before deploying the workflow, the container image needs to be built:

1. **Build the application with Maven:**
   ```bash
   cd workflows/experimentals/greeting-oidc-auth
   mvn clean package -DskipTests
   ```

2. **Build the container image:**
   ```bash
   podman build -t quay.io/YOUR_ORG/serverless-workflow-greeting-auth:TAG .
   ```
   Or using Docker:
   ```bash
   docker build -t quay.io/YOUR_ORG/serverless-workflow-greeting-auth:TAG .
   ```

3. **Push to container registry (optional):**
   ```bash
   podman push quay.io/YOUR_ORG/serverless-workflow-greeting-auth:TAG
   ```

Update the image reference in `manifests/03-sonataflow_greeting-auth.yaml` with your built image before deploying.

## Installation on OCP
For installing on OCP, there is a need to deploy all of the manifests from [manifests folder](./manifests/), but prior to that, to set the values [in the secret file](./manifests/00-secret_greeting-auth.yaml) according to the installation of the Keycloak/RHSSO instance and the target RHDH instance.

The HTTPBin deployment and service manifests (`00-httpbin-deployment.yaml` and `00-httpbin-service.yaml`) should be deployed first as they provide the test endpoint used by the workflow to verify token propagation.

## HTTPBin functionality for testing
HTTPBin is a simple HTTP request & response service deployed as part of the workflow manifests. It is used to verify that JWT tokens are correctly propagated from the workflow to external API calls.

The workflow calls HTTPBin's `/headers` endpoint, which echoes back all request headers including the `Authorization` header containing the Bearer token. This allows the workflow to:

- Verify that JWT tokens are correctly forwarded from Backstage through the workflow to external APIs
- Display the decoded JWT token payload in workflow results
- Confirm that token propagation is working as expected

HTTPBin is deployed as a separate service (`httpbin`) in the same namespace and is accessed via the Kubernetes service DNS name `http://httpbin.rhdh-operator.svc.cluster.local`.
