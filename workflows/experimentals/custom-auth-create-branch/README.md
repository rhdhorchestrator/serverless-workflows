# Custom Auth Create Branch Workflow

This workflow demonstrates creating a GitHub branch using a custom authentication provider. It's designed to test the custom authentication provider functionality in Red Hat Developer Hub (RHDH). The custom auth provider provides the same functionality as the built in github auth provider, but has a different id and is deployed as a dynamic plugin.


## Overview

The workflow performs the following operations:
1. Gets the SHA of a specified branch
2. Creates a new branch from that SHA
3. Retrieves commit details
4. Outputs the link to the branch

## Required Configurations

### 1. Add Custom Authentication Plugins

Add the custom authentication plugins to the `dynamic-plugins-rhdh` configmap in the `rhdh` namespace:


```yaml
# Custom authentication provider module (frontend)  
- package: oci://quay.io/brotman/multiple-authentication-module:latest!custom-authentication-provider-module
  disabled: false
  pluginConfig:
    dynamicPlugins:
      frontend:
        custom-authentication-provider-module:
          signInPage:
            importName: CustomSignInPage
          providerSettings:
            - title: Github Two
              description: Sign in with GitHub Org Two
              provider: core.auth.github-two

# Backend authentication provider module  
- package: oci://quay.io/brotman/multiple-authentication-module:latest!custom-authentication-provider-module-backend-dynamic
  disabled: false
```

### 2. Enable Auth Provider Module Override

Add the environment variable to enable custom authentication provider modules in the Backstage instance:

```bash
kubectl patch backstage my-rhdh -n rhdh --type='merge' -p='{
  "spec": {
    "application": {
      "extraEnvs": {
        "envs": [
          {
            "name": "ENABLE_AUTH_PROVIDER_MODULE_OVERRIDE",
            "value": "true"
          }
        ]
      }
    }
  }
}'
```


> **⚠️ Important**: This setting breaks the built in auth providers, but is necessary to enable any custom provider.

### 3. GitHub OAuth Application Setup

Create a GitHub OAuth application with the following configuration:

1. **Go to GitHub** → Settings → Developer settings → OAuth Apps
2. **Create a new OAuth App** (or edit existing one)
3. **Set the following values:**
   - **Application name**: `RHDH GitHub Two Auth` (or any descriptive name)
   - **Homepage URL**: console URL
   - **Authorization callback URL**: `<console URL>/api/auth/github-two/handler/frame`

### 4. Update Authentication Secret

Update the backstage auth secret. First, ensure you have the environment variables set:

```bash
# Set your GitHub OAuth app credentials
export GITHUB_TWO_CLIENT_ID="your_github_oauth_client_id"
export GITHUB_TWO_CLIENT_SECRET="your_github_oauth_client_secret"
```

Then update the secret:

```bash
kubectl patch secret my-rhdh-secret -n rhdh --type='merge' -p='{
  "data": {
    "GITHUB_TWO_CLIENT_ID": "'$(echo -n "$GITHUB_TWO_CLIENT_ID" | base64 -w 0)'",
    "GITHUB_TWO_CLIENT_SECRET": "'$(echo -n "$GITHUB_TWO_CLIENT_SECRET" | base64 -w 0)'"
  }
}'
```

Add the GitHub Two provider configuration to the auth section:

```yaml
auth:
  environment: development
  providers:
    github-two:
      development:
        clientId: ${GITHUB_TWO_CLIENT_ID}
        clientSecret: ${GITHUB_TWO_CLIENT_SECRET}
```

