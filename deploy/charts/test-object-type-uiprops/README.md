# Test Object Type Support in ui:props workflow

The test-object-type-uiprops workflow is used for **Backstage / RHDH** and orchestrator UI testing around **RHIDP-11054**: the input schema includes nested objects and fields that document **object-type (JsonValue) support** in `ui:props`—for example `fetch:response:*` values that are not plain strings. At runtime the workflow logs the full input, then completes with a structured result that surfaces **name** and **email** from `basicInfo` when present.

## Input

- **`basicInfo`** — Object group **Basic Information**.
  - **`name`** [required] — User name.
  - **`email`** [optional] — Email address (`format: email`).
- **`demonstrationFields`** [optional] — Object group **Object Type in ui:props Demonstration** (nested fields for UI behavior demos).
  - **`simpleText`** [optional] — Plain string field (classic `ui:props` usage).
  - **`objectExample`** [optional] — Field whose description/`ui:help` illustrates non-string JsonValue handling for `fetch:response:*` in `ui:props`.

## Workflow diagram

No SVG diagram is checked in for this workflow; the definition is an operation state (sysout plus result expression) in `workflows/test-object-type-uiprops/test-object-type-uiprops.sw.yaml`.

## Installation

See the [greeting installation guide](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/deploy/docs/main/greeting/README.md) for persistence prerequisites and cluster expectations. Use this chart name and SonataFlow resource name instead of `greeting`:

```console
TARGET_NS=sonataflow-infra
helm repo add orchestrator-workflows https://rhdhorchestrator.io/serverless-workflows
helm install test-object-type-uiprops orchestrator-workflows/test-object-type-uiprops -n ${TARGET_NS}
```

Verify the workflow is ready:

```console
oc wait sonataflow test-object-type-uiprops -n ${TARGET_NS} --for=condition=Running=True --timeout=5m
```

After the chart is published to the Helm repo, adjust the `helm install` line if your repository uses a different chart name or version (`--devel` for pre-releases).
