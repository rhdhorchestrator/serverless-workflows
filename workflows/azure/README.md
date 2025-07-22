# Azure list subscriptions workflow
The workflow logs in to Azure and lists the subscriptions. It uses token propagation. Therefore, it is meant to be used via RHDH UI and not via API.

## Prerequisite
* Access to Azure account via token and API.

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `AZURE_URL`      | The URL to the Azure API server. Usually https://management.azure.com | ✅ | |

## Workflow diagram
![Azure list subscriptions workflow diagram](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/azure/azure.svg?raw=true)

## Installation

See [official installation guide](https://github.com/rhdhorchestrator/serverless-workflows/blob/main/deploy/docs/main/azure)
