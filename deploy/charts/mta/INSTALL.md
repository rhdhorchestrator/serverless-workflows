MTA
===========

# Installation
## Persistence pre-requisites
The MTA workflow has persistence enabled, you must have a PostgreSQL instance running in the cluster, in the same `namespace` as the workflows.
A `secret` containing the instance credentials must exist as well. 

See [this](https://www.rhdhorchestrator.io/orchestrator-helm-operator/postgresql) on how to install a PostgreSQL instance. Please follow the section detailing how to install using Helm. In this document, a `secret` holding the credentials is created.

## Installing helm chart 
From `charts` folder run 
```console
helm install mta workflows/mta -n sonataflow-infra
```

The rest of the installation steps can be found [here](https://github.com/rhdhorchestrator/serverless-workflows-config/blob/gh-pages/docs/mta/README.md#configuration)

### Persistence configuration
For a different persistence configuration, edit the `sonataflow` resource to set the correct value for the `persistence` `spec`.
The defaults are:
```
persistence:
  postgresql:
    secretRef:
      name: sonataflow-psql-postgresql
      userKey: postgres-username
      passwordKey: postgres-password
    serviceRef:
      name: sonataflow-psql-postgresql
      port: 5432
      databaseName: sonataflow
      databaseSchema: mtaanalysis
```

Make sure the above values match what is deployed on your namespace.

You can patch the resource by running (update it if needed with your values):
```bash
  oc patch sonataflow/mtaanalysis -n sonataflow-infra \
    --type merge \
    -p '
    {
      "spec": {
        "persistence": {
          "postgresql": {
            "secretRef": {
              "name": "sonataflow-psql-postgresql",
              "userKey": "postgres-username",
              "passwordKey": "postgres-password"
            },
            "serviceRef": {
              "name": "sonataflow-psql-postgresql",
              "port": 5432,
              "databaseName": "sonataflow",
              "databaseSchema": "mtaanalysis"
            }
          }
        }
      }
    }'
```

