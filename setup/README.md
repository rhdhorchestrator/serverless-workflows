# Requirements
This container images extends a basic UBI 9 image with the required tools:
* `git`
* `tar`
* `kustomize`
* `jq`
* `yq`
* `kn`
* `kubectl`

# Build and publish the image
Customize the `push` command to publish in your own repository:
```bash
 podman build --platform='linux/amd64' -t quay.io/$USER/ubi9-pipeline:latest .
 podman push quay.io/$USER/ubi9-pipeline:latest
```
# A workflow for building the image
When the Dockerfile is changed and merged, a [workflow](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/.github/workflows/builder-utility.yaml) is triggered to build and publish the image.
