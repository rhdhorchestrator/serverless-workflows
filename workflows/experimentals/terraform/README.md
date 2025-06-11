# terraform
This workflow takes terraform configurations and creates a run on Terraform Cloud / Terraform Enterprise on a designated Project and Workspace. After approval, the run is applied and the infrastructure is provisioned.   
Notifications are sent to notify for success or failure upon completion

The following inputs are required:
- for Terraform Cloud
    - Terraform Cloud URL
    - Terraform Access Token
- for Terraform Configurations:
    - A URL to a raw github file containing a tar of terraform configuration files (*.tf).
    - The raw github URL has to include the https://raw.githubusercontent.com domain,
     e.g the following format: https://raw.githubusercontent.com/ElaiShalevRH/TerraformDemo/refs/heads/main/content-1735483218.tar.gz

An example for such tar file can be seen [here.](https://github.com/ElaiShalevRH/TerraformDemo)

## Workflow diagram
![Terraform workflow diagram](https://github.com/rhdhorchestrator/serverless-workflow-examples/blob/main/terraform/src/main/resources/terraform.svg?raw=true)


## Prerequisites
* A running instance of Terraform Cloud / Enterprise, with a Project and a Workspace created. A Workspace ID is issued and will be used in the workflows input schema. 
* A running instance of Backstage with notification plugin configured.

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory |
|-----------------------|-------------|-----------|
| `TERRAFORM_URL`       | The Terraform Cloud instance URL | ✅ |
| `TERRAFORM_TOKEN`      | The Access Token for Terraform Cloud | ✅ |

Please note that TERRAFORM_TOKEN must be a [user API token](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/users#api-tokens), or a [team API token](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens#team-api-tokens). 

## Run instructions
1. Set up a Terraform Cloud instance with a [Project](https://developer.hashicorp.com/terraform/cloud-docs/projects), a [Workspace](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-workspace-create), and procure a WorkspaceID. 
2. Set up a publically accessible tar archive of your terraform configurations.
3. Make sure to configure any Terraform Providers Credentials on the Terraform instance (e.g AWS). 
4. Run the Workflow and enter the URL to the tar and the WorkspaceID as the input params.
5. Accept the Terraform Plan on the cloud instance, if not configured to be automatic. 
6. Recieve notification of success/failure.  


# Running in Quarkus

This project uses Quarkus, the Supersonic Subatomic Java Framework.

If you want to learn more about Quarkus, please visit its website: https://quarkus.io/ .

## Running the application in dev mode

You can run your application in dev mode that enables live coding using:
```shell script
./mvnw compile quarkus:dev
```

> **_NOTE:_**  Quarkus now ships with a Dev UI, which is available in dev mode only at http://localhost:8080/q/dev/.

## Packaging and running the application

The application can be packaged using:
```shell script
./mvnw package
```
It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it’s not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:
```shell script
./mvnw package -Dquarkus.package.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

## Creating a native executable

You can create a native executable using: 
```shell script
./mvnw package -Dnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using: 
```shell script
./mvnw package -Dnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/src-1.0.0-SNAPSHOT-runner`

If you want to learn more about building native executables, please consult https://quarkus.io/guides/maven-tooling.

## Related Guides

- Kubernetes ([guide](https://quarkus.io/guides/kubernetes)): Generate Kubernetes resources from annotations
- SmallRye Health ([guide](https://quarkus.io/guides/smallrye-health)): Monitor service health
