# Sample Retry Test workflow

The sample-retry-test workflow is a minimal Serverless Workflow used for local and UI testing. It injects a fixed message and completes immediately. The input schema drives a **Backstage / RHDH** form with **ActiveTextInput** fields whose `ui:props` exercise **fetch retry** behavior (max attempts, delay, backoff, and HTTP status codes). Your Backstage backend must expose the URLs referenced in the schema (for example `/api/retry-test/all-props`) so the form can load values.

## Input

- **`retryAllProps`** [optional] — ActiveTextInput with full retry settings (`fetch:retry:maxAttempts`, `delay`, `backoff`, `statusCodes` including 404).
- **`retryStatusCodesNoMatch`** [optional] — ActiveTextInput with retry props but a status-code list that omits 404 (used to validate retry behavior when the failing status is not listed).
- **`retryNoProps`** [optional] — ActiveTextInput with fetch URL and response mapping only (no explicit retry properties).

## Workflow diagram

No SVG diagram is checked in for this workflow; the definition is a single inject state in `workflows/sample-retry-test/sample-retry-test.sw.yaml`.

## Installation

See the [greeting installation guide](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/deploy/docs/main/greeting/README.md) for persistence prerequisites and cluster expectations. Use this chart name and SonataFlow resource name instead of `greeting`:

```console
TARGET_NS=sonataflow-infra
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows
helm install sample-retry-test orchestrator-workflows/sample-retry-test -n ${TARGET_NS}
```

Verify the workflow is ready:

```console
oc wait sonataflow sample-retry-test -n ${TARGET_NS} --for=condition=Running=True --timeout=5m
```

After the chart is published to the Helm repo, adjust the `helm install` line if your repository uses a different chart name or version (`--devel` for pre-releases).
